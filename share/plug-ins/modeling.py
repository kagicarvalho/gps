"""
This plug-in adds support for GMC (the GNAT Modeling Compiler) which generates
Ada (SPARK 2014?) and C code from Simulink models.

=========================================
THIS IS WORK IN PROGRESS
As it is this module does not perform anything useful. It defines
the Simulink language, which you can use in your project, but expects
.mdl files to be a JSON definition compatible with
GPS.Browsers.Diagram.load_json. The JSON is loaded into a browser when
you open a .mdl file, for instance from the Project view.
=========================================

"""

import json
import GPS
import GPS.Browsers
import glob
import gps_utils
import modules
import os
import os.path
import os_utils
import re

#############
# Constants #
#############

BLOCK_END = "End Block"
BLOCK_START = "Block"
# The prefixes of a block annotation

BLOCK_ANNOTATION = "(%(start)s|%(end)s) ((\w|_| )+(/(\w|_| )+)*)" % {
    "end": BLOCK_END,
    "start": BLOCK_START
}
# A regex pattern denoting a block annotation. Any changes to parenthesis must
# be reflected in BLOCK_ID and BLOCK_KIND.

BLOCK_ID = 2
BLOCK_KIND = 1
# The parenthesized groups which denote the block id and block kind in the
# BLOCK_ANNOTATION regex pattern.

COMPILE_MODEL_ACTION = "compile model"
# The name of the general action which triggers a GMC compilation

CONTEXTUAL_MENU = "Locate in model: <b>%s</b>"
# The name of the contextual menu produced when right clicking on a source code
# file. The name must contain %s which is replaced by the Simulink model.

DIAGRAM_ENABLED = "enabled"
DIAGRAM_SCALE = "scale"
DIAGRAM_SELECTED_ITEM = "selected_item"
DIAGRAM_TOPLEFT = "topleft"
# The names of various attributes used in saving/loading a GMC plug-in module

GMC_NAME = "gmc"
# The name of the GMC executable

GMC_EXEC = os_utils.locate_exec_on_path(GMC_NAME)
# The path to the GMC executable

GMC_HEADER = "Copyright \(C\) Project P"
# ??? "consortium" has different spelling in Ada and C headers ???
# A regex pattern denoting the predefined header which appears in every source
# code file generated by a GMC compilation. Note that special characters must
# be escaped.

JSON_FILE_EXTENSION = ".js"
# A regex pattern denoting the file extension of a JSON file

MDL_FILE_EXTENSION = ".mdl"
# A regex pattern denoting the file extension of a Simulink model file

MDL2JSON_NAME = "mdl2json"
# The name of the MDL2json executable

MDL2JSON_EXEC = os_utils.locate_exec_on_path(MDL2JSON_NAME)
# The path to the MDL2JSON executable

OPTION_CLEAN = "-c"
OPTION_FLATTEN = "--full-flattening"
OPTION_INCREMENTAL = "-i"
OPTION_LANGUAGE = "-l"
OPTION_LIBRARY = "-b"
OPTION_MATLAB = "-m"
OPTION_OUTPUT = "-o"
OPTION_TYPING = "-t"
# The names of various GMC and MDL2JSON options

OUTPUT_DIRECTORY = "Output_Dir"
# The name of the project attribute which denotes the output directory where a
# GMC compilation produces source code files.

SOURCE_MODEL = "Source_Model"
# The name of the project attribute which denotes the Simulink model

TARGET = "GMC for project"
# The name of the build target which describes a GMC compilation

###############
# Definitions #
###############

# Matlab and Simulink languages

LANGUAGE_DEFS = r"""<?xml version='1.0' ?>
  <GPS>
    <Language>
      <Name>Matlab</Name>
      <Body_Suffix>.m</Body_Suffix>
      <Obj_Suffix>-</Obj_Suffix>
    </Language>
    <Language>
      <Name>Simulink</Name>
      <Body_Suffix>.mdl</Body_Suffix>
      <Obj_Suffix>-</Obj_Suffix>
    </Language>
  </GPS>
"""

