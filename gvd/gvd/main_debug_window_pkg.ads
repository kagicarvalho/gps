-----------------------------------------------------------------------
--                   GVD - The GNU Visual Debugger                   --
--                                                                   --
--                      Copyright (C) 2000-2001                      --
--                              ACT-Europe                           --
--                                                                   --
-- GVD is free  software;  you can redistribute it and/or modify  it --
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

with Gtk.Window; use Gtk.Window;
with Gtk.Box; use Gtk.Box;
with Gtk.Menu_Bar; use Gtk.Menu_Bar;
with Gtk.Menu_Item; use Gtk.Menu_Item;
with Gtk.Menu; use Gtk.Menu;
with Gtk.Check_Menu_Item; use Gtk.Check_Menu_Item;
with Gtk.Widget; use Gtk.Widget;
with Gtk.Frame; use Gtk.Frame;
with Gtk.Notebook; use Gtk.Notebook;
with GVD.Status_Bar; use GVD.Status_Bar;
with Gtkada.Toolbar; use Gtkada.Toolbar;

package Main_Debug_Window_Pkg is

   type Main_Debug_Window_Record is new Gtk_Window_Record with record
      Vbox1 : Gtk_Vbox;
      Menubar1 : Gtk_Menu_Bar;
      File1 : Gtk_Menu_Item;
      File1_Menu : Gtk_Menu;
      Open_Program1 : Gtk_Menu_Item;
      Open_Debugger1 : Gtk_Menu_Item;
      Open_Recent1 : Gtk_Menu_Item;
      Open_Core_Dump1 : Gtk_Menu_Item;
      Separator0 : Gtk_Menu_Item;
      Edit_Source1 : Gtk_Menu_Item;
      Open_Source1 : Gtk_Menu_Item;
      Reload_Sources1 : Gtk_Menu_Item;
      Separator1 : Gtk_Menu_Item;
      Open_Session1 : Gtk_Menu_Item;
      Save_Session_As1 : Gtk_Menu_Item;
      Separator2 : Gtk_Menu_Item;
      Attach_To_Process1 : Gtk_Menu_Item;
      Detach_Process1 : Gtk_Menu_Item;
      Separator3 : Gtk_Menu_Item;
      Change_Directory1 : Gtk_Menu_Item;
      Separator4 : Gtk_Menu_Item;
      Close1 : Gtk_Menu_Item;
      Exit1 : Gtk_Menu_Item;
      Edit2 : Gtk_Menu_Item;
      Edit2_Menu : Gtk_Menu;
      Undo1 : Gtk_Menu_Item;
      Redo1 : Gtk_Menu_Item;
      Separator5 : Gtk_Menu_Item;
      Cut1 : Gtk_Menu_Item;
      Copy1 : Gtk_Menu_Item;
      Paste1 : Gtk_Menu_Item;
      Select_All1 : Gtk_Menu_Item;
      Separator6 : Gtk_Menu_Item;
      Search1 : Gtk_Menu_Item;
      Separator7 : Gtk_Menu_Item;
      Preferences1 : Gtk_Menu_Item;
      Gdb_Settings1 : Gtk_Menu_Item;
      Program1 : Gtk_Menu_Item;
      Program1_Menu : Gtk_Menu;
      Run1 : Gtk_Menu_Item;
      Separator10 : Gtk_Menu_Item;
      Step1 : Gtk_Menu_Item;
      Step_Instruction1 : Gtk_Menu_Item;
      Next1 : Gtk_Menu_Item;
      Next_Instruction1 : Gtk_Menu_Item;
      Finish1 : Gtk_Menu_Item;
      Separator12 : Gtk_Menu_Item;
      Continue1 : Gtk_Menu_Item;
      Continue_Without_Signal1 : Gtk_Menu_Item;
      Separator13 : Gtk_Menu_Item;
      Kill1 : Gtk_Menu_Item;
      Interrupt1 : Gtk_Menu_Item;
      Abort1 : Gtk_Menu_Item;
      Command1 : Gtk_Menu_Item;
      Command1_Menu : Gtk_Menu;
      Command_History1 : Gtk_Menu_Item;
      Clear_Window1 : Gtk_Menu_Item;
      Separator14 : Gtk_Menu_Item;
      Define_Command1 : Gtk_Menu_Item;
      Edit_Buttons1 : Gtk_Menu_Item;
      Data1 : Gtk_Menu_Item;
      Data1_Menu : Gtk_Menu;
      Call_Stack : Gtk_Check_Menu_Item;
      Threads1 : Gtk_Menu_Item;
      Tasks1 : Gtk_Menu_Item;
      Signals1 : Gtk_Menu_Item;
      Separator17 : Gtk_Menu_Item;
      Edit_Breakpoints1 : Gtk_Menu_Item;
      Edit_Displays1 : Gtk_Menu_Item;
      Examine_Memory1 : Gtk_Menu_Item;
      Separator24 : Gtk_Menu_Item;
      Display_Local_Variables1 : Gtk_Menu_Item;
      Display_Arguments1 : Gtk_Menu_Item;
      Display_Registers1 : Gtk_Menu_Item;
      Display_Expression1 : Gtk_Menu_Item;
      More_Status_Display1 : Gtk_Menu_Item;
      Separator27 : Gtk_Menu_Item;
      Refresh1 : Gtk_Menu_Item;
      Show1 : Gtk_Menu_Item;
      Help1 : Gtk_Menu_Item;
      Help1_Menu : Gtk_Menu;
      Manual : Gtk_Menu_Item;
      About_Gvd : Gtk_Menu_Item;
      Toolbar2 : Gtkada_Toolbar;
      Button49 : Gtk_Widget;
      Button50 : Gtk_Widget;
      Button52 : Gtk_Widget;
      Button53 : Gtk_Widget;
      Button54 : Gtk_Widget;
      Button55 : Gtk_Widget;
      Button58 : Gtk_Widget;
      Button60 : Gtk_Widget;
      Button57 : Gtk_Widget;
      Button51 : Gtk_Widget;
      Button61 : Gtk_Widget;
      Frame7 : Gtk_Frame;
      Process_Notebook : Gtk_Notebook;
      Statusbar1 : GVD_Status_Bar;
   end record;
   type Main_Debug_Window_Access is access all Main_Debug_Window_Record'Class;

   procedure Gtk_New (Main_Debug_Window : out Main_Debug_Window_Access);
   procedure Initialize
     (Main_Debug_Window : access Main_Debug_Window_Record'Class);

end Main_Debug_Window_Pkg;
