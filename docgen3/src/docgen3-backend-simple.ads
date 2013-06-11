------------------------------------------------------------------------------
--                                  G P S                                   --
--                                                                          --
--                     Copyright (C) 2007-2013, AdaCore                     --
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

--  This package implements a simple reStructured text backend of Docgen.
--  For details on the reStructured Text Markup language read:
--    http://docutils.sourceforge.net/docs/user/rst/quickref.html
--    http://docutils.sourceforge.net/docs/ref/rst/restructuredtext.html
--  For details on sphynx read:
--    http://sphinx-doc.org

with GNATCOLL.VFS;      use GNATCOLL.VFS;
with Docgen3.Atree;     use Docgen3.Atree;
with Docgen3.Files;     use Docgen3.Files;
with Docgen3.Frontend;  use Docgen3.Frontend;

private package Docgen3.Backend.Simple is

   type Simple_Backend is new Docgen3.Backend.Docgen3_Backend with private;

   overriding procedure Initialize
     (Backend : in out Simple_Backend;
      Context : Docgen_Context);
   --  Initialize the backend and create the destination directory with support
   --  files. Returns the backend structure used to collect information of all
   --  the processed files (used to generate the global indexes).

   overriding procedure Process_File
     (Backend : in out Simple_Backend;
      Tree    : access Tree_Type);
   --  Generate the documentation of a single file

   overriding procedure Finalize
     (Backend : in out Simple_Backend;
      Update_Global_Index : Boolean);
   --  If Update_Global_Index is true then update the global indexes.

private
   type Collected_Entities is record
      Pkgs             : EInfo_List.Vector;
      Variables        : EInfo_List.Vector;
      Access_Types     : EInfo_List.Vector;
      Simple_Types     : EInfo_List.Vector;
      Record_Types     : EInfo_List.Vector;
      Tagged_Types     : EInfo_List.Vector;
      Interface_Types  : EInfo_List.Vector;
      Subprgs          : EInfo_List.Vector;
      Methods          : EInfo_List.Vector;
      CPP_Classes      : EInfo_List.Vector;
      CPP_Constructors : EInfo_List.Vector;
   end record;

   type Simple_Backend is new Docgen3.Backend.Docgen3_Backend with record
      Context   : aliased Docgen_Context;
      Src_Files : Files_List.Vector;
      Entities  : Collected_Entities;
   end record;

end Docgen3.Backend.Simple;
