--  with System; use System;
--  with Glib; use Glib;
--  with Gdk.Event; use Gdk.Event;
--  with Gdk.Types; use Gdk.Types;
--  with Gtk.Accel_Group; use Gtk.Accel_Group;
--  with Gtk.Object; use Gtk.Object;
--  with Gtk.Enums; use Gtk.Enums;
--  with Gtk.Style; use Gtk.Style;
with Gtk.Widget; use Gtk.Widget;
with Switches_Editors; use Switches_Editors;

package body Switches_Editor_Pkg.Callbacks is

--     use Gtk.Arguments;

   --------------------------
   -- Refresh_All_Switches --
   --------------------------

   procedure Refresh_All_Switches
     (Object : access Gtk_Widget_Record'Class;
      Params : Gtk.Arguments.Gtk_Args)
   is
      Editor : Switches_Edit := Switches_Edit (Object);
--        Arg1 : Address := To_Address (Params, 1);
--        Arg2 : Guint := To_Guint (Params, 2);
   begin
      if Editor.Make_Switches /= null then
         Refresh_Make_Switches (Object);
      end if;
      if Editor.Compiler_Switches /= null then
         Refresh_Comp_Switches (Object);
      end if;
      if Editor.Binder_Switches /= null then
         Refresh_Bind_Switches (Object);
      end if;
   end Refresh_All_Switches;

   ---------------------------
   -- Refresh_Make_Switches --
   ---------------------------

   procedure Refresh_Make_Switches
     (Object : access Gtk_Widget_Record'Class)
   is
   begin
      Update_Cmdline (Switches_Edit (Object), Gnatmake);
   end Refresh_Make_Switches;

   ------------------------------------
   -- On_Make_Switches_Entry_Changed --
   ------------------------------------

   procedure On_Make_Switches_Entry_Changed
     (Object : access Gtk_Widget_Record'Class)
   is
   begin
      Update_Gui_From_Cmdline (Switches_Edit (Object), Gnatmake);
   end On_Make_Switches_Entry_Changed;

   ---------------------------
   -- Refresh_Comp_Switches --
   ---------------------------

   procedure Refresh_Comp_Switches
     (Object : access Gtk_Widget_Record'Class)
   is
   begin
      Update_Cmdline (Switches_Edit (Object), Compiler);
   end Refresh_Comp_Switches;

   ----------------------------------------
   -- On_Compiler_Switches_Entry_Changed --
   ----------------------------------------

   procedure On_Compiler_Switches_Entry_Changed
     (Object : access Gtk_Widget_Record'Class)
   is
   begin
      Update_Gui_From_Cmdline (Switches_Edit (Object), Compiler);
   end On_Compiler_Switches_Entry_Changed;

   --------------------------------------
   -- On_Binder_Switches_Entry_Changed --
   --------------------------------------

   procedure On_Binder_Switches_Entry_Changed
     (Object : access Gtk_Widget_Record'Class)
   is
   begin
      Update_Gui_From_Cmdline (Switches_Edit (Object), Binder);
   end On_Binder_Switches_Entry_Changed;

   ---------------------------
   -- Refresh_Bind_Switches --
   ---------------------------

   procedure Refresh_Bind_Switches
     (Object : access Gtk_Widget_Record'Class)
   is
   begin
      Update_Cmdline (Switches_Edit (Object), Binder);
   end Refresh_Bind_Switches;

   --------------------------------------
   -- On_Linker_Switches_Entry_Changed --
   --------------------------------------

   procedure On_Linker_Switches_Entry_Changed
     (Object : access Gtk_Widget_Record'Class)
   is
   begin
      Update_Gui_From_Cmdline (Switches_Edit (Object), Linker);
   end On_Linker_Switches_Entry_Changed;

   -----------------------------
   -- Refresh_Linker_Switches --
   -----------------------------

   procedure Refresh_Linker_Switches
     (Object : access Gtk_Widget_Record'Class)
   is
   begin
      Update_Cmdline (Switches_Edit (Object), Linker);
   end Refresh_Linker_Switches;

end Switches_Editor_Pkg.Callbacks;
