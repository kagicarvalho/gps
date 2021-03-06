------------------------------------------------------------------------------
--                               GNAT Studio                                --
--                                                                          --
--                        Copyright (C) 2020, AdaCore                       --
--                                                                          --
-- This is free software;  you can redistribute it  and/or modify it  under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  This software is distributed in the hope  that it will be useful, --
-- but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN- --
-- TABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public --
-- License for  more details.  You should have  received  a copy of the GNU --
-- General  Public  License  distributed  with  this  software;   see  file --
-- COPYING3.  If not, go to http://www.gnu.org/licenses for a complete copy --
-- of the license.                                                          --
------------------------------------------------------------------------------

with GNATCOLL.Traces;                     use GNATCOLL.Traces;
with GNATCOLL.VFS;                        use GNATCOLL.VFS;

with Basic_Types;                         use Basic_Types;
with Language;
with Src_Editor_Buffer;                   use Src_Editor_Buffer;
with Src_Editor_Buffer.Blocks;            use Src_Editor_Buffer.Blocks;

with GPS.Editors;                         use GPS.Editors;
with GPS.LSP_Clients;
with GPS.LSP_Module;

with GPS.LSP_Client.Requests.Folding_Range;

package body GPS.LSP_Client.Editors.Folding is

   Me : constant Trace_Handle := Create ("GPS.EDITORS.LSP_FOLDING");

   -- Folding_Request --

   type Folding_Request is
     new GPS.LSP_Client.Requests.Folding_Range.
       Abstract_Folding_Range_Request with
      record
         Kernel : Kernel_Handle;
      end record;
   type Folding_Request_Access is access all Folding_Request;
   --  Used for communicate with LSP

   overriding procedure On_Result_Message
     (Self   : in out Folding_Request;
      Result : LSP.Messages.FoldingRange_Vector);

   -- LSP_Editor_Folding_Provider --

   type LSP_Editor_Folding_Provider is
     new GPS.Editors.Editor_Folding_Provider with record
      Kernel : Kernel_Handle;
   end record;

   overriding function Compute_Blocks
     (Self : in out LSP_Editor_Folding_Provider;
      File : GNATCOLL.VFS.Virtual_File) return Boolean;

   Provider : aliased LSP_Editor_Folding_Provider;

   -----------------------
   -- On_Result_Message --
   -----------------------

   overriding procedure On_Result_Message
     (Self   : in out Folding_Request;
      Result : LSP.Messages.FoldingRange_Vector)
   is
      Buffer : Source_Buffer;
      Data   : Blocks_Vector.Vector;
   begin
      declare
         Bufs : constant Source_Buffer_Array := Buffer_List (Self.Kernel);
      begin
         for Idx in Bufs'Range loop
            if Bufs (Idx).Get_Filename = Self.Text_Document then
               Buffer := Bufs (Idx);
               exit;
            end if;
         end loop;
      end;

      if Buffer = null then
         --  Buffer can be closed
         return;
      end if;

      for FoldingRange of Result loop
         Data.Append
           ((Editable_Line_Type (FoldingRange.startLine) + 1,
            Editable_Line_Type (FoldingRange.endLine) + 1));
      end loop;

      Set_Blocks (Buffer, Data);

   exception
      when E : others =>
         Trace (Me, E);
   end On_Result_Message;

   --------------------
   -- Compute_Blocks --
   --------------------

   overriding function Compute_Blocks
     (Self : in out LSP_Editor_Folding_Provider;
      File : GNATCOLL.VFS.Virtual_File) return Boolean
   is
      use type Language.Language_Access;

      Request : Folding_Request_Access;
      Lang    : constant Language.Language_Access :=
        Self.Kernel.Get_Language_Handler.Get_Language_From_File (File);
      Client  : GPS.LSP_Clients.LSP_Client_Access;
      Option  : LSP.Messages.Optional_Provider_Options;
   begin
      if Lang = null
        or else not GPS.LSP_Module.LSP_Is_Enabled (Lang)
      then
         return False;
      end if;

      Client := GPS.LSP_Module.Get_Language_Server (Lang).Get_Client;
      if not Client.Is_Ready then
         return True;
      end if;

      Option := Client.Capabilities.foldingRangeProvider;
      if not Option.Is_Set
        or else (Option.Value.Is_Boolean
                 and then not Option.Value.Bool)
      then
         return False;
      end if;

      Request := new Folding_Request;
      Request.Kernel := Self.Kernel;
      Request.Text_Document := File;

      GPS.LSP_Client.Requests.Execute
        (Lang, GPS.LSP_Client.Requests.Request_Access (Request));

      return True;

   exception
      when E : others =>
         Trace (Me, E);
         return False;
   end Compute_Blocks;

   ---------------------
   -- Register_Module --
   ---------------------

   procedure Register_Module (Kernel : Kernel_Handle) is
   begin
      Provider.Kernel := Kernel;
      Src_Editor_Buffer.Set_Folding_Provider (Provider'Access);
   end Register_Module;

end GPS.LSP_Client.Editors.Folding;
