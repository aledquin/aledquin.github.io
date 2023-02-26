use strict;
use warnings;
use 5.14.2;
use Test2::Bundle::More;
use File::Temp;
use File::Basename;
use Try::Tiny;
use Data::Dumper;

use FindBin qw($RealBin $RealScript);
use lib "$RealBin/../../lib/perl/";
use alphaHLDepotRelease;
use Util::Misc;

our $DEBUG         = 0;
our $VERBOSITY     = 0;
our $FPRINT_NOEXIT = 1;

sub suppress_output_and_process($$$$$) {
    my $testnum       = shift;
    my $file          = shift;
    my $hash_ref      = shift;
    my $aref_warnings = shift; 
    my $aref_errors   = shift;
    my $warnfile      = "/tmp/unit_test_processLegalReleaseFile_batch_stdout_${testnum}_$$";
    my $errfile       = "/tmp/unit_test_processLegalReleaseFile_batch_stderr_${testnum}_$$";
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
            if ( $error =~ m/-F- Failed to find/ ){
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
    my %stackHash = ();
    my %expected_hash = ();

    print("RealBin is '$RealBin'\n");
    my @files = `ls $RealBin/../data/alphaHLDepotRelease/legalRelease/*.txt`; #nolint backticks
    my $count = @files;
    my @p10020416_38748_files = `ls $RealBin/../data/alphaHLDepotRelease/test*p10020416*legal_release.txt`; #nolint backticks
    my $p10020416_38748_count = @p10020416_38748_files; 
    plan( $count + $p10020416_38748_count * 3);
    my $nth = 0;
    foreach my $file ( @files ) {
        $nth++;
        my @warnings;
        my @errors;
        chomp $file;
        %stackHash = ();

        my $isok = suppress_output_and_process( $nth, $file, \%stackHash, \@warnings, \@errors );
        if ( ! $isok ){
            ok( $isok == 1, "$nth: Serious failure calling suppress_output_and_process()");
        }

        my $nwarnings = @warnings;
        
        # We expect warnings for some legal release files; don't complain if we 
        # see those warnings.
        if ( $file =~ m/lpddr54\.d851-lpddr54-tsmc16ffc18\.rel1\.20_1\.20a_rel_\.design\.legalRelease.txt/){
            if ( $nwarnings == 2 ) {
                $nwarnings  = 0;
            }
        }
        if ( $file =~ m/lpddr54\.d890-lpddr54-tsmc5ffp12\.rel1\.00\.design_unrestricted\.legalRelease.txt/){
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

    }
  
    my %icv_expected = (
        "test.p10020416-38478.calibre_verifs_false.legal_release.txt" => ["ant", "drc", "erc", "lvs", "drcint"],
        "test.p10020416-38478.calibre_verifs_true.legal_release.txt"=> ["ant", "drc", "erc", "lvs", "drcint"],
        "test.p10020416-38478.calibre_verifs_true.verif_addi_dfm.legal_release.txt"=> ["ant", "drc", "erc", "lvs", "drcint", "dfm"],
        "test.p10020416-38478.calibre_verifs_true.verif_addi_dfm_xyz.legal_release.txt"=> ["ant", "drc", "erc", "lvs", "drcint", "dfm", "xyz"],
        "test.p10020416-38478.calibre_verifs_true.verif_remove_erc.legal_release.txt"=> ["ant", "drc",  "lvs", "drcint" ],
        "test.p10020416-38478.calibre_verifs_true.verif_remove_erc_lvs.legal_release.txt"=> ["ant", "drc", "drcint" ],
        "test.p10020416-38478.customer_macro.legal_release.txt"=> ["ant", "drc", "erc", "lvs", "drcint" ],
        "test.p10020416-38478.no_new_args.legal_release.txt"=> ["ant", "drc", "erc", "lvs", "drcint"],
        "test.p10020416-38478.invalid_param.legal_release.txt" => ["ant", "drc", "erc", "lvs", "drcint"],
    );
    my %calibre_expected = (
        "test.p10020416-38478.calibre_verifs_false.legal_release.txt" => [],
        "test.p10020416-38478.calibre_verifs_true.legal_release.txt"=> ["ant", "drc", "erc", "lvs", "drcint"],
        "test.p10020416-38478.calibre_verifs_true.verif_addi_dfm.legal_release.txt"=> ["ant", "drc", "erc", "lvs", "drcint", "dfm"],
        "test.p10020416-38478.calibre_verifs_true.verif_addi_dfm_xyz.legal_release.txt"=> ["ant", "drc", "erc", "lvs", "drcint", "dfm", "xyz"],
        "test.p10020416-38478.calibre_verifs_true.verif_remove_erc.legal_release.txt"=> ["ant", "drc", "lvs", "drcint" ],
        "test.p10020416-38478.calibre_verifs_true.verif_remove_erc_lvs.legal_release.txt"=> ["ant", "drc", "drcint" ],
        "test.p10020416-38478.customer_macro.legal_release.txt"=> ["ant", "drc", "erc", "lvs", "drcint" ],
        "test.p10020416-38478.no_new_args.legal_release.txt"=> [],
        "test.p10020416-38478.invalid_param.legal_release.txt" => [],
    );

    foreach my $file ( @p10020416_38748_files) {
        $nth++;
        my @warnings;
        my @errors;
        chomp $file;
        %stackHash = ();
        my $file_name = basename($file);
        my $aref_expected_icv_list     = $icv_expected{"$file_name"} || [];
        my $aref_expected_calibre_list = $calibre_expected{"$file_name"} || [];

        my $isok = suppress_output_and_process( $nth, $file, \%stackHash, \@warnings, \@errors );
        if ( ! $isok ){
            ok( $isok == 1, "$nth: Serious failure calling suppress_output_and_process()");
        }else{
            my $nerrors = @errors;
            my $nexpected = 0;
            $nexpected = 1 if ( $file_name =~ m/invalid_param/ );
            ok( $nerrors == $nexpected, "($nth) ($nerrors vs $nexpected) Checking for any Errors printed while parsing '$file_name'");
            if ( $nerrors != $nexpected ) {
                foreach my $text ( @errors ) {
                    print("\tError: $text\n");
                }

            }

            my $aref_icv_list     = $stackHash{'icv_report_list'};
            my $aref_calibre_list = $stackHash{'calibre_report_list'};
            is_deeply( $aref_icv_list,     $aref_expected_icv_list,     "($nth) processLegalReleaseFile p10020416-38478 icv '$file_name'");
            is_deeply( $aref_calibre_list, $aref_expected_calibre_list, "($nth) processLegalReleaseFile p10020416-38478 calibre '$file_name'");
        }

    }
    

    done_testing();

    return 0;
}

Main();

