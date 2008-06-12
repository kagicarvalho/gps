-----------------------------------------------------------------------
--                               G P S                               --
--                                                                   --
--                      Copyright (C) 2007-2008, AdaCore             --
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

with Ada.Strings.Unbounded;      use Ada.Strings.Unbounded;
with String_Utils;               use String_Utils;

package body Switches_Chooser is

   use Switch_Description_Vectors, Combo_Switch_Vectors;
   use Frame_Description_Vectors;

   procedure Add_To_Getopt
     (Config    : Switches_Editor_Config;
      Switch    : String;
      Separator : Character);
   --  Add Switch to the automatically constructed getopt string.
   --  If Separator is ASCII.NUL, then the switches takes a parameter, but
   --  might have no separator.
   --  If it is ASCII.LF, the switch takes no parameter.
   --  If it is ASCII.CR, the switch takes an optional parameter

   ------------
   -- Create --
   ------------

   function Create
     (Default_Separator : String;
      Switch_Char       : Character := '-';
      Scrolled_Window   : Boolean := False;
      Lines             : Positive := 1;
      Columns           : Positive := 1;
      Show_Command_Line : Boolean := True;
      Sections          : String := "") return Switches_Editor_Config
   is
      Config : Switches_Editor_Config;
      Start, Stop : Natural;
   begin
      Config := new Switches_Editor_Config_Record'
        (Lines             => Lines,
         Columns           => Columns,
         Default_Separator => To_Unbounded_String (Default_Separator),
         Getopt_Switches   => Null_Unbounded_String,
         Scrolled_Window   => Scrolled_Window,
         Switch_Char       => Switch_Char,
         Config            => <>,
         Max_Radio         => 0,
         Max_Popup         => Main_Window,
         Show_Command_Line => Show_Command_Line,
         Sections          => To_Unbounded_String (Sections),
         Switches          => <>,
         Frames            => <>,
         Dependencies      => null);

      --  Add sections to getopt switches
      Start := Sections'First;
      Stop  := Start + 1;

      while Stop <= Sections'Last loop
         if Sections (Stop) = ' ' then
            Add_To_Getopt (Config    => Config,
                           Switch    => Sections (Start .. Stop - 1),
                           Separator => ASCII.LF);
            Define_Section (Config.Config, Sections (Start .. Stop - 1));
            Start := Stop + 1;
            Stop := Start;

         elsif Stop = Sections'Last then
            Add_To_Getopt (Config    => Config,
                           Switch    => Sections (Start .. Stop),
                           Separator => ASCII.LF);
            Define_Section (Config.Config, Sections (Start .. Stop));
         end if;

         Stop := Stop + 1;
      end loop;

      return Config;
   end Create;

   -----------------------
   -- Set_Configuration --
   -----------------------

   procedure Set_Configuration
     (Config     : access Switches_Editor_Config_Record;
      Cmd_Config : Command_Line_Configuration)
   is
   begin
      Config.Config := Cmd_Config;
   end Set_Configuration;

   ---------------------
   -- Set_Frame_Title --
   ---------------------

   procedure Set_Frame_Title
     (Config    : Switches_Editor_Config;
      Title     : String;
      Line      : Positive := 1;
      Column    : Positive := 1;
      Line_Span : Natural := 1;
      Col_Span  : Natural := 1;
      Popup     : Popup_Index := Main_Window)
   is
   begin
      Append
        (Config.Frames,
         Frame_Description'
           (Title     => To_Unbounded_String (Title),
            Line      => Line,
            Column    => Column,
            Popup     => Popup,
            Line_Span => Line_Span,
            Col_Span  => Col_Span));
   end Set_Frame_Title;

   -------------------
   -- Add_To_Getopt --
   -------------------

   procedure Add_To_Getopt
     (Config    : Switches_Editor_Config;
      Switch    : String;
      Separator : Character)
   is
   begin
      --  If the switch has an argument, it must start with Switch_Char.
      --  Otherwise, Getopt (called in Set_Command_Line) will not recognize it
      --  and cannot properly associate its parameter with it.
      --  If this proves to be too much of an issue, and when the switch does
      --  not start with Switch_Char, we mark it as having no parameter, which
      --  is not ideal but should work.
      --  The most common case of having two or more switch_char is for
      --  enabling and disabling options as in "+opt -opt", so these are
      --  check buttons, with no parameter anyway

      if Separator = ASCII.LF
        or else Switch (Switch'First) /= Config.Switch_Char
      then
         Append (Config.Getopt_Switches,
                 " " & Switch (Switch'First + 1 .. Switch'Last));
      elsif Separator = ASCII.NUL then
         Append (Config.Getopt_Switches,
                 " " & Switch (Switch'First + 1 .. Switch'Last) & "!");
      elsif Separator = '=' then
         Append (Config.Getopt_Switches,
                 " " & Switch (Switch'First + 1 .. Switch'Last) & "=");
      elsif Separator = ASCII.CR then
         Append (Config.Getopt_Switches,
                 " " & Switch (Switch'First + 1 .. Switch'Last) & "?");
      else
         Append (Config.Getopt_Switches,
                 " " & Switch (Switch'First + 1 .. Switch'Last) & ":");
      end if;
   end Add_To_Getopt;

   ---------------
   -- Add_Check --
   ---------------

   procedure Add_Check
     (Config  : Switches_Editor_Config;
      Label   : String;
      Switch  : String;
      Section : String := "";
      Tip     : String := "";
      Line    : Positive := 1;
      Column  : Positive := 1;
      Popup   : Popup_Index := Main_Window)
   is
   begin
      Append
        (Config.Switches,
         Switch_Description'
           (Typ           => Switch_Check,
            Switch        => To_Unbounded_String (Switch),
            Switch_Unset  => Null_Unbounded_String,
            Default_State => False,
            Label         => To_Unbounded_String (Label),
            Tip           => To_Unbounded_String (Tip),
            Section       => To_Unbounded_String (Section),
            Separator     => ASCII.NUL,
            Popup         => Popup,
            Line          => Line,
            Column        => Column));
      Add_To_Getopt (Config, Switch, ASCII.LF);
   end Add_Check;

   ---------------
   -- Add_Check --
   ---------------

   procedure Add_Check
     (Config        : Switches_Editor_Config;
      Label         : String;
      Switch_Set    : String;
      Switch_Unset  : String;
      Default_State : Boolean;
      Section       : String := "";
      Tip           : String := "";
      Line          : Positive := 1;
      Column        : Positive := 1;
      Popup         : Popup_Index := Main_Window)
   is
   begin
      Append
        (Config.Switches,
         Switch_Description'
           (Typ           => Switch_Check,
            Switch        => To_Unbounded_String (Switch_Set),
            Switch_Unset  => To_Unbounded_String (Switch_Unset),
            Default_State => Default_State,
            Label         => To_Unbounded_String (Label),
            Tip           => To_Unbounded_String (Tip),
            Section       => To_Unbounded_String (Section),
            Separator     => ASCII.NUL,
            Popup         => Popup,
            Line          => Line,
            Column        => Column));
      Add_To_Getopt (Config, Switch_Set, ASCII.LF);
      Add_To_Getopt (Config, Switch_Unset, ASCII.LF);
   end Add_Check;

   ---------------
   -- Add_Field --
   ---------------

   procedure Add_Field
     (Config       : Switches_Editor_Config;
      Label        : String;
      Switch       : String;
      Separator    : String := ""; --  no separator
      Section      : String := "";
      Tip          : String := "";
      As_Directory : Boolean := False;
      As_File      : Boolean := False;
      Line         : Positive := 1;
      Column       : Positive := 1;
      Popup        : Popup_Index := Main_Window)
   is
      Sep : Character := ASCII.NUL;
   begin
      if Separator /= "" then
         Sep := Separator (Separator'First);
      end if;

      Append
        (Config.Switches,
         Switch_Description'
           (Typ => Switch_Field,
            Switch  => To_Unbounded_String (Switch),
            Label   => To_Unbounded_String (Label),
            Tip     => To_Unbounded_String (Tip),
            Section => To_Unbounded_String (Section),
            Separator => Sep,
            As_Directory => As_Directory,
            As_File      => As_File,
            Line   => Line,
            Column => Column,
            Popup  => Popup));
      Add_To_Getopt (Config, Switch, Sep);
   end Add_Field;

   --------------
   -- Add_Spin --
   --------------

   procedure Add_Spin
     (Config    : Switches_Editor_Config;
      Label     : String;
      Switch    : String;
      Separator : String := ""; --  no separator
      Min       : Integer;
      Max       : Integer;
      Default   : Integer;
      Section   : String := "";
      Tip       : String := "";
      Line      : Positive := 1;
      Column    : Positive := 1;
      Popup     : Popup_Index := Main_Window)
   is
      Sep : Character := ASCII.NUL;
   begin
      if Separator /= "" then
         Sep := Separator (Separator'First);
      end if;
      Append
        (Config.Switches,
         Switch_Description'
           (Typ       => Switch_Spin,
            Switch    => To_Unbounded_String (Switch),
            Label     => To_Unbounded_String (Label),
            Tip       => To_Unbounded_String (Tip),
            Section   => To_Unbounded_String (Section),
            Separator => Sep,
            Min       => Min,
            Max       => Max,
            Default   => Default,
            Line      => Line,
            Column    => Column,
            Popup     => Popup));
      Add_To_Getopt (Config, Switch, Sep);
   end Add_Spin;

   ---------------
   -- Add_Combo --
   ---------------

   procedure Add_Combo
     (Config    : Switches_Editor_Config;
      Label     : String;
      Switch    : String;
      Separator : String := ""; --  no separator
      No_Switch : String;
      No_Digit  : String;
      Entries   : Combo_Switch_Array;
      Section   : String := "";
      Tip       : String := "";
      Line      : Positive := 1;
      Column    : Positive := 1;
      Popup     : Popup_Index := Main_Window)
   is
      Ent : Combo_Switch_Vectors.Vector;
      S   : Character := ASCII.NUL;
   begin
      for E in Entries'Range loop
         Append (Ent, Entries (E));
      end loop;

      if Separator /= "" then
         S := Separator (Separator'First);
      end if;

      Append
        (Config.Switches,
         Switch_Description'
           (Typ       => Switch_Combo,
            Switch    => To_Unbounded_String (Switch),
            Label     => To_Unbounded_String (Label),
            Tip       => To_Unbounded_String (Tip),
            Section   => To_Unbounded_String (Section),
            Separator => S,
            No_Switch => To_Unbounded_String (No_Switch),
            No_Digit  => To_Unbounded_String (No_Digit),
            Entries   => Ent,
            Line      => Line,
            Column    => Column,
            Popup     => Popup));

      if Separator = "" then
         Add_To_Getopt (Config, Switch, ASCII.CR);      --  optional parameter
      else
         Add_To_Getopt (Config, Switch, Separator (Separator'First));
      end if;
   end Add_Combo;

   ---------------
   -- Add_Popup --
   ---------------

   function Add_Popup
     (Config  : Switches_Editor_Config;
      Label   : String;
      Lines   : Positive := 1;
      Columns : Positive := 1;
      Line    : Positive := 1;
      Column  : Positive := 1;
      Popup   : Popup_Index := Main_Window) return Popup_Index
   is
   begin
      Config.Max_Popup := Config.Max_Popup + 1;
      Append
        (Config.Switches,
         Switch_Description'
           (Typ       => Switch_Popup,
            Switch    => Null_Unbounded_String,
            Label     => To_Unbounded_String (Label),
            Tip       => Null_Unbounded_String,
            Section   => Null_Unbounded_String,
            Separator => ASCII.NUL,
            Line      => Line,
            Column    => Column,
            Lines     => Lines,
            Columns   => Columns,
            Popup     => Popup,
            To_Popup  => Config.Max_Popup));
      return Config.Max_Popup;
   end Add_Popup;

   ---------------
   -- Add_Radio --
   ---------------

   function Add_Radio
     (Config  : Switches_Editor_Config;
      Line    : Positive := 1;
      Column  : Positive := 1;
      Popup   : Popup_Index := Main_Window) return Radio_Switch
   is
   begin
      Config.Max_Radio := Config.Max_Radio + 1;
      Append
        (Config.Switches,
         Switch_Description'
           (Typ       => Switch_Radio,
            Switch    => Null_Unbounded_String,
            Label     => Null_Unbounded_String,
            Tip       => Null_Unbounded_String,
            Section   => Null_Unbounded_String,
            Separator => ASCII.NUL,
            Group     => Config.Max_Radio,
            Line      => Line,
            Column    => Column,
            Popup     => Popup));
      return Config.Max_Radio;
   end Add_Radio;

   ---------------------
   -- Add_Radio_Entry --
   ---------------------

   procedure Add_Radio_Entry
     (Config    : Switches_Editor_Config;
      Radio     : Radio_Switch;
      Label     : String;
      Switch    : String;
      Section   : String := "";
      Tip       : String := "")
   is
   begin
      Append
        (Config.Switches,
         Switch_Description'
           (Typ       => Switch_Radio,
            Switch    => To_Unbounded_String (Switch),
            Label     => To_Unbounded_String (Label),
            Tip       => To_Unbounded_String (Tip),
            Section   => To_Unbounded_String (Section),
            Separator => ASCII.NUL,
            Group     => Radio,
            Line      => 1,
            Column    => 1,
            Popup     => Main_Window));
      Add_To_Getopt (Config, Switch, ASCII.LF);
   end Add_Radio_Entry;

   --------------------
   -- Add_Dependency --
   --------------------

   procedure Add_Dependency
     (Config         : Switches_Editor_Config;
      Switch         : String;
      Section        : String;
      Status         : Boolean;
      Slave_Tool     : String;
      Slave_Switch   : String;
      Slave_Section  : String;
      Slave_Activate : Boolean := True) is
   begin
      Config.Dependencies := new Dependency_Description'
        (Next           => Config.Dependencies,
         Master_Switch  => new String'(Switch),
         Master_Section => new String'(Section),
         Master_Status  => Status,
         Slave_Tool     => new String'(Slave_Tool),
         Slave_Section  => new String'(Slave_Section),
         Slave_Switch   => new String'(Slave_Switch),
         Slave_Status   => Slave_Activate,
         Act_On_Default => False);
   end Add_Dependency;

   ----------------------------
   -- Add_Dependency_Default --
   ----------------------------

   procedure Add_Default_Value_Dependency
     (Config         : Switches_Editor_Config;
      Switch         : String;
      Section        : String;
      Slave_Switch   : String;
      Slave_Section  : String) is
   begin
      Config.Dependencies := new Dependency_Description'
        (Next           => Config.Dependencies,
         Master_Switch  => new String'(Switch),
         Master_Section => new String'(Section),
         Master_Status  => False,
         Slave_Tool     => null,
         Slave_Section  => new String'(Slave_Section),
         Slave_Switch   => new String'(Slave_Switch),
         Slave_Status   => False,
         Act_On_Default => True);
   end Add_Default_Value_Dependency;

   ----------------------
   -- Get_Command_Line --
   ----------------------

   procedure Get_Command_Line
     (Cmd      : in out Command_Line;
      Expanded : Boolean;
      Result   : out GNAT.Strings.String_List_Access)
   is
      Iter  : Command_Line_Iterator;
      Count : Natural := 0;
   begin
      Start (Cmd, Iter, Expanded => Expanded);
      while Has_More (Iter) loop
         Count := Count + 1;

         if Current_Separator (Iter) = " "
           and then Current_Parameter (Iter) /= ""
         then
            Count := Count + 1;
         end if;

         Next (Iter);
      end loop;

      Result := new String_List (1 .. Count);
      Count := Result'First;
      Start (Cmd, Iter, Expanded => Expanded);
      while Has_More (Iter) loop
         if Is_New_Section (Iter) then
            Result (Count) := new String'(Current_Section (Iter));
            Count := Count + 1;
         end if;

         if Current_Separator (Iter) /= " " then
            if Current_Parameter (Iter) /= "" then
               Result (Count) := new String'
                 (Current_Switch (Iter)
                  & Current_Separator (Iter)
                  & Current_Parameter (Iter));

            else
               Result (Count) := new String'(Current_Switch (Iter));
            end if;

            Count := Count + 1;

         else
            Result (Count) := new String'(Current_Switch (Iter));
            Count := Count + 1;

            if Current_Parameter (Iter) /= "" then
               Result (Count) := new String'(Current_Parameter (Iter));
               Count := Count + 1;
            end if;
         end if;

         Next (Iter);
      end loop;
   end Get_Command_Line;

   ---------------------------
   -- Root_Switches_Editors --
   ---------------------------

   package body Switches_Editors is

      ----------------
      -- Initialize --
      ----------------

      procedure Initialize
        (Editor : in out Root_Switches_Editor;
         Config : Switches_Editor_Config)
      is
      begin
         Set_Configuration (Editor.Cmd_Line, Config.Config);
         Editor.Config := Config;
         Editor.Widgets := new Widget_Array
           (0 .. Integer (Length (Config.Switches)));
      end Initialize;

      ----------------------
      -- Get_Tool_By_Name --
      ----------------------

      function Get_Tool_By_Name
        (Editor : Root_Switches_Editor;
         Tool_Name : String) return Root_Switches_Editor_Access
      is
         pragma Unreferenced (Editor, Tool_Name);
      begin
         return null;
      end Get_Tool_By_Name;

      ----------------------
      -- Get_Command_Line --
      ----------------------

      function Get_Command_Line
        (Editor   : access Root_Switches_Editor;
         Expanded : Boolean) return GNAT.Strings.String_List_Access
      is
         Result : String_List_Access;
      begin
         Get_Command_Line (Editor.Cmd_Line, Expanded, Result);
         return Result;
      end Get_Command_Line;

      ----------------
      -- Set_Widget --
      ----------------

      procedure Set_Widget
        (Editor       : in out Root_Switches_Editor;
         Switch_Index : Integer;
         Widget       : access Root_Widget_Record'Class)
      is
      begin
         Editor.Widgets (Switch_Index) := Root_Widget (Widget);
      end Set_Widget;

      procedure Handle_Dependencies
        (Editor  : in out Root_Switches_Editor'Class;
         Switch  : String;
         Section : String;
         Status  : Boolean);
      --  If necessary, toggle other switches in other tools to reflect
      --  the change of status of Switch

      --------------------------
      -- Handle_Dependencies --
      --------------------------

      procedure Handle_Dependencies
        (Editor  : in out Root_Switches_Editor'Class;
         Switch  : String;
         Section : String;
         Status  : Boolean)
      is
         Deps     : Dependency_Description_Access :=
                      Editor.Config.Dependencies;
         Tool     : Root_Switches_Editor_Access;

      begin
         while Deps /= null loop
            if not Deps.Act_On_Default
              and then Deps.Master_Switch.all = Switch
              and then Deps.Master_Section.all = Section
              and then Deps.Master_Status = Status
            then
               --  Find the slave tool
               Tool := Get_Tool_By_Name
                 (Editor,
                  Deps.Slave_Tool.all);

               if Tool /= null then
                  --  We give just a hint to the user that the switch
                  --  should be added, by preselecting it. The user is
                  --  still free to force another value for the slave
                  --  switch. Even if we were setting the widget as
                  --  insensitive, the command line would still be
                  --  editable anyway.

                  if Deps.Slave_Status then
                     Add_Switch
                       (Tool.Cmd_Line,
                        Section => Deps.Slave_Section.all,
                        Switch  => Deps.Slave_Switch.all);
                  else
                     Remove_Switch
                       (Tool.Cmd_Line,
                        Section => Deps.Slave_Section.all,
                        Switch  => Deps.Slave_Switch.all);
                  end if;

                  On_Command_Line_Changed (Tool.all);
                  Update_Graphical_Command_Line (Tool.all);
               end if;

            elsif Deps.Act_On_Default
              and then Deps.Master_Switch.all = Switch
              and then Deps.Master_Section.all = Section
            then
               for W in Editor.Config.Switches.First_Index ..
                 Editor.Config.Switches.Last_Index
               loop
                  declare
                     S       : Switch_Description :=
                                 Element (Editor.Config.Switches, W);
                     Changed : Boolean := False;

                  begin
                     if To_String (S.Section) = Deps.Slave_Section.all
                       and then S.Typ = Switch_Check
                     then
                        if To_String (S.Switch) = Deps.Slave_Switch.all
                          and then Status /= S.Default_State
                        then
                           S.Default_State := Status;
                           Changed := True;

                        elsif To_String (S.Switch_Unset) =
                          Deps.Slave_Switch.all
                          and then Status = S.Default_State
                        then
                           S.Default_State := not Status;
                           Changed := True;
                        end if;

                        if Changed then
                           if not Status then
                              --  We are deactivating a switch, let's
                              --  remove unnecessary deactivation switch
                              Remove_Switch
                                (Editor.Cmd_Line,
                                 Section => Deps.Slave_Section.all,
                                 Switch  => To_String (S.Switch_Unset));
                           end if;

                           Editor.Config.Switches.Replace_Element (W, S);
                           Set_Graphical_Widget
                             (Editor,
                              Editor.Widgets (W),
                              S.Typ,
                              Boolean'Image (Status),
                              Is_Default => True);

                           --  We found the slave switch. Let's stop the
                           --  search.
                           exit;
                        end if;
                     end if;
                  end;
               end loop;
            end if;

            Deps := Deps.Next;
         end loop;
      end Handle_Dependencies;

      -------------------
      -- Change_Switch --
      -------------------

      procedure Change_Switch
        (Editor    : in out Root_Switches_Editor;
         Widget    : access Root_Widget_Record'Class;
         Parameter : String)
      is

         Combo : Combo_Switch_Vectors.Cursor;
         Val   : Boolean;

      begin
         if not Editor.Block then
            for W in Editor.Widgets'Range loop
               if Editor.Widgets (W) = Root_Widget (Widget) then
                  declare
                     S : constant Switch_Description :=
                       Element (Editor.Config.Switches, W);
                  begin
                     --  We first remove the switch from the command line,
                     --  and add it later on if the corresponding widget is
                     --  checked
                     Remove_Switch (Editor.Cmd_Line,
                                    Section => To_String (S.Section),
                                    Switch  => To_String (S.Switch));

                     if S.Typ = Switch_Check
                       and then S.Switch_Unset /= Null_Unbounded_String
                     then
                        Remove_Switch (Editor.Cmd_Line,
                                       Section => To_String (S.Section),
                                       Switch  => To_String (S.Switch_Unset));
                     end if;

                     case S.Typ is
                        when Switch_Check =>
                           if Parameter = "Checked" then
                              Add_Switch
                                (Editor.Cmd_Line,
                                 Section => To_String (S.Section),
                                 Switch  => To_String (S.Switch));
                              Val := True;

                           elsif Parameter = "Unchecked" then
                              if S.Default_State then
                                 --  If 'unchecked' while the default state
                                 --  is 'checked', explicitely add the
                                 --  deactivation switch
                                 Add_Switch
                                   (Editor.Cmd_Line,
                                    Section => To_String (S.Section),
                                    Switch  => To_String (S.Switch_Unset));
                              end if;

                              Val := False;

                           else
                              --  Checked_Default state
                              Val := True;
                           end if;

                           Handle_Dependencies
                             (Editor,
                              To_String (S.Switch),
                              To_String (S.Section),
                              Val);

                           if S.Switch_Unset /= Null_Unbounded_String then
                              Handle_Dependencies
                                (Editor,
                                 To_String (S.Switch_Unset),
                                 To_String (S.Section),
                                 not Val);
                           end if;

                        when Switch_Radio =>
                           if Boolean'Value (Parameter) then
                              Add_Switch
                                (Editor.Cmd_Line,
                                 Section => To_String (S.Section),
                                 Switch  => To_String (S.Switch));
                           end if;
                           Handle_Dependencies
                             (Editor,
                              To_String (S.Switch),
                              To_String (S.Section),
                              Boolean'Value (Parameter));

                        when Switch_Field =>
                           if Parameter /= "" then
                              Add_Switch
                                (Editor.Cmd_Line,
                                 Section   => To_String (S.Section),
                                 Switch    => To_String (S.Switch),
                                 Parameter => Parameter,
                                 Separator => S.Separator);
                           end if;
                           Handle_Dependencies
                             (Editor,
                              To_String (S.Switch),
                              To_String (S.Section),
                              Parameter /= "");

                        when Switch_Spin =>
                           if Integer'Value (Parameter) /= S.Default then
                              Add_Switch
                                (Editor.Cmd_Line,
                                 Section   => To_String (S.Section),
                                 Switch    => To_String (S.Switch),
                                 Parameter => Parameter,
                                 Separator => S.Separator);
                           end if;
                           Handle_Dependencies
                             (Editor,
                              To_String (S.Switch),
                              To_String (S.Section),
                              Integer'Value (Parameter) /= S.Default);

                        when Switch_Combo =>
                           Combo := First (S.Entries);
                           while Has_Element (Combo) loop
                              if Element (Combo).Label = Parameter then
                                 if Element (Combo).Value = S.No_Switch then
                                    Handle_Dependencies
                                      (Editor,
                                       To_String (S.Switch),
                                       To_String (S.Section),
                                       False);
                                 elsif Element (Combo).Value = S.No_Digit then
                                    Add_Switch
                                      (Editor.Cmd_Line,
                                       Section => To_String (S.Section),
                                       Switch  => To_String (S.Switch));
                                    Handle_Dependencies
                                      (Editor,
                                       To_String (S.Switch),
                                       To_String (S.Section),
                                       True);
                                 else
                                    Add_Switch
                                      (Editor.Cmd_Line,
                                       Section   => To_String (S.Section),
                                       Switch    => To_String (S.Switch),
                                       Parameter =>
                                         To_String (Element (Combo).Value),
                                       Separator => S.Separator);
                                    Handle_Dependencies
                                      (Editor,
                                       To_String (S.Switch),
                                       To_String (S.Section),
                                       True);
                                 end if;

                              end if;
                              Next (Combo);
                           end loop;

                        when Switch_Popup =>
                           null;
                     end case;

                     Update_Graphical_Command_Line
                       (Root_Switches_Editor'Class (Editor));
                     return;
                  end;
               end if;
            end loop;
         end if;
      end Change_Switch;

      -----------------------------------
      -- Update_Graphical_Command_Line --
      -----------------------------------

      procedure Update_Graphical_Command_Line
        (Editor : in out Root_Switches_Editor)
      is
         Iter    : Command_Line_Iterator;
         Cmd     : Unbounded_String;

      begin
         Editor.Block := True;

         Start (Editor.Cmd_Line, Iter, Expanded => False);
         while Has_More (Iter) loop
            if Is_New_Section (Iter) then
               Append (Cmd, Current_Section (Iter) & " ");
            end if;

            if Current_Parameter (Iter) /= "" then
               Append (Cmd, Current_Switch (Iter)
                       & Current_Separator (Iter)
                       & Current_Parameter (Iter) & " ");
            else
               Append (Cmd, Current_Switch (Iter) & " ");
            end if;

            Next (Iter);
         end loop;

         Set_Graphical_Command_Line
           (Root_Switches_Editor'Class (Editor), To_String (Cmd));
         Editor.Block := False;
      end Update_Graphical_Command_Line;

      ---------
      -- "=" --
      ---------

      function "="
        (Editor : access Root_Switches_Editor;
         Args   : GNAT.Strings.String_List) return Boolean
      is
         Cmd2         : Command_Line;
         Iter1, Iter2 : Command_Line_Iterator;
      begin
         --  ??? Not efficient to go back to a string

         Set_Configuration (Cmd2, Get_Configuration (Editor.Cmd_Line));
         Set_Command_Line
           (Cmd2,
            Argument_List_To_String (Args),
            To_String (Editor.Config.Getopt_Switches),
            Switch_Char => Editor.Config.Switch_Char);

         --  The two command lines are equal if the switches are exactly in the
         --  same order. This is needed for instance when the user has typed
         --  some libraries to link with, and their order should be preserved.
         --  That means, however, that if the user unchecks and then rechecks
         --  a check button, then the command line will appear as modified.
         --  (See G315-031)

         Start (Editor.Cmd_Line, Iter1, Expanded => True);
         Start (Cmd2,            Iter2, Expanded => True);
         while Has_More (Iter1) loop
            if not Has_More (Iter2) then
               return False;
            end if;

            if Current_Switch (Iter1) /= Current_Switch (Iter2)
              or else Current_Separator (Iter1) /= Current_Separator (Iter2)
              or else Current_Parameter (Iter1) /= Current_Parameter (Iter2)
              or else Current_Section (Iter1) /= Current_Section (Iter2)
            then
               return False;
            end if;

            Next (Iter1);
            Next (Iter2);
         end loop;

         return not Has_More (Iter2);
      end "=";

      -----------------------------
      -- On_Command_Line_Changed --
      -----------------------------

      procedure On_Command_Line_Changed
        (Editor   : in out Root_Switches_Editor;
         Cmd_Line : String)
      is
      begin
         if Editor.Block then
            return;
         end if;

         Editor.Block := True;
         Set_Command_Line
           (Editor.Cmd_Line, Cmd_Line,
            To_String (Editor.Config.Getopt_Switches),
            Switch_Char => Editor.Config.Switch_Char);
         Editor.Block := False;
         On_Command_Line_Changed (Editor);
      end On_Command_Line_Changed;

      -----------------------------
      -- On_Command_Line_Changed --
      -----------------------------

      procedure On_Command_Line_Changed
        (Editor   : in out Root_Switches_Editor'Class)
      is
         Iter                : Command_Line_Iterator;
         Switch              : Switch_Description_Vectors.Cursor :=
                                 First (Editor.Config.Switches);
         Current_Radio_Group : Radio_Switch := -1;

      begin
         if Editor.Block then
            return;
         end if;

         Editor.Block := True;

         while Has_Element (Switch) loop
            declare
               S : constant Switch_Description := Element (Switch);
            begin
               if Editor.Widgets (To_Index (Switch)) /= null then
                  Start (Editor.Cmd_Line, Iter, Expanded => True);

                  while Has_More (Iter) loop
                     exit when To_String (S.Switch) = Current_Switch (Iter)
                       and then To_String (S.Section) = Current_Section (Iter);
                     exit when S.Typ = Switch_Check
                       and then
                         To_String (S.Switch_Unset) = Current_Switch (Iter)
                       and then To_String (S.Section) = Current_Section (Iter);

                     Next (Iter);
                  end loop;

                  case S.Typ is
                     when Switch_Check =>
                        declare
                           State      : Boolean;
                           Is_Default : Boolean;
                        begin
                           if not Has_More (Iter) then
                              Is_Default := True;
                           else
                              Is_Default := False;
                           end if;

                           if not Is_Default then
                              State := To_String (S.Switch) =
                                Current_Switch (Iter);
                           else
                              State := S.Default_State;
                           end if;

                           Set_Graphical_Widget
                             (Editor,
                              Editor.Widgets (To_Index (Switch)),
                              S.Typ,
                              Boolean'Image (State),
                              Is_Default);

                           Handle_Dependencies
                             (Editor,
                              To_String (S.Switch),
                              To_String (S.Section),
                              State);

                           if To_String (S.Switch_Unset) /= "" then
                              Handle_Dependencies
                                (Editor,
                                 To_String (S.Switch_Unset),
                                 To_String (S.Section),
                                 not State);
                           end if;
                        end;

                     when Switch_Spin =>
                        if Current_Parameter (Iter) = "" then
                           Set_Graphical_Widget
                             (Editor,
                              Editor.Widgets (To_Index (Switch)),
                              S.Typ,
                              Integer'Image (S.Default));

                        else
                           Set_Graphical_Widget
                             (Editor,
                              Editor.Widgets (To_Index (Switch)),
                              S.Typ,
                              Current_Parameter (Iter));
                        end if;

                     when Switch_Field =>
                        Set_Graphical_Widget
                          (Editor,
                           Editor.Widgets (To_Index (Switch)),
                           S.Typ,
                           Current_Parameter (Iter));

                     when Switch_Radio =>
                        --  If we are starting a new radio group, pre-select
                        --  the first in the group, which is the default. It
                        --  will automatically get unselected if some other
                        --  element in the group is selected

                        if Editor.Widgets (To_Index (Switch)) /= null then
                           Set_Graphical_Widget
                             (Editor,
                              Editor.Widgets (To_Index (Switch)),
                              S.Typ,
                              Boolean'Image
                                (S.Group /= Current_Radio_Group
                                 or else Has_More (Iter)));
                           Current_Radio_Group := S.Group;
                        end if;

                     when Switch_Combo =>
                        declare
                           Combo : Combo_Switch_Vectors.Cursor
                             := First (S.Entries);
                           Param : constant String := Current_Parameter (Iter);
                        begin
                           while Has_Element (Combo) loop
                              if not Has_More (Iter) then
                                 exit when Element (Combo).Value = S.No_Switch;
                              else
                                 exit when
                                   (Param = ""
                                    and then
                                       Element (Combo).Value = S.No_Digit)
                                   or else Element (Combo).Value = Param;
                              end if;
                              Next (Combo);
                           end loop;

                           if Has_Element (Combo) then
                              Set_Graphical_Widget
                                (Editor,
                                 Editor.Widgets (To_Index (Switch)),
                                 S.Typ,
                                 To_String (Element (Combo).Label));
                           end if;
                        end;

                     when Switch_Popup =>
                        null;
                  end case;
               end if;
            end;

            Next (Switch);
         end loop;

         Editor.Block := False;
      end On_Command_Line_Changed;

      ----------------------
      -- Set_Command_Line --
      ----------------------

      procedure Set_Command_Line
        (Editor   : access Root_Switches_Editor;
         Cmd_Line : String)
      is
      begin
         Set_Graphical_Command_Line
           (Root_Switches_Editor'Class (Editor.all), Cmd_Line);
         On_Command_Line_Changed
           (Root_Switches_Editor'Class (Editor.all), Cmd_Line);
      end Set_Command_Line;

      ----------------------
      -- Set_Command_Line --
      ----------------------

      procedure Set_Command_Line
        (Editor   : access Root_Switches_Editor;
         Cmd_Line : GNAT.Strings.String_List)
      is
      begin
         --  ??? Not very efficient to go through a string
         Set_Command_Line
           (Root_Switches_Editor'Class (Editor.all)'Access,
            Argument_List_To_String (Cmd_Line));
      end Set_Command_Line;

      ----------------
      -- Get_Config --
      ----------------

      function Get_Config
        (Editor : access Root_Switches_Editor)
         return Switches_Editor_Config is
      begin
         return Editor.Config;
      end Get_Config;

      ----------------------
      -- Get_Command_Line --
      ----------------------

      function Get_Command_Line
        (Editor : access Root_Switches_Editor)
         return Command_Line
      is
      begin
         return Editor.Cmd_Line;
      end Get_Command_Line;

   end Switches_Editors;

end Switches_Chooser;
