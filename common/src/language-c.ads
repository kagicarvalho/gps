-----------------------------------------------------------------------
--                              G P S                                --
--                                                                   --
--                     Copyright (C) 2000-2005                       --
--                             AdaCore                               --
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

--  This is the general C (non debugger specific) support package.
--  See language.ads for a complete spec.

package Language.C is

   type C_Language is new Language_Root with private;

   C_Lang : constant Language_Access;
   --  Class constant for the C language.

   -------------
   -- Parsing --
   -------------

   function Is_Simple_Type
     (Lang : access C_Language; Str : String) return Boolean;

   ------------------
   -- Highlighting --
   ------------------

   function Keywords
     (Lang : access C_Language) return Pattern_Matcher_Access;

   function Get_Language_Context
     (Lang : access C_Language) return Language_Context_Access;

   C_Keywords_Regexp : constant String :=
     "auto|break|c(ase|on(st|tinue)|har)|d(efault|o|ouble)|e(lse|num|xtern)|" &
     "f(loat|or)|goto|i(f|n(t|line))|long|re(gister|strict|turn)|" &
     "s(hort|i(gned|zeof)|t(atic|ruct)|witch)|un(ion|signed)|vo(id|latile)|" &
     "while|typedef";
   --  Regexp used to highlight keywords in C.
   --  Do not use this directly, use the function Keywords instead.

   --------------
   -- Explorer --
   --------------

   function Explorer_Regexps
     (Lang : access C_Language) return Explorer_Categories;

   ------------------------
   -- Naming Conventions --
   ------------------------

   function Dereference_Name
     (Lang : access C_Language;
      Name : String) return String;

   function Array_Item_Name
     (Lang  : access C_Language;
      Name  : String;
      Index : String) return String;

   function Record_Field_Name
     (Lang  : access C_Language;
      Name  : String;
      Field : String) return String;

   ---------------------
   -- Project support --
   ---------------------

   function Get_Project_Fields
     (Lang : access C_Language) return Project_Field_Array;

   ----------------------
   -- Source Analyzing --
   ----------------------

   procedure Parse_Constructs
     (Lang   : access C_Language;
      Buffer : String;
      Result : out Construct_List);

   procedure Parse_Entities
     (Lang     : access C_Language;
      Buffer   : String;
      Callback : Entity_Callback);

   procedure Format_Buffer
     (Lang            : access C_Language;
      Buffer          : String;
      Replace         : Replace_Text_Callback;
      From, To        : Natural := 0;
      Indent_Params   : Indent_Parameters := Default_Indent_Parameters;
      Indent_Offset   : Natural := 0;
      Case_Exceptions : Case_Handling.Casing_Exceptions :=
        Case_Handling.No_Casing_Exception);

private
   type C_Language is new Language_Root with null record;

   function Comment_Line
     (Lang    : access C_Language;
      Line    : String;
      Comment : Boolean := True;
      Clean   : Boolean := False) return String;

   C_Lang : constant Language_Access := new C_Language;
end Language.C;
