""" Provides the "Tools/Run program under Xcov" menu, which executes xcov
automatically.
"""


###########################################################################
## No user customization below this line
###########################################################################

import GPS, os.path, os_utils;

#  Check for Xcov

if os_utils.locate_exec_on_path ("xcov") != "":
    GPS.parse_xml ("""
  <!--  Program execution under instrumented execution environment  -->

  <target-model name="xcov-run" category="">
    <description>Code coverage with Xcov</description>
    <command-line>
      <arg>xcov</arg>
      <arg>--run</arg>
    </command-line>
    <icon>gps-build-all</icon>
    <switches command="%(tool_name)s" columns="2" lines="2">
      <combo label="Target" switch="--target" separator="=" column="1">
        <combo-entry label="powerpc-elf" value="powerpc-elf"/>
        <combo-entry label="leon-elf" value="leon-elf"/>
        <combo-entry label="i386-pok" value="i386-pok"/>
        <combo-entry label="i386-linux" value="i386-linux"/>
        <combo-entry label="prepare" value="prepare"/>
      </combo>
      <field label="Tag" switch="--tag" separator="=" column="2"/>
      <field label="Trace file" switch="-o" separator=" " as-file="true" column="1"/>
      <check label="Verbose" switch="--verbose" column="2"/>
    </switches>
  </target-model>

  <target model="xcov-run" category="Xcov Run" name="Run under Xcov"
          menu="/Tools/Cov_erage/">
    <target-type>executable</target-type>
    <in-toolbar>FALSE</in-toolbar>
    <in-menu>TRUE</in-menu>
    <read-only>TRUE</read-only>
    <icon>gps-build-all</icon>
    <launch-mode>MANUALLY</launch-mode>
    <command-line>
      <arg>xcov</arg>
      <arg>--run</arg>
      <arg>--target=powerpc-elf</arg>
      <arg>%TT</arg>
      <arg>-o</arg>
      <arg>%TT.trace</arg>
    </command-line>
  </target>

  <!--  Coverage report generation  -->

  <target-model name="xcov-coverage" category="">
    <description>Code coverage with Xcov</description>
    <command-line>
      <arg>xcov</arg>
      <arg>--coverage=insn</arg>
      <arg>--annotate=xcov</arg>
    </command-line>
    <icon>gps-build-all</icon>
    <switches command="%(tool_name)s" columns="3" lines="5">
      <combo label="Coverage" switch="--coverage" separator="=" column="1">
        <combo-entry label="Instruction" value="insn"
                     title="Object Instruction Coverage"/>
        <combo-entry label="Branch" value="branch"
                     title="Object Branch Coverage"/>
        <combo-entry label="Statement" value="stmt"
                     title="Source Statement Coverage"/>
        <combo-entry label="Decision" value="decision"
                     title="Source Decision Coverage"/>
        <combo-entry label="MCDC" value="mcdc"
                     title="Source MCDC Coverage"/>
      </combo>
      <combo label="Annotate" switch="--annotate" separator="=" column="1">
        <combo-entry label="Xcov" value="xcov"/>
        <combo-entry label="Xcov + Assembler" value="xcov+asm"/>
      </combo>
      <field label="Routine list" switch="--routine-list" separator="="
             as-file="true"/>
    </switches>
  </target-model>

  <target model="xcov-coverage" category="Xcov Report"
          name="Generate Xcov report" menu="/Tools/Cov_erage/">
    <target-type>executable</target-type>
    <in-toolbar>FALSE</in-toolbar>
    <in-menu>TRUE</in-menu>
    <read-only>TRUE</read-only>
    <icon>gps-build-all</icon>
    <launch-mode>MANUALLY</launch-mode>
    <command-line>
      <arg>xcov</arg>
      <arg>--coverage=insn</arg>
      <arg>--annotate=xcov</arg>
      <arg>%TT.trace</arg>
    </command-line>
  </target>
""")
