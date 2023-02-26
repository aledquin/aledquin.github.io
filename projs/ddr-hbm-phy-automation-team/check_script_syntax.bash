#!/usr/bin/env bash
# Updates:
#   001 ljames  6/22/2022
#       Filter out bom-checker; we no longer support this.
#   002 ljames 6/24/2022
#       Disable the calls to the Kibana usage database by setting
#       env variable DDR_DA_SKIP_USAGE to anything. Just has to exist.
#


DDR_DA_SKIP_USAGE=1
export  DDR_DA_SKIP_USAGE

PERL='/depot/perl-5.14.2/bin/perl'
PYTHON='/global/freeware/Linux/2.X/python-3.6.1/bin/python'
PYTHON_ERR_FOUND=0
PERL_ERR_FOUND=0
PERL_COMPILE_ERR_FOUND=0
SKIP_FILE=MiscUtils.pm
SKIP_FILE2=./perl/test/bin/inspector.pl
SKIP_FILE3=TestMessaging.pm
SKIP_FILE4_WARN=./admin/perl_lint.pl
SKIP_FILE5_WARN=MyPackage/Graphics.pm
SKIP_FILE6_WARN=./ddr-ckt-rel/dev/main/bin/alphaHLDepotPhyvRelease
SKIP_FILE7_WARN=./ddr-ckt-rel/dev/main/bin/alphaHLDepotRelPinCheck
SKIP_FILE8_WARN=./ddr-ckt-rel/dev/main/bin/alphaHLDepotDefRelease
SKIP_FILE9_WARN=./ddr-ckt-rel/dev/main/bin/alphaCompileLibs
SKIP_FILE10_WARN=./ddr-ckt-rel/dev/main/bin/alphaVerifyTimingCollateral
SKIP_FILE11_WARN=./ddr-ckt-rel/dev/main/t/test_alphaHLDepotPhyvRelease
# This script is sanity check to ensure  all python+perl code
# will compile successfully. If not, then it needs to be
# examined.  
mcmd='modulecmd.x86_64.Linux.3.10'
module_cmd="/global/etc/modules/$MODULE_VERSION/bin/$mcmd tcsh"
$module_cmd unload ddr-ckt-rel

echo "-I- Checking PYTHON content compiles ..."
# Check the PYTHON content...
count=0
npass=0
nfail=0
while read -r file; do
   $PYTHON -m py_compile $file  >& /dev/null
   retval=$?
   count=$(($count + 1))
   if [ $retval -eq 0 ]; then
     status="PASSED"
     npass=$(( $npass + 1))
   else
     status="FAILED"
     PYTHON_ERR_FOUND=1
     nfail=$(( $nfail + 1))
   fi
   echo "$status: $PYTHON -m py_compile '$file'"
done < <(find . -name '*.py')

if [ $PYTHON_ERR_FOUND -gt 0 ] ; then
   echo "+------------------------------------------------+"
   echo "| Python Compile Check ($nfail)/($count) FAILED! "
   echo "+------------------------------------------------+"
else
   echo "+------------------------------------------------+"
   echo "| Python Compile Check ($count)/($count) PASSED! "
   echo "+------------------------------------------------+"
fi

echo "-I- Checking PERL -> content compiles ..."
count=0
npass=0
nfail=0
nskip=0
regex1="perl\/lib\/Set\/"
regex2="perl\/lib\/Email\/"
regex3="perl\/lib\/Text\/"
regex4="perl\/bin\/experiments\/"
regex5="perl\/test\/TestPM\/"
regex6="users\/"
regex7="ddr-ckt-rel/releases\/"
regex8="\.git\/"
regex9="bom-checker\/"
# Check the PERL content...by compiling code.
while read -r file; do
  count=$(($count + 1))
  if [[ $file =~ $regex1 ]] \
     || [[ $file =~ $regex2 ]] \
     || [[ $file =~ $regex3 ]] \
     || [[ $file =~ $regex4 ]] \
     || [[ $file =~ $regex5 ]] \
     || [[ $file =~ $regex6 ]] \
     || [[ $file =~ $regex7 ]] \
     || [[ $file =~ $regex8 ]] \
     || [[ $file =~ $regex9 ]]; then
     #echo "WAIVED *** $PERL -c '$file'"
     skipping="TRUE"
     nskip=$(($nskip + 1))
  else
    if [[ ! $file = *$SKIP_FILE*  ]] \
      && [[ ! $file = *$SKIP_FILE2* ]] \
      && [[ ! $file = *$SKIP_FILE3* ]]; then
      curdir=$PWD
      filename=`basename "$file"`
      dir_name=`dirname "$file"`
      extension="${filename##*.}"
      file_type=`file $file`
      if [[ "$file_type" = *Perl5* ]] \
         || [[ "$file_type" = *Perl* ]] \
         || [[ "$extension" = "pm" ]] \
         || [[ "$extension" = "pl" ]]; then
        pushd $dir_name >& /dev/null
        #echo "debug: $PERL -c $filename"
        $PERL -c $filename >& /dev/null
        retval=$?
        popd >& /dev/null
        if [ $retval -eq 0 ]; then
          status="PASSED"
          npass=$(($npass + 1))
        else
          status="FAILED"
          PERL_COMPILE_ERR_FOUND=1
          nfail=$(($nfail + 1))
        fi
        echo "$status: $PERL -c '$file'"
      fi
    fi
  fi
