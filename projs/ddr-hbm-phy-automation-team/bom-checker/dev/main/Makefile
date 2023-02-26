SHELL=tcsh

# The version of PERL required
PERL_EXE=/depot/perl-5.14.2/bin/perl

# The location of the Devel::Cover package
DEVEL_PATH=/u/ljames/perl_directory/lib/site_perl/5.14.2/x86_64-linux

# How to run coverage
COVERIT=/depot/perl-5.14.2/bin/perl -MDevel::Cover
PROVE=/depot/perl-5.14.2/bin/prove

# Find all the .t files and put them into the TESTS variable
TESTS := $(wildcard ./t/*.t)
SH_TESTS := $(wildcard ./t/run-tests_*.sh)

.PHONY: clean coverage cover_delete

test: t_tests sh_tests

t_tests:
	@$(PROVE) t

sh_tests:
	$(foreach tst,$(SH_TESTS), $(tst);)

test_details:
	$(foreach tst,$(TESTS),$(PERL_EXE) $(tst);)

coverage: clean 
	$(foreach tst,$(TESTS),$(COVERIT) $(tst);)
	cover
	
clean:
	cover -delete

