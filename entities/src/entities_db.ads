
with GNATCOLL.Projects;     use GNATCOLL.Projects;
with GNATCOLL.SQL.Sessions; use GNATCOLL.SQL.Sessions;

package Entities_Db is

   procedure Parse_All_LI_Files
     (Session : Session_Type;
      Tree    : Project_Tree;
      Project : Project_Type;
      Database_Is_Empty : Boolean := False);
   --  Parse all the LI files for the project, and stores them in the
   --  database.
   --  If the caller knows that the database is empty, it should pass True for
   --  Database_Is_Empty. In this case, this package will avoid a number of
   --  calls to SELECT and significantly speed up the initial insertion.

end Entities_Db;
