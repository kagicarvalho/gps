-----------------------------------------------------------------------
--                               G P S                               --
--                                                                   --
--                        Copyright (C) 2006                         --
--                              AdaCore                              --
--                                                                   --
-- GPS is free  software;  you can redistribute it and/or modify  it --
-- under the terms of the GNU General Public License as published by --
-- the Free Software Foundation; either version 2 of the License, or --
-- (at your option) any later version.                               --
--                                                                   --
-- This program is  distributed in the hope that it will be  useful, --
-- but  WITHOUT ANY WARRANTY;  without even the  implied warranty of --
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU --
-- General Public License for more details. You should have received --
-- a copy of the GNU General Public License along with this program; --
-- if not,  write to the  Free Software Foundation, Inc.,  59 Temple --
-- Place - Suite 330, Boston, MA 02111-1307, USA.                    --
-----------------------------------------------------------------------

with GNAT.OS_Lib; use GNAT.OS_Lib;
with GNAT.Regpat; use GNAT.Regpat;
pragma Warnings (Off);
with GNAT.Expect.TTY.Remote; use GNAT.Expect.TTY.Remote;
pragma Warnings (On);

with Filesystem;         use Filesystem;
with GPS.Kernel.Console; use GPS.Kernel.Console;
with GPS.Kernel.Hooks;   use GPS.Kernel.Hooks;
with GPS.Kernel.Remote;  use GPS.Kernel.Remote;
with GPS.Kernel.Timeout; use GPS.Kernel.Timeout;
with Commands;           use Commands;
with Traces;             use Traces;

package body Remote_Sync_Module is

   Me : constant Debug_Handle := Create ("remote_sync_module");

   function On_Rsync_Hook
     (Kernel : access Kernel_Handle_Record'Class;
      Data   : access Hooks_Data'Class) return Boolean;
   --  run RSync hook

   procedure Parse_Rsync_Output
     (Data : Process_Data; Output : String);
   --  Called whenever new output from rsync is available

   ---------------------
   -- Register_Module --
   ---------------------

   procedure Register_Module (Kernel : Kernel_Handle) is
   begin
      Add_Hook (Kernel, Rsync_Action_Hook,
                Wrapper (On_Rsync_Hook'Access),
                "remote_sync_module.rsync");
   end Register_Module;

   -------------------
   -- On_Rsync_Hook --
   -------------------

   function On_Rsync_Hook
     (Kernel : access Kernel_Handle_Record'Class;
      Data   : access Hooks_Data'Class) return Boolean
   is
      Rsync_Data    : Rsync_Hooks_Args renames Rsync_Hooks_Args (Data.all);
      Src_Path      : String_Access;
      Dest_Path     : String_Access;
      Src_FS        : Filesystem_Access;
      Dest_FS       : Filesystem_Access;
      Machine       : Machine_Descriptor;
      Success       : Boolean;
      Rsync_Args    : constant String_List :=
        (new String'("-az"),
         new String'("--progress"),
         new String'("--delete"),
         new String'("--exclude"),
         new String'("'*.o'"));
      Transport_Arg : String_Access;

      function  Build_Arg return String_List;
      --  Build rsync arguments

      ---------------
      -- Build_Arg --
      ---------------

      function Build_Arg return String_List is
      begin
         if Transport_Arg /= null then
            return Rsync_Args & Transport_Arg & Src_Path & Dest_Path;
         else
            return Rsync_Args & Src_Path & Dest_Path;
         end if;
      end Build_Arg;
   begin

      if Rsync_Data.Src_Name = "" then
         --  Local src machine, remote dest machine
         Machine := Get_Machine_Descriptor (Rsync_Data.Dest_Name);
         Src_FS    := new Filesystem_Record'Class'(Get_Local_Filesystem);
         Src_Path  := new String'
           (To_Unix (Src_FS.all, Rsync_Data.Src_Path, True));
         Dest_FS   := new Filesystem_Record'Class'
           (Get_Filesystem (Rsync_Data.Dest_Name));
         Dest_Path := new String'
           (Machine.Network_Name.all & ":" &
            To_Unix (Dest_FS.all, Rsync_Data.Dest_Path, True));
      else
         --  Remote src machine, local dest machine
         Machine := Get_Machine_Descriptor (Rsync_Data.Src_Name);
         Src_FS    := new Filesystem_Record'Class'
           (Get_Filesystem (Rsync_Data.Src_Name));
         Src_Path  := new String'
           (Machine.Network_Name.all & ":" &
            To_Unix (Src_FS.all, Rsync_Data.Src_Path, True));
         Dest_FS   := new Filesystem_Record'Class'(Get_Local_Filesystem);
         Dest_Path := new String'
           (To_Unix (Dest_FS.all, Rsync_Data.Dest_Path, True));
      end if;

      if Machine = null then
         return False;
      end if;

      if Machine.Access_Name.all = "ssh" then
         Transport_Arg := new String'("--rsh=ssh");
      end if;

      Launch_Process
        (Kernel_Handle (Kernel),
         Command              => "rsync",
         Arguments            => Build_Arg,
         Console              => Get_Console (Kernel),
         Show_Command         => True,
         Show_Output          => True,
         Success              => Success,
         Line_By_Line         => True,
         Callback             => Parse_Rsync_Output'Access,
         Queue_Id             => Rsync_Data.Queue_Id,
         Synchronous          => False);
      Free (Src_Path);
      Free (Dest_Path);
      Free (Transport_Arg);
      return Success;
   end On_Rsync_Hook;

   ------------------------
   -- Parse_Rsync_Output --
   ------------------------

   procedure Parse_Rsync_Output
     (Data : Process_Data; Output : String)
   is
      Progress_Regexp : constant Pattern_Matcher := Compile
        ("^.*\(([0-9]*), [0-9.%]* of ([0-9]*)", Multiple_Lines);
      Matched     : Match_Array (0 .. 2);
      File_Nb     : Natural;
      Total_Files : Natural;
   begin
      Trace (Me, "Parse_Rsync_Output: '" & Output & "'");
      if not Data.Process_Died then
         Match (Progress_Regexp,
                Output,
                Matched);
         if Matched (0) /= No_Match then
            File_Nb := Natural'Value
              (Output (Matched (1).First .. Matched (1).Last));
            Total_Files := Natural'Value
              (Output (Matched (2).First .. Matched (2).Last));
            Set_Progress (Data.Command,
              Progress => (Activity => Running,
                           Current  => File_Nb,
                           Total    => Total_Files));
         end if;
      end if;
   end Parse_Rsync_Output;

end Remote_Sync_Module;
