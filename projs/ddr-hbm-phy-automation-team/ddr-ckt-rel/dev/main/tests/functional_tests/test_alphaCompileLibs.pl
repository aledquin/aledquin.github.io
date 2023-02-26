#!/depot/perl-5.14.2/bin/perl
use strict;
use warnings;
# nolint utils__script_usage_statistics
use Cwd     qw(getcwd);
use Cwd     qw( abs_path );
use Carp    qw( cluck confess croak );
use Getopt::Std;
use Getopt::Long;
use FindBin qw( $RealBin $RealScript );


use lib "$RealBin/../../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
use lib "$RealBin/lib";
use TestUtils;

our $STDOUT_LOG   = undef; 
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $PROGRAM_NAME = $RealScript;
our $AUTO_APPEND_NEWLINE = 1;
our $DDR_DA_DEFAULT_P4WS = "p4_func_tests";
our $TEMPDIR      = "/tmp";

sub Main(){
    my $scriptName = "alphaCompileLibs.pl";
    my %t = ( 
        '01'=>{
            'description' => "alphaCompileLibs simple test",
            'testScript'  =>"$RealScript",
            'testDataDir' =>"$RealBin/../data/alphaCompileLibs_testdata",
            'scriptDir'   =>"$RealBin/../../bin",
            'scriptName'  =>"$scriptName",
            'lvf'         =>"anything", 
        },
    );

    my $workspace    = $ENV{'DDR_DA_DEFAULT_P4WS'} || $DDR_DA_DEFAULT_P4WS;
    my $opt_cleanup  = 1;
    my $opt_coverage = 0;
    my $opt_help     = 0;
    my $opt_tnum     = 0;

    ($workspace, $opt_cleanup, $opt_coverage, $opt_help, $opt_tnum) = 
        test_scripts__get_options( $workspace );
    if ( ! $workspace ) {
        return -1;
    }
    if ( $opt_help ) {
        return 0;
    }

    my $ntests = keys(%t);
    my $nfails = 0;
    foreach my $tstnum (sort keys %t) {
        if ( $opt_tnum ) {
            my $num = $tstnum + 0;     # convert string of number to a number
            next if ( $num != $opt_tnum );
        }
        my $href_args = $t{"$tstnum"};
        viprint(LOW, "Running $href_args->{'testScript'} $tstnum\n");
        my $cmdline_args = create_cmdline_args( $href_args,  $workspace );

        # We have to run our script within the test directory
        chdir ( $href_args->{'testDataDir'} ) if ( $href_args->{'testDataDir'} );
        my ($status,$stdout) = test_scripts__main(
            $tstnum,
            $opt_cleanup,
            $opt_coverage,
            $href_args->{'testScript'},
            $href_args->{'testDataDir'},
            $href_args->{'scriptDir'},
            $href_args->{'scriptName'},
            $cmdline_args,
            $workspace,
            \&my_comparator,
        );

       if ( $status != 0 ){
            dprint(LOW, "$tstnum: common main returned status = $status\n");
            my $tempfile = "${TEMPDIR}/ddr_ft_${tstnum}_${scriptName}_href_args->{'testScript'}_$$.log";
            my $ostatus  = open my $FOUT, ">", $tempfile ; #nolint open>
            my $seeFile = "";
            if ( $ostatus ){
                print $FOUT "$href_args->{'scriptName'} $cmdline_args\n";
                print $FOUT "$stdout\n";
                close($FOUT);
                $seeFile = " See $tempfile ";
            }
           
            print("FAILED: #${tstnum} $href_args->{'testScript'} $href_args->{'description'}${seeFile}\n");
            $nfails += 1;
        }else{
            print("PASSED: #${tstnum} $href_args->{'testScript'} $href_args->{'description'}\n");
        }
    }


    if ( $nfails  ){
        print("FAILED: ($nfails/$ntests) $RealScript\n");
    }else{
        print("PASSED: ($ntests/$ntests) $RealScript\n");
    }

    
    exit($nfails);
}

sub my_comparator($$$$) {
    my $p4ws        = shift;  # the perforce workspace path to root 
    my $tdataDir    = shift;  # the directory path that holds .crr files
    my $scriptName  = shift;  # the script name running this subroutine
    my $testNumber  = shift;  # the number of the test

    $scriptName     =~ s/\.[^.]+$//; # strip file extensions
    my $crrFileName = "${tdataDir}/${scriptName}_${testNumber}.crr";

    if ( ! -e $crrFileName ) {
        wprint("comparator: Missing file '$crrFileName' !");
        return -1;
    }

    # Now read the crr file and make sure those files exist in our tdataDir
    # area.
    open my $FID, "<", $crrFileName || return -1;  #nolint open>

    my @datum = <$FID>;
    close($FID);

    my $errors = 0;  # success by default

    foreach my $filePath ( @datum ) {
        chomp $filePath;  # remove trailing linefeed
        if ( ! -e "${tdataDir}/$filePath" ) {
            wprint( "comparator: File mentioned in the .crr File was Not Found In The /data output area '$filePath'");
            $errors ++;
        }
    }

    return $errors ;
}

sub create_cmdline_args($;$){
    my $href_args = shift;
    my $workspace = shift;

    my $verbosity = $main::VERBOSITY;
    my $debug     = $main::DEBUG;
    my $lvf       = $href_args->{'lvf'};
  

    my $cmd = "";
    $cmd .= " -lvf "                   if ( $lvf       );
    $cmd .= " -debug $debug "          if ( $debug     );
    $cmd .= " -verbosity $verbosity "  if ( $verbosity );

    return $cmd;
}

&Main();


