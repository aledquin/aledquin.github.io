SHELL=/depot/local/bin/tcsh -f

#$(warning $(GITROOT) $(origin GITROOT))

ifndef GITROOT
GITROOT=/u/$(USER)/GitLab/ddr-hbm-phy-automation-team
endif

# The top directory for the git repository
#ifeq ( $(origin GITROOT),"undefined" ) 
#	GITROOT=/u/$(USER)/GitLab/ddr-hbm-phy-automation-team
#endif
# The tool you want to build
TOOL=sharedlib

# The version of PERL required
PERL_EXE=/depot/perl-5.14.2/bin/perl
# The version of Python required
PYTHON38_EXE=/depot/Python/Python-3.8.0/bin/python
# The TCL version
TCL_EXE=/depot/tcl8.6.3/bin/tclsh8.6

CHECK=./../admin/check_code.csh -short -nosymlink

# How to run coverage
COVERIT=/depot/perl-5.14.2/bin/perl -MDevel::Cover=-db,$(GITROOT)/$(TOOL)_cover_db
PROVE=/depot/perl-5.14.2/bin/prove
COVERAPP=/depot/perl-5.14.2/bin/cover
RUN_TESTS_PY=./../../../run_tests.py

LINT_PL=./../admin/perl_lint.pl -short
LINT_PY=./../admin/python_lint.pl -short
LINT_TCL=./../admin/tcl_lint.pl -short

LIST_TCL=./../admin/list_tcl
LIST_PERL=./../admin/list_perl
LIST_PYTHON=./../admin/list_python

# Find all the .t files and put them into the PLTESTS variable
PLTESTS := $(wildcard $(GITROOT)/$(TOOL)/perl/tests/unit_tests/*.t)

# Find all the test_.py files and put them into the TESTS variable
PYTESTS := $(wildcard $(GITROOT)/$(TOOL)/python/tests/unit_tests/test_*)

TCLTESTS := $(wildcard $(GITROOT)/$(TOOL)/tcl/tests/unit_tests/*.test)

SCRIPTS_PL := $(shell $(LIST_PERL))
SCRIPTS_PY := $(shell $(LIST_PYTHON))
SCRIPTS_TCL := $(shell $(LIST_TCL))

# Targets for admin/check_code.csh
CHECK_PL  := $(SCRIPTS_PL)
CHECK_PY  := $(SCRIPTS_PY)
CHECK_TCL := $(SCRIPTS_TCL)

.PHONY: help clean coverage clean_coverage test unit_tests_py unit_tests_pl unit_tests_tcl unit_tests_pl_details lint unit_tests lint_pl lint_py lint_tcl

.FORCE:

test: lint unit_tests

compile_check: check_compile_pl check_compile_py

check_compile_pl:
	@echo "================================================================================\nRunning 'perl -c' on all perl scripts\n================================================================================\n"
	@$(foreach file,$(SCRIPTS_PL),$(PERL_EXE) -c $(file);)

check_compile_py:
	@echo "================================================================================\nRunning 'python -m' on all python scripts\n================================================================================\n"
	@$(foreach file,$(SCRIPTS_PY),echo $(PYTHON38_EXE) -m py_compile $(file); $(PYTHON38_EXE) -m py_compile $(file);)
#	@$(foreach file,$(SCRIPTS_PY),$(PYTHON38_EXE) -m py_compile $(file);)

check_all: check_pl check_py check_tcl

# CHECK app will run linting on perl scripts and python scripts
check_pl: $(CHECK_PL)
	@echo "\n================================================================================\n<b>Perl admin/check_code.csh PASSED\n================================================================================\n"

$(CHECK_PL): .FORCE
	@$(CHECK) -printerrors $@

check_py: $(CHECK_PY)
	@echo "\n================================================================================\n<b>Python admin/check_code.csh PASSED\n================================================================================\n"

$(CHECK_PY): .FORCE
	@$(CHECK) -printerrors $@

check_tcl: $(CHECK_TCL)
	@echo "\n================================================================================\n<b>TCL admin/check_code.csh PASSED\n================================================================================\n"

$(CHECK_TCL): .FORCE
	@$(CHECK) -printerrors $@

lint: lint_pl lint_py lint_tcl

lint_pl:
	@echo "\n================================================================================\n<b>Perl Linter on Perl modules and scripts</b>\n================================================================================\n"	
	@$(foreach file,$(SCRIPTS_PL),$(LINT_PL) $(file);)

lint_py:
	@echo "\n================================================================================\n<b>Python Linter </b>\n================================================================================\n"	
	@$(foreach file,$(SCRIPTS_PY),$(LINT_PY) $(file);)


lint_tcl:
	@echo "\n================================================================================\n<b>TCL Linter </b>\n================================================================================\n"	
	@$(foreach file,$(SCRIPTS_TCL),$(LINT_TCL) $(file);)


unit_tests: unit_tests_py unit_tests_pl unit_tests_tcl

unit_tests_py:
	@echo "\n================================================================================\n<b>Python Unit Tests</b>\n================================================================================\n"	
	$(foreach tst,$(PYTESTS),$(tst);)

unit_tests_pl:
	@echo "\n================================================================================\n<b>Perl Unit Tests</b>\n================================================================================\n"	
	@$(PROVE) $(GITROOT)/$(TOOL)/perl/tests/unit_tests/

unit_tests_tcl:
	@echo "\n================================================================================\n<b>TCL Unit Tests</b>\n================================================================================\n"	
	$(foreach tst,$(TCLTESTS),$(TCL_EXE) $(tst);)

unit_tests_pl_details:
	$(foreach tst,$(PLTESTS),$(PERL_EXE) $(tst);)

func_tests_py:
	@echo "\n================================================================================\n<b>Python Functional Tests</b>\n================================================================================\n"	
	@$(RUN_TESTS_PY) --tool $(TOOL) --functional_tests

coverage:
	$(foreach tst,$(PLTESTS),cd $(GITROOT); $(COVERIT) $(tst);)

build_coverage_html:
	cd $(GITROOT); $(COVERAPP)

clean:
	@echo "Cleaning up files"

clean_coverage:
	cd $(GITROOT); $(COVERAPP) -delete

help:
	@echo "lint\ntest\nunit_tests\nunit_tests_py\nunit_tests_pl\nunit_tests_pl_details\ncoverage\nbuild_coverage_html\nclean\nclean_coverage\nhelp\n"

