-----------------------------------------------------------------------
--                               G P S                               --
--                                                                   --
--                 Copyright (C) 2001-2009, AdaCore                  --
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
-- a copy of the GNU General Public License along with this library; --
-- if not,  write to the  Free Software Foundation, Inc.,  59 Temple --
-- Place - Suite 330, Boston, MA 02111-1307, USA.                    --
-----------------------------------------------------------------------

with Ada.Characters.Handling;   use Ada.Characters.Handling;
with Ada.Directories;           use Ada.Directories;
with Interfaces.C;              use Interfaces.C;
with Interfaces.C.Strings;      use Interfaces.C.Strings;

with GNAT.Case_Util;            use GNAT.Case_Util;
with GNAT.Directory_Operations; use GNAT, GNAT.Directory_Operations;

with GNATCOLL.VFS;              use GNATCOLL.VFS;
with GNATCOLL.VFS_Utils;        use GNATCOLL.VFS_Utils;

with Config;

package body OS_Utils is

   OpenVMS_Host : Boolean := False;

   ---------------------
   -- Create_Tmp_File --
   ---------------------

   function Create_Tmp_File return GNATCOLL.VFS.Virtual_File is
      Current_Dir : constant Virtual_File := Get_Current_Dir;
      Temp_Dir    : constant Virtual_File := Get_Tmp_Directory;
      Fd          : File_Descriptor;
      Base        : String_Access;

   begin
      Change_Dir (Temp_Dir);
      Create_Temp_File (Fd, Base);
      Close (Fd);

      declare
         Result : constant Filesystem_String := +Base.all;
      begin
         Free (Base);
         Change_Dir (Current_Dir);

         return Create_From_Dir (Temp_Dir, Result);
      end;
   end Create_Tmp_File;

   -------------------------
   -- Executable_Location --
   -------------------------

   type chars_ptr_ptr is access all chars_ptr;

   Argv : chars_ptr_ptr;
   pragma Import (C, Argv, "gnat_argv");

   function Executable_Location return String is
      Exec_Name : constant String := Value (Argv.all);

      function Get_Install_Dir (S : String) return String;
      --  S is the executable name preceeded by the absolute or relative
      --  path, e.g. "c:\usr\bin\gcc.exe" or "..\bin\gcc". Returns the absolute
      --  or relative directory where "bin" lies (in the example "C:\usr"
      --  or ".."). If the executable is not a "bin" directory, return "".

      ---------------------
      -- Get_Install_Dir --
      ---------------------

      function Get_Install_Dir (S : String) return String is
         Exec      : String  := S;
         Path_Last : Integer := 0;

      begin
         for J in reverse Exec'Range loop
            if Is_Directory_Separator (Exec (J)) then
               Path_Last := J - 1;
               exit;
            end if;
         end loop;

         if Path_Last >= Exec'First + 2 then
            To_Lower (Exec (Path_Last - 2 .. Path_Last));
         end if;

         if Path_Last < Exec'First + 2
           or else Exec (Path_Last - 2 .. Path_Last) /= "bin"
           or else (Path_Last - 3 >= Exec'First
                    and then not Is_Directory_Separator (Exec (Path_Last - 3)))
         then
            return "";
         end if;

         return Exec (Exec'First .. Path_Last - 4);
      end Get_Install_Dir;

   --  Beginning of Executable_Location

   begin
      --  First determine if a path prefix was placed in front of the
      --  executable name.

      for J in reverse Exec_Name'Range loop
         if Is_Directory_Separator (Exec_Name (J)) then
            return Get_Install_Dir (Exec_Name);
         end if;
      end loop;

      --  If you are here, the user has typed the executable name with no
      --  directory prefix.

      declare
         Ex : String_Access := GNAT.OS_Lib.Locate_Exec_On_Path (Exec_Name);
         Dir : constant String := Get_Install_Dir (Ex.all);
      begin
         Free (Ex);
         return Dir;
      end;
   end Executable_Location;

   ----------------------------
   -- Is_Directory_Separator --
   ----------------------------

   function Is_Directory_Separator (C : Character) return Boolean is
   begin
      --  In addition to the default directory_separator allow the '/' to
      --  act as separator since this is allowed in MS-DOS, Windows 95/NT,
      --  and OS2 ports. On VMS, the situation is more complicated because
      --  there are two characters to check for.

      return C = Directory_Separator
        or else C = '/'
        or else (OpenVMS_Host and then (C = ']' or else C = ':'));
   end Is_Directory_Separator;

   ------------------
   -- Max_Path_Len --
   ------------------

   Max_Path : Integer;
   pragma Import (C, Max_Path, "max_path_len");
   --  Take advantage of max_path_len defined in the GNAT run time

   function Max_Path_Len return Natural is
   begin
      return Max_Path;
   end Max_Path_Len;

   ----------------------
   -- Set_OpenVMS_Host --
   ----------------------

   procedure Set_OpenVMS_Host (Setting : Boolean := True) is
   begin
      OpenVMS_Host := Setting;
   end Set_OpenVMS_Host;

   ------------------------
   -- Make_Dir_Recursive --
   ------------------------

   procedure Make_Dir_Recursive (Name : Virtual_File) is
      Parent : constant Virtual_File := Get_Parent (Name);

   begin
      if Parent = No_File or else Is_Directory (Name) then
         return;
      else
         Make_Dir_Recursive (Parent);
         Name.Make_Dir;
      end if;
   end Make_Dir_Recursive;

   --------------
   -- New_Line --
   --------------

   EOL : aliased constant String := (1 => ASCII.LF);

   procedure New_Line (File : File_Descriptor; Count : Natural := 1) is
      N : Integer;
      pragma Unreferenced (N);
   begin
      for J in 1 .. Count loop
         N := Write (File, EOL'Address, EOL'Length);
      end loop;
   end New_Line;

   ---------
   -- Put --
   ---------

   procedure Put (File : File_Descriptor; Str : String) is
      N : Integer;
      pragma Unreferenced (N);
   begin
      if Str'Length /= 0 then
         N := Write (File, Str (Str'First)'Address, Str'Length);
      end if;
   end Put;

   --------------
   -- Put_Line --
   --------------

   procedure Put_Line (File : File_Descriptor; Str : String) is
      N : Integer;
      pragma Unreferenced (N);
   begin
      if Str'Length /= 0 then
         N := Write (File, Str (Str'First)'Address, Str'Length);
      end if;

      N := Write (File, EOL'Address, EOL'Length);
   end Put_Line;

   --------------------
   -- Is_Cygwin_Path --
   --------------------

   function Is_Cygwin_Path (Path : Filesystem_String) return Boolean is
      Cygdrive : constant Filesystem_String := "/cygdrive/";
      use type Filesystem_String;
   begin
      return Path'Length > Cygdrive'Length + 1
        and then
      Path (Path'First .. Path'First + Cygdrive'Length - 1) = Cygdrive
        and then Is_Letter (Path (Path'First + Cygdrive'Length))
        and then Path (Path'First + Cygdrive'Length + 1) = '/';
   end Is_Cygwin_Path;

   ---------------------
   -- Format_Pathname --
   ---------------------

   function Format_Pathname
     (Path  : Filesystem_String;
      Style : Path_Style := System_Default) return Filesystem_String
   is
      function Cygwin_To_Dos
        (Path : Filesystem_String) return Filesystem_String;
      --  Convert the /cygdrive/<drive>/ prefix to the DOS <drive>:\ equivalent
      --  and convert a forward slashes to backward slashes.

      -------------------
      -- Cygwin_To_Dos --
      -------------------

      function Cygwin_To_Dos
        (Path : Filesystem_String) return Filesystem_String
      is
         Cygdrive : constant String := "/cygdrive/";
      begin
         if Is_Cygwin_Path (Path) then
            return +(Case_Util.To_Upper (Path (Path'First + Cygdrive'Length)) &
              ":") & Path (Path'First + Cygdrive'Length + 1 .. Path'Last);
         else
            return Path;
         end if;
      end Cygwin_To_Dos;

   begin
      case Style is
         when UNIX | System_Default =>
            return Format_Pathname
              (Path,
               Directory_Operations.Path_Style'Val (Path_Style'Pos (Style)));

         when DOS =>
            declare
               Result : constant Filesystem_String := Cygwin_To_Dos (Path);
            begin
               return Format_Pathname (Result, Directory_Operations.DOS);
            end;

         when Cygwin =>
            declare
               Result : constant Filesystem_String :=
                          Format_Pathname (Path, Directory_Operations.UNIX);
            begin
               if Result'Length > 2
                 and then (Result (Result'First) in 'A' .. 'Z'
                           or else Result (Result'First) in 'a' .. 'z')
                 and then Result (Result'First + 1) = ':'
                 and then Result (Result'First + 2) = '/'
               then
                  return +("/cygdrive/" &
                    Case_Util.To_Upper (Result (Result'First))) &
                    Result (Result'First + 2 .. Result'Last);
               else
                  return Result;
               end if;
            end;
      end case;
   end Format_Pathname;

   --------------------------
   -- Normalize_To_OS_Case --
   --------------------------

   function Normalize_To_OS_Case
     (Full_Name : Filesystem_String) return Filesystem_String
   is

      use type Config.Host_Type;

      function Norm (Dir, Name : String) return String;
      --  Normalize Name using OS casing and do the same recusivelly for full
      --  pathname in Dir.

      ----------
      -- Norm --
      ----------

      function Norm (Dir, Name : String) return String is
         L_Name  : String := Name;
         Search  : Search_Type;
         Entries : Directory_Entry_Type;
      begin
         Case_Util.To_Lower (L_Name);

         Start_Search (Search, Dir, "*");

         while More_Entries (Search) loop
            Get_Next_Entry (Search, Entries);

            declare
               S_Name : String := Simple_Name (Entries);
            begin
               Case_Util.To_Lower (S_Name);

               if L_Name = S_Name then
                  End_Search (Search);

                  if Dir'Length = 3 then
                     if Dir (Dir'First + 1 .. Dir'First + 2) = ":\" then
                        return Compose
                          (Case_Util.To_Upper (Dir (Dir'First)) & ":\",
                           Simple_Name (Entries));

                     else
                        return Compose (Dir, Simple_Name (Entries));
                     end if;

                  else
                     return Compose
                       (Norm (Containing_Directory (Dir), Simple_Name (Dir)),
                        Simple_Name (Entries));
                  end if;
               end if;
            end;
         end loop;

         --  Not found, return Full_Name
         End_Search (Search);
         return Compose (Dir, Name);
      end Norm;

   begin
      if Config.Host = Config.Windows
        and then (Is_Regular_File (Full_Name)
                  or else Is_Directory (Full_Name))
      then
         return +Norm
           (Containing_Directory (+Full_Name), Simple_Name (+Full_Name));
      else
         return Full_Name;
      end if;

   exception
      when Name_Error | Use_Error | Status_Error =>
         return Full_Name;
   end Normalize_To_OS_Case;

end OS_Utils;
