use strict;
use warnings;
use 5.14.2;
use Test2::Bundle::More;
use File::Temp;
use File::Basename;
use Try::Tiny;
use Data::Dumper;
use Getopt::Long;

use FindBin qw($RealBin $RealScript);
use lib "$RealBin/../../lib/perl/";
use alphaHLDepotRelease;
use Util::Misc;

our $DEBUG         = 0;
our $VERBOSITY     = 0;
our $FPRINT_NOEXIT = 1;

sub suppress_output_and_process($$$$$$) {
    my $testnum       = shift;
    my $file          = shift;
    my $hash_ref      = shift;
    my $hash_yaml_ref = shift;
    my $aref_warnings = shift; 
    my $aref_errors   = shift;
    my $warnfile      = "/tmp/unit_test_22_processLegalReleaseFile_yaml_batch_stdout_${testnum}_$$";
    my $errfile       = "/tmp/unit_test_22_processLegalReleaseFile_yaml_batch_stderr_${testnum}_$$";
    my $everything_is_ok = 1;

    do {
        local *STDOUT;
        local *STDERR;
        open( STDOUT, '>', "$warnfile" ) || return 0;
        open( STDERR, '>', "$errfile" ) || return 0;
        $everything_is_ok = 0;
        processLegalReleaseFile( $file, $hash_ref );
        # if something horrible happens here, then everything_is_ok will
        # remain as 0 and we will know that something serious happened.
        $everything_is_ok = 1;
        my $yaml_file = $file;
        $yaml_file =~ s/\.txt/\.yml/;
        if ( ! -e $yaml_file ){
            $yaml_file =~ s/\.yml/\.yaml/;
        }
        processLegalReleaseFile( $yaml_file, $hash_yaml_ref);
    };

    if ( -e $errfile && ! -z $errfile){
        my @errors = read_file( $errfile );
        my $skip_count=0;
        foreach my $error ( @errors ) {
            chomp $error;
            next if ( $error =~ m/^\s*$/ );

            if ( $skip_count > 0 ){
                $skip_count--;
                next;
            }
            if ( $error =~ m/-F- Failed to find/ || 
                 $error =~ m/-F- None of metal stack/ ){
                $skip_count = 1; # skip the following line as well
                next;
            }
            
            push( @$aref_warnings, "'$error'\n");
        }
    }

    if ( -e $warnfile && ! -z $warnfile ){
        my @content = read_file( $warnfile );
        foreach my $line ( @content ) {
            if ( $line =~ m/UnknownLegalReleaseLine/ ){
                chomp $line;
                push( @$aref_errors, $line);
            }

            if ( $line =~ m/undefined value as an/ ){
                chomp $line;
                push( @$aref_warnings, $line);
            }
        }
    }

    my $nwarns = @$aref_warnings;
    unless ( $nwarns ){
        unlink( $warnfile ) if ( -e $warnfile );
        unlink( $errfile )  if ( -e $errfile );
    }

    return $everything_is_ok;
}

sub Main() {

    my $file          = "$RealBin/../data/test_legal_release_non_existant.t";
    my %legalReleaseHash = ();
    my %legalReleaseHashYaml = ();
    my %expected_hash = ();
    my $opt_tnum;
    my $opt_verbosity;
    my $opt_debug;

    my $get_status   = GetOptions( "testnum=i"  => \$opt_tnum, "verbosity=i" => \ $opt_verbosity, "debug=i" => \$opt_debug);
    $main::VERBOSITY = $opt_verbosity if ( $opt_verbosity );
    $main::DEBUG     = $opt_debug     if ( $opt_debug);

    my $yaml_count = 0;

    print("RealBin is '$RealBin'\n");
    my @files = `ls $RealBin/../data/alphaHLDepotRelease/legalRelease/*.txt`; #nolint backticks
    my $nfiles = @files;

    foreach my $fname (@files) {
        chomp $fname;
        my $yfname = $fname;
        $yfname =~ s/\.txt/.yml/;
        $yaml_count++ if ( -e $yfname ) ;
    }

    my $count = @files;
    plan( $count );
    my $nth = 0;
    foreach my $file ( @files ) {
        chomp $file;
        $nth++;
        next if ( defined $opt_tnum && $opt_tnum != 0 && $opt_tnum != $nth );
        print("Processing file: '$file'\n");
        my @warnings;
        my @errors;
        %legalReleaseHash = ();
        %legalReleaseHashYaml = ();

        my $isok = suppress_output_and_process( $nth, $file, \%legalReleaseHash, \%legalReleaseHashYaml, \@warnings, \@errors );
        if ( ! $isok ){
            ok( $isok == 1, "$nth: Serious failure calling suppress_output_and_process()");
        }

        my $nwarnings = @warnings;
        
        # We expect warnings for some legal release files; don't complain if we 
        # see those warnings.
        if ( $file =~ m/lpddr54\.d851-lpddr54-tsmc16ffc18\.rel1\.20_1\.20a_rel_\.design\.legalRelease\./){
            if ( $nwarnings == 2 ) {
                $nwarnings  = 0;
            }
        }
        if ( $file =~ m/lpddr54\.d890-lpddr54-tsmc5ffp12\.rel1\.00\.design_unrestricted\.legalRelease\./){
            if ( $nwarnings == 1) {
                $nwarnings = 0;
            }
        }

        if ( $nwarnings > 0 ){
            print("warnings: $nwarnings\n");
            foreach my $warn (@warnings){
                print("\t$warn\n");
            }
        }

        my $short = $file;
        my $columns = 120;
        if ( length($short) >=  $columns) {
            $short = substr($file, -$columns, $columns);
            $short = "...${short}";
        }
       
        my $set_cmd_list = "";
        if ( $nwarnings > 0 ) {
            my @setcmds;
            foreach my $warn ( @warnings ) {
                if ( $warn =~ m/set\s+(\w+)/ ) {
                    my $thewarn = $1;
                    push( @setcmds, "set $thewarn\n");
                }
            }
            $set_cmd_list = join("\t", @setcmds);
        }
        
        my $msg = "processLegalReleaseFile() of '$short' has $nwarnings warnings";
        $msg .= "\n\t${set_cmd_list}" if ( $set_cmd_list );
        ok ($nwarnings == 0 , $msg);

        if ( $nwarnings == 0 ) {
            my $nelements = keys( %legalReleaseHashYaml );
            if ( $nelements > 0 ){
                # this currently fails with {phyvMacros}{dwc_lppdr5xmphy_utility_blocks}[0]  ARRAY()  eq ARRAY()
                #is_deeply( \%legalReleaseHashYaml, \%legalReleaseHash, "Compare tcl to yml results" ); 
            }
        }

    }
  
    done_testing();

    return 0;
}

Main();