# The language definitions are parsed immediately to ensure that they are
# available at startup.

GPS.parse_xml(LANGUAGE_DEFS)

# Various project-related attributes

PROJECT_DEFS = """<?xml version='1.0' ?>
  <GPS>
    <project_attribute
     package="GMC"
     name="%(source_model)s"
     editor_page="GMC"
     label="Source model"
     description="The Simulink model to compile and view"
     hide_in="wizard library_wizard">
       <string type="file"/>
    </project_attribute>

    <project_attribute
     package="GMC"
     name="%(output_directory)s"
     editor_page="GMC"
     label="Output directory"
     description="The location of all generated source code files"
     hide_in="wizard library_wizard">
       <string type="directory"/>
    </project_attribute>

    <target-model name="GMC" category="">
      <description>Generic launch of GMC</description>
      <command-line>
        <arg>gmc</arg>
      </command-line>
      <switches/>
      <icon>gps-build-all</icon>
    </target-model>

    <target model="GMC" category="_Project_" name="%(target)s">
      <in-toolbar>FALSE</in-toolbar>
      <in-menu>FALSE</in-menu>
      <launch-mode>MANUALLY_WITH_NO_DIALOG</launch-mode>
      <read-only>TRUE</read-only>
      <command-line>
        <arg>gmc</arg>
      </command-line>
    </target>

    <tool
     name="GMC"
     package="GMC"
     index="Simulink">
      <language>Simulink</language>
      <switches lines="3">
        <title line="1">Files</title>
        <title line="2">Generation</title>
        <title line="3">Output</title>

        <field
         line="1"
         label="Matlab file"
         switch="%(option_matlab)s"
         separator=" "
         as-file="true"
         tip="Provides variable declarations of the Matlab workspace"/>
        <field
         line="1"
         label="Typing file"
         switch="%(option_typing)s"
         separator=" "
         as-file="true"
         tip="Provides Simulink block typing information"/>
        <field
         line="1"
         label="Library directory"
         switch="%(option_library)s"
         separator=" "
         as-directory="true"
         tip="Ask Matteo"/>

        <combo
         line="2"
         label="Target language"
         switch="%(option_language)s"
         separator=" "
         tip="The language used by GMC to produce the generated files">
           <combo-entry label="Ada" value="ada"/>
           <combo-entry label="C" value="c"/>
        </combo>
        <check
         line="2"
         label="Flatten model"
         switch="%(option_flatten)s"
         tip="Ask Matteo"/>

        <radio line="3">
          <radio-entry
           label="Delete"
           switch="%(option_clean)s"
           tip="Delete contents of output directory between compilations"/>
          <radio-entry
           label="Preserve"
           switch="%(option_incremental)s"
           tip="Preserve contents of output directory between compilations"/>
        </radio>
      </switches>
    </tool>
  </GPS>
""" % {
    "option_clean": OPTION_CLEAN,
    "option_flatten": OPTION_FLATTEN,
    "option_incremental": OPTION_INCREMENTAL,
    "option_language": OPTION_LANGUAGE,
    "option_library": OPTION_LIBRARY,
    "option_matlab": OPTION_MATLAB,
    "option_typing": OPTION_TYPING,
    "output_directory": OUTPUT_DIRECTORY,
    "source_model": SOURCE_MODEL,
    "target": TARGET
}

# The project attributes are parsed only when the GMC executable is available

if GMC_EXEC:
    GPS.parse_xml(PROJECT_DEFS)


class GMC_Diagram(GPS.Browsers.Diagram):

    def on_selection_changed(self, item, *args):
        """
        React to a change in selection of an item. This routine is not used,
        but must be present for overriding purposes.
        """
        pass


