with Gtk.Handlers;
with Gtk.Menu_Item; use Gtk.Menu_Item;
with Gtk.Check_Menu_Item; use Gtk.Check_Menu_Item;
with Gtk.Button; use Gtk.Button;
with Gtk.Radio_Button; use Gtk.Radio_Button;
with Gtk.List; use Gtk.List;

package Callbacks_Odd is

   package Menu_Item_Callback is new
     Gtk.Handlers.Callback (Gtk_Menu_Item_Record);

   package Check_Menu_Item_Callback is new
     Gtk.Handlers.Callback (Gtk_Check_Menu_Item_Record);

   package Button_Callback is new
     Gtk.Handlers.Callback (Gtk_Button_Record);

   package Radio_Button_Callback is new
     Gtk.Handlers.Callback (Gtk_Radio_Button_Record);

   package List_Callback is new
     Gtk.Handlers.Callback (Gtk_List_Record);

end Callbacks_Odd;