done < <(find . -name '*')

if [ $PERL_COMPILE_ERR_FOUND -gt 0 ] ; then
   echo "+------------------------------------------------+"
   echo "| PERL Compile Check $nfail/$count FAILED!   "
   if [ $nskip > 0 ]; then 
       echo "| ($nskip) tests have been skipped               "
   fi 
   echo "+------------------------------------------------+"
else
   echo "+------------------------------------------------+"
   echo "| PERL Compile Check $npass/$count PASSED!   "
   if [ $nskip > 0]; then
       echo "| ($nskip) tests have been skipped               "
   fi
   echo "+------------------------------------------------+"
fi

echo "-I- Checking PERL -> content for warnnings ..."
regex6="users\/"
regex7="\.git\/"
regex8="ddr-ckt-rel\/releases"
regex9="\/t\/"
regex10="bom-checker\/"
# Check the PERL content...by running with '-w'
count=0
npass=0
nfail=0
nskip=0

while read -r file; do
  if [[ $file =~ $regex6 ]] \
     || [[ $file =~ $regex7 ]] \
     || [[ $file =~ $regex8 ]] \
     || [[ $file =~ $regex9 ]] \
     || [[ $file =~ $regex10 ]]; then
    fakenothing=0 
  else
    if [[ ! $file = *$SKIP_FILE*  ]] \
       && [[ ! $file = *$SKIP_FILE2* ]] \
       && [[ ! $file = *$SKIP_FILE3* ]] \
       && [[ ! $file = *$SKIP_FILE4_WARN* ]] \
       && [[ ! $file = *$SKIP_FILE5_WARN* ]] \
       && [[ ! $file = *$SKIP_FILE6_WARN* ]] \
       && [[ ! $file = *$SKIP_FILE7_WARN* ]] \
       && [[ ! $file = *$SKIP_FILE8_WARN* ]] \
       && [[ ! $file = *$SKIP_FILE9_WARN* ]] \
       && [[ ! $file = *$SKIP_FILE10_WARN* ]]; then
       #echo "debug: PERL -w $file"
       filename=`basename "$file"`
       dir_name=`dirname "$file"`
       extension="${filename##*.}"
       file_type=`file $file`
       if [[ "$file_type" = *Perl5* ]] \
          || [[ "$file_type" = *Perl* ]] \
          || [[ "$extension" = "pl" ]]; then
         helpflag="-help"
         if [[ "$extension" == "pm" ]]; then
            helpflag=""
         fi
         $PERL -w $file $helpflag >& /dev/null
         retval=$?
         count=$(($count + 1))
         # if the perl script fails when using -help, try again without it.
         if [[ $retval -ne 0 ]] && [[ $helpflag == "-help" ]]; then
             $PERL -w $file >& /dev/null
             retval=$?
         fi

         if [ $retval -eq 0 ]; then
             status="PASSED"
             npass=$(($npass + 1))
         else
             status="FAILED"
             echo "$status: $PERL -w '$file' $helpflag"
             PERL_ERR_FOUND=1
             nfail=$(($nfail + 1))
         fi
       fi
    fi
  fi
done < <(find . -name '*')

if [ $PERL_ERR_FOUND -gt 0 ] ; then
   echo "+-------------------------------------------------"
   echo "| PERL Warnings Check had $nfail/$count FAILED!"
   echo "+-------------------------------------------------"
else
   echo "+-------------------------------------------------"
   echo "| PERL Warnings Check had $npass/$count PASSED!"
   echo "+-------------------------------------------------"
fi

if [ $PYTHON_ERR_FOUND -gt 0 ] || [ $PERL_COMPILE_ERR_FOUND -gt 0 ] || [ $PERL_ERR_FOUND -gt 0 ] ; then
   echo "--------------------------------------------------"
   echo "FAILED: check_script_syntax contains at least one failed test"
   echo "--------------------------------------------------"
   exit 1
else
   echo "--------------------------------------------------"
   echo "PASSED: check_script_syntax has no Failures       "
   echo "--------------------------------------------------"
   exit 0
fi
echo "<hr>"

exit -1