class GMC_Diagram_Viewer(GPS.Browsers.View):

    # _gmc_module
    #    type: GMC_Module
    # The GMC module in charge of the diagram viewer

    def __init__(self, gmc_module):
        """
        Create a new instance of GMC_Diagram_Viewer.
        :param GMC_Module gmc_module: An instance of GMC_Module.
        """
        self._gmc_module = gmc_module

    def on_create_context(self, context, topitem, item, x, y, *args):
        """
        React to a right click on an item. The routine is not used, but must be
        present for overriding purposes.
        """
        pass

    def on_item_clicked(self, topitem, item, x, y, *args):
        """
        React to a single click event on an item. The routine is not used, but
        must be present for overriding purposes.
        """
        pass

    def on_item_double_clicked(self, topitem, item, x, y, *args):
        """
        React to a double click event on an item.
        :param GPS.Browsers.Item topitem: The root of the subtree where item
            appears.
        :param GPS.Browsers.Item item: The item being double clicked.
        :param Float x: The x coordinate of the click.
        :param Float y: The y coordinate of the click.
        """
        self._gmc_module.handle_diagram_viewer_event(
            topitem, item, x, y, *args)

    def on_key(self, topitem, item, key, *args):
        """
        React to a key press while the diagram viewer is in focus. This routine
        is not used, but must be present for overriding purposes.
        """
        pass


class GMC_Module(modules.Module):

    # _block_id
    #    type: String
    # A block id whose corresponding graphical item must be highlighted when
    # a MDL2JSON compilation event occurs.

    # _locations
    #    type: list
    #    element: GPS.Message
    # A list of locations displayed in the Locations viewer.

    def __block_data(self, line):
        """
        Extract the block annotation data (if any) from a line.
        :param String line: A line to parse.
        :return: A tuple of the form (String, Boolean). The first element is
            the block id. The second element is a flag which is set to True
            when the annotation starts a block, False when it ends a block. If
            the line does not contain any block annotation data, the routine
            returns None.
        """
        result = re.search(pattern=BLOCK_ANNOTATION, string=line)

        if result:
            return (
                result.group(BLOCK_ID),
                result.group(BLOCK_KIND) == BLOCK_START)

        return None

    def __build_compilation_command(self, executable, file, switches):
        """
        Build a GMC/MDL2JSON compilation command.
        :param String executable: The executable to run.
        :param String file: A Simulink model or a JSON file.
        :param String switches: A sequence of switches.
        :return: The String representation of the command.
        """
        cmd = executable + " " + file + " " + OPTION_OUTPUT + " "\
            + self.__output_directory() + " " + switches

        # Ensure that the command has no leading spaces in the case where the
        # executable is missing.

        return cmd.strip()

    def build_contextual_menu(self, context):
        """
        Create a submenu for the "Locate in model" contextual menu. Each choice
        of the submenu represents an open annotation block.
        :param GPS.FileContext context: The context of the source code file
            subject to the right click.
        """
        click_line_num = context.location().line()
        cod_file = context.file().name()

        editor = GPS.EditorBuffer.get(GPS.File(cod_file))
        start = editor.at(click_line_num, 1)

        # Obtain the current line referenced by the cursor and determine
        # whether it denotes a block annotation. If it does, block_data[0]
        # contains the block id, block_data[1] is True when the annotation
        # starts a block.

        block_data = self.__block_data(
            editor.get_chars(start, start.end_of_line()))

        # The line where the right click occurred denotes a block id. Create a
        # one element contextual menu with the block id as the only choice.

        if block_data and block_data[0]:

            # "/" has a special meaning in GPS menus as it signals a new
            # submenu. To remedy this, convert every "/" into ".". This
            # substitution must be undone in handle_contextual_menu_event.

            block_id = block_data[0].replace("/", ".")
            return [block_id]

        # Otherwise the line denotes code, comment or white spaces. Either way,
        # parse the file and extract all open annotation blocks upto the said
        # line. This "scoping" approach yields the blocks where a piece of code
        # is "visible":

        #     block 1
        #     block 2
        #     source code statement 1  -  associated with block 1 and 2
        #     end block 2
        #     source code statement 2  -  associated with block 1
        #     end block 1

        else:
            block_ids = []

            # Open the source code file and examine each line

            phys_file = open(cod_file)
            line_num = 0

            for line in phys_file:
                line_num = line_num + 1

                # Stop the parse once the current line reaches the line where
                # the right click occurred.

                if line_num == click_line_num:
                    break

                # Check whether the current line denotes a block annotation.
                # If it does, block_data[0] contains the block id, block_data
                # [1] is True when the annotation starts a block.

                block_data = self.__block_data(line)

                if block_data and block_data[0]:

                    # "/" has a special meaning in GPS menus as it signals a
                    # new submenu. To remedy this, convert every "/" into ".".
                    # This act must be undone in handle_contextual_menu_event.

                    block_id = block_data[0].replace("/", ".")

                    # The line denotes a start annotation. Add the block id to
                    # the list of open block scopes.

                    if block_data[1]:
                        if not block_id in block_ids:
                            block_ids.append(block_id)

                    # Otherwise the line denotes an end annotation which closes
                    # a open block scope.

                    else:
                        if block_id in block_ids:
                            block_ids.remove(block_id)

            return block_ids

    def __compile_model_to_json(self):
        """
        Compile a Simulink model with MDL2JSON to generate a JSON file.
        """
        # Compile the Simulink model only when vital project attributes are
        # set and there is no diagram being shown in GPS. Guard against extra
        # compilations if there is already a MDL2JSON compilation currently
        # taking place.

        if (
            self.__project_file_ok()
            and not self.__is_running(MDL2JSON_EXEC)
        ):
            switches = self.__switches()

            # Remove unwanted switches

            switches = re.sub(pattern=OPTION_FLATTEN, repl="", string=switches)

            # Construct the argument list and call MDL2JSON to compile the
            # Simulink model. Note that the compilation is executed without
            # a build target because the JSON machinery must remain hidden.

            GPS.Process(
                command=self.__build_compilation_command(
                    executable=MDL2JSON_EXEC,
                    file=self.__model_file(),
                    switches=switches),
                on_exit=self.handle_MDL2JSON_compilation_event)

    def compile_model_to_source_code(self):
        """
        Compile a Simulink model with GMC to generate source code files in a
        particular target language.
        """
        # Compile the Simulink model only when vital project attributes are
        # set. Guard against extra compilations if there is already a GMC
        # compilation currently taking place.

        if self.__project_file_ok() and not self.__is_running(TARGET):
            switches = self.__switches()

            # Handle a missing compilation behavior switch (-c/-i) by adding a
            # default.

            if not re.search(
                pattern=OPTION_CLEAN + "|" + OPTION_INCREMENTAL,
                string=switches
            ):
                switches = switches + " " + OPTION_INCREMENTAL

            # Handle a missing target language switch (-l) by adding a default

            if not re.search(pattern=OPTION_LANGUAGE, string=switches):
                switches = switches + " " + OPTION_LANGUAGE + " ada"

            # Construct the argument list and call GMC to compile the Simulink
            # model.

            targ = GPS.BuildTarget(TARGET)
            targ.execute(
                synchronous=False,
                extra_args=self.__build_compilation_command(
                    executable="",
                    file=self.__model_file(),
                    switches=switches))

    def __diagram_viewer(self):
        """
        Obtain the diagram viewer in charge of visualizing a Simulink model.
        :return: An instance of GMC_Diagram_Viewer.
        """
        window = GPS.MDI.get(os.path.basename(self.__model_file()))

        if hasattr(window, "_diagram_viewer"):
            return window._diagram_viewer

        return None

    def __diagram_viewer_focus(self):
        """
        Bring the diagram viewer into focus.
        """
        GPS.MDI.get(os.path.basename(self.__model_file())).raise_window()

    def handle_contextual_menu_event(self, context, choice, choice_index):
        """
        Process a contextual menu event and perform the appropriate navigation
        action.
        """
        # Updo the replacement done in build_contextual_menu as item ids use
        # "/" to delimit their children, not ".".

        block_id = choice.replace(".", "/")

        # Highlight the chosen graphical item and bring the diagram viewer into
        # focus.

        if self.__diagram_viewer():
            self.__select_item(block_id)
            self.__diagram_viewer_focus()

        # Otherwise the Simulink model needs to be compiled to JSON. Note that
        # this action automatically highlights the chosen graphical item and
        # brings the diagram viewer into focus.

        else:
            self._block_id = block_id
            self.__compile_model_to_json()

    def handle_diagram_viewer_event(self, topitem, item, x, y, *args):
        """
        Process a diagram viewer event and perform the appropriate navigation
        action.
        :param GPS.Browsers.Item topitem: The root of the subtree where item
            appears.
        :param GPS.Browsers.Item item: The item being double clicked.
        :param Float x: The x coordinate of the click.
        :param Float y: The y coordinate of the click.
        """
        def add_locations(cod_file, item_id):
            """
            Examine the contents of a source code file and add a new location
            to the Locations viewer for eash starting block annotation which
            mentions item_id. Note that the file may lack such annotations.
            :param String cod_file: The path + name of a source code file.
            :param String item_id: The item id to search for.
            """
            phys_file = open(cod_file)
            line_num = 0

            for line in phys_file:
                line_num = line_num + 1

                # Check whether the current line denotes a block annotation. If
                # it does, block_data[0] contains the block id, block_data[1]
                # is True when the annotation starts a block.

                block_data = self.__block_data(line)

                # The current line denotes a starting block annotation. Check
                # whether the item id matches the block id. Note that the block
                # id may contain an extra level of detail, therefore perform
                # the membership test against the block id rather than the
                # other way around. To illustrate:

                #     A/B/C      block id
                #     A/B        item id

                if (
                    block_data
                    and block_data[0]
                    and block_data[1]
                    and item_id in block_data[0]
                ):
                    self._locations.append(GPS.Message(
                        category="default",
                        file=GPS.File(cod_file),
                        line=line_num,
                        column=1,
                        text=block_data[0],
                        flags=0))

        # Start of processing for handle_diagram_viewer_event

        if hasattr(item, "id") and item.id:

            # Clear all locations displayed in the Locations viewer as the
            # current item will generate new ones.

            for location in self._locations:
                location.remove()

            self._locations = []

            # Open all files in the output directory and try to detect source
            # code files by matching their contents against a predefined GMC
            # header.

            all_files = os.path.join(self.__output_directory(), "*")
            for cod_file in glob.glob(all_files):
                if self.__is_source_code_file(cod_file):
                    add_locations(cod_file=cod_file, item_id=item.id)

            return True

        return False

    def handle_editor_event(self, hookname, file, line, column):
        """
        Process an editor event and perform the appropriate navigation action.
        :param ??? hookname: ???
        :param GPS.File file: The file being edited.
        :param Integer line: The line number of the cursor.
        :param Integer column: The column number of the cursor.
        """
        if self.__is_source_code_file(file.name()) and self.__diagram_viewer():
            editor = GPS.EditorBuffer.get(file)
            start = editor.at(line, 1)

            # Obtain the current line referenced by the cursor and determine
            # whether it denotes a block annotation. If it does, block_data[0]
            # contains the block id, block_data[1] is True when the annotation
            # starts a block.

            block_data = self.__block_data(
                editor.get_chars(start, start.end_of_line()))

            # Select the graphical item which corresponds to the block id
            # being clicked on.

            if block_data and block_data[0]:
                self.__select_item(block_data[0])

    def handle_GMC_compilation_event(
        self,
        hookname,
        category,
        target_name="",
        mode_name="",
        status=""
    ):
        """
        Process a compilation event and perform the appropriate action.
        :param ??? hookname: ???
        :param String category: The location/highlighting category that
            contains the compilation output.
        :param String target_name: The name of the executed build target.
        :param String mode_name: The name of the executed build mode.
        :param Integer status: The exit status of the executed program.
        """
        # GMC has finished compiling a Simulink model. Reload the project
        # explorer as the compilation generates new files which must be
        # displayed accordingly.

        if target_name == TARGET:
            GPS.execute_action("reload project")

    def handle_MDL2JSON_compilation_event(self, process, status, output):
        """
        Process a MDL2JSON compilation event and perform the appropriate action
        :param GPS.Process process: An instance of GPS.Process.
        :param Integer status: The exit status of the call to MDL2JSON.
        :param String output: the output of the call to MDL2JSON.
        """
        if status != 0:
            GPS.Console("Messages").write(
                "%s\n" % output)
            GPS.Console("Messages").write(
                "mdl2json returned error %s" % status, mode="error")
            return

        diags = GPS.Browsers.Diagram.load_json(
            self.__json_file(), diagramFactory=GMC_Diagram)

        # The compilation of the Simulink model to JSON was triggered by
        # routine load_desktop. Reuse the already available diagram viewer
        # and set the proper diagram.

        diag_view = self.__diagram_viewer()

        if diag_view:
            diag_view.diagram = diags[0]

        # Otherwise the compilation was triggered by double clicking on the
        # Simulink model. Create a diagram viewer and display the diagram.

        else:
            model_file = os.path.basename(self.__model_file())

            diag_view = GMC_Diagram_Viewer(self)
            diag_view.create(
                diagram=diags[0],
                title=model_file,
                save_desktop=self._save_desktop)

            # Store the instance of the diagram viewer in the window in
            # charge of displaying it.

            window = GPS.MDI.get(model_file)
            window._diagram_viewer = diag_view

        # Highlight the corresponding graphical item of a block selected
        # during an interaction with contextual menu "Locate in model".

        if self._block_id:
            self.__select_item(self._block_id)
            self._block_id = None

        # JSON files must never be exposed to the outside. Destroy the file
        # once the diagram has been displayed.

        os.remove(self.__json_file())

    def __is_running(self, process):
        """
        Determine whether a process is currently running in GPS.
        :param String process: The name of the process.
        :return: The Boolean status of the test.
        """
        for task in GPS.Task.list():
            if task.name() == process:
                return True

        return False

    def __is_source_code_file(self, file):
        """
        Determine whether a file is the byproduct of a GMC compilation.
        :param String file: The path + name of the file to test.
        :return: The Boolean status of the test.
        """
        if os.path.isfile(file):
            phys_file = open(file)

            # A file is the byproduct of a GMC compilation when the first line
            # of its textual content denotes a GMC header.

            status = re.search(pattern=GMC_HEADER, string=phys_file.readline())
            phys_file.close()

            return status is not None

        # Otherwise parameter file denotes a directory

        else:
            return False

    def is_source_code_file_context(self, context):
        """
        Determine whether the context of a right click is a file which is the
        byproduct of a GMC compilation.
        :param GPS.Context context: The context being right clicked on.
        :return: The Boolean status of the test.
        """
        # The following is in a try-except block because calling file() on
        # certain file contexts raises an exception.

        try:
            return (
                isinstance(context, GPS.FileContext)
                and self.__is_source_code_file(context.file().name()))
        except:
            return False

    def __json_file(self):
        """
        Obtain the JSON file produced by a MDL2JSON compilation.
        :return: The path + file name of the file as String.
        """
        # The JSON file resides in the output directory and shares the same
        # name as that of the related Simulink model, except for the file
        # extension.

        return os.path.abspath(os.path.join(
            self.__output_directory(),
            re.sub(
                pattern=MDL_FILE_EXTENSION + "$",
                repl=JSON_FILE_EXTENSION,
                string=os.path.basename(self.__model_file()))))

    def load_desktop(self, view, data):
        """
        Load the contents of a GMC plug-in module.
        """
        try:
            info = json.loads(data)
            if not isinstance(info, dict):
                return None
        except:
            return None

        # The diagram viewer was enabled in the previous session of GPS

        if info[DIAGRAM_ENABLED]:
            model_file = os.path.basename(self.__model_file())

            # Routine load_desktop launches an asynchronous compilation process
            # and at the same time it must return one of the byproducts of the
            # said compilation. To resolve this race condition, construct an
            # empty diagram viewer now and store it in the corresponding MDI
            # window. Routine handle_MDL2JSON_compilation_event will then reuse
            # the diagram viewer and finish loading the diagram.

            diag_view = GMC_Diagram_Viewer(self)

            # Note that the diagram viewer loads an empty diagram. The actual
            # diagram is set in handle_MDL2JSON_compilation_event.

            diag_view.create(
                diagram=GPS.Browsers.Diagram(),
                title=model_file,
                save_desktop=self._save_desktop
            )

            # Set the properties used in the previous session of GPS

            diag_view.scale = info[DIAGRAM_SCALE]
            self._block_id = info[DIAGRAM_SELECTED_ITEM]
            diag_view.topleft = info[DIAGRAM_TOPLEFT]

            # Store the instance of the diagram viewer in the window in charge
            # of displaying it.

            window = GPS.MDI.get(model_file)
            window._diagram_viewer = diag_view

            # Recompile the Simulink model to JSON and display the diagram

            self.__compile_model_to_json()

            return GPS.MDI.get_by_child(diag_view)

        return None

    def __model_file(self):
        """
        Obtain the Simulink model used in a GMC/MDL2JSON compilation as
        specified in a GMC project.
        :return: The value of project attribute Source_Model as String. This
            is usually the path + name of the Simulink model.
        """
        return GPS.Project.root().get_attribute_as_string(
            package="GMC", attribute=SOURCE_MODEL)

    def __output_directory(self):
        """
        Obtain the output directory of a GMC/MDL2JSON compilation as specified
        in a GMC project.
        :return: The value of project attribute Output_Dir as String.
        """
        return GPS.Project.root().get_attribute_as_string(
            package="GMC", attribute=OUTPUT_DIRECTORY)

    def __present(self, file):
        """
        Determine whether a file is physically present on disk. If this is not
        the case, issue an error.
        :param GPS.File file: The file to be tested.
        :return: The Boolean status of the test.
        """
        file_name = file.name()

        if os.path.exists(file_name):
            return True

        # The file does not exist, issue an error

        else:
            GPS.Console("Messages").write(
                "file %s is missing" % file_name, mode="error")
            return False

    def __project_file_ok(self, report=True):
        """
        Determine whether key project attributes are present and if not, issue
        an error.
        :param Boolean report: Set to True to issue an error.
        :return: The Boolean status of the test.
        """
        status = True

        if not self.__model_file():
            if report:
                GPS.Console("Messages").write(
                    "missing project attribute Source_Model in package GMC",
                    mode="error")
            status = False

        if not self.__output_directory():
            if report:
                GPS.Console("Messages").write(
                    "missing project attribute Output_Dir in package GMC",
                    mode="error")
            status = False

        return status

    def _save_desktop(self, child):
        """
        Save the contents of a GMC plug-in module.
        """
        diag_view = child.get_child()
        info = {
            DIAGRAM_ENABLED: True,
            DIAGRAM_SCALE: diag_view.scale,
            DIAGRAM_SELECTED_ITEM: self._block_id,
            DIAGRAM_TOPLEFT: diag_view.topleft}

        return (self.name(), json.dumps(info))

    def __select_item(self, block_id):
        """
        Given a block id, find the corresponding graphical item and select it.
        :param String block_id: The id of a block annotation.
        """
        def find_matching_graphical_item(item):
            """
            Inspect the input graphical item and its children (if any) to try
            and match their ids against the block id.
            :param GPS.Browsers.Item item): The (parent) item.
            :return GPS.Browsers.Item: The graphical item whose id matches
                block_id or None.
            """
            # Check whether the current item id matches the block id. Note that
            # the block id may contain an extra level of detail, therefore
            # perform the membership test against the block id rather than
            # the other way around. To illustrate:

            #     A/B/C      block id
            #     A/B        item id

            # Note that the item may not even have the "id" attribute set or it
            # may be None.

            if hasattr(item, "id"):
                item_id = item.id

                if item_id and item_id in block_id:
                    return item

            # Inspect any available children. Note that the item may not even
            # have the "children" attribute set or it may be None.

            if hasattr(item, "children"):
                graph_items = item.children

                if graph_items:
                    for graph_item in graph_items:
                        result = find_matching_graphical_item(graph_item)

                        if result:
                            return result

            return None

        # Start of processing for __select_item

        graph_item = None

        # Inspect all the top level items of the diagram. Note that each top
        # level item may have children, grand children and so on. The search
        # favors roots over children.

        for top_item in self.__diagram_viewer().diagram.items:
            graph_item = find_matching_graphical_item(top_item)

            if graph_item:
                break

        # Once a matching graphical item has been found, remove the previous
        # selection and highlight the new item.

        if graph_item:
            diag = self.__diagram_viewer().diagram

            diag.clear_selection()
            diag.select(graph_item)

    def setup(self):
        """
        Setup the GMC plug-in.
        """
        # The module is loaded only when GMC is available

        if GMC_EXEC:
            self._block_id = None
            self._locations = []

            self.__setup_hooks()
            self.__setup_menus()

    def __setup_hooks(self):
        """
        Enable the GMC plug-in functionality by registering various actions
        with corresponding GPS event hooks.
        """
        GPS.Hook("compilation_finished").add(
            self.handle_GMC_compilation_event, last=False)
        GPS.Hook("location_changed").add(
            self.handle_editor_event, last=False)
        GPS.Hook("open_file_action_hook").add(
            self.visualize_model, last=False)

    def __setup_menus(self):
        """
        Enable the GMC plug-in menus and buttons.
        """
        # Register the contextual menu which is displayed on a right click in
        # an editor.

        GPS.Contextual(
            CONTEXTUAL_MENU % os.path.basename(self.__model_file())
        ).create_dynamic(
            on_activate=self.handle_contextual_menu_event,
            factory=self.build_contextual_menu,
            filter=self.is_source_code_file_context)

        # Register the general action which triggers the compilation of a
        # Simulink model to source code.

        gps_utils.make_interactive(
            callback=self.compile_model_to_source_code,
            name=COMPILE_MODEL_ACTION)

    def __switches(self):
        """
        Obtain the switches used in a GMC/MDL2JSON compilation as specified in
        a GMC project.
        :return: The switches of a GMC project as String.
        """
        return GPS.Project.root().get_tool_switches_as_string("GMC")

    def teardown(self):
        """
        Clean up a GMC plug-in.
        """
        del self._block_id

        for location in self._locations:
            location.remove()

        del self._locations

    def visualize_model(
        self,
        hookname,
        model_file,
        line,
        column,
        column_end,
        enable_navigation,
        new_file,
        force_reload,
        focus,
        project
    ):
        """
        Create the visual representation of a Simulink model.
        :param GPS.File model_file: The model file to visualize.
        :param Integer line:
        :param Integer column_end:
        :param Boolean enabled_navigation:
        :param Boolean new_file:
        :param Boolean force_reload:
        :param Boolean focus:
        :param GPS.Project project:
        :return: The Boolean status of the operation.
        """
        # Compile a Simulink model into JSON only when the MDL2JSON tool is
        # available.

        if (
            MDL2JSON_EXEC
            and self.__present(model_file)
            and model_file.language() == "simulink"
        ):
            # Do not recompile the Simulink model if the diagram is already
            # displayed. Instead bring the digram viewer into focus.

            if self.__diagram_viewer():
                self.__diagram_viewer_focus()
            else:
                self.__compile_model_to_json()

            return True

        else:
            return False
