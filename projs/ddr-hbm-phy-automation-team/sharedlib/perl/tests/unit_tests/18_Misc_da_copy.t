use strict;
use warnings;
use v5.14.2;

use Test2::Bundle::More;
use Test2::Tools::Compare;
use File::Temp;
use Term::ANSIColor;
$Term::ANSIColor::EACHLINE = "\n";  # Resets the color after each newline...

use FindBin qw($RealBin $RealScript);

use lib "$RealBin/../lib";
use Util::CommonHeader;
use Util::Messaging;
use Util::Misc;

our $DEBUG      = NONE;
our $VERBOSITY  = NONE;
our $STDOUT_LOG = undef; 
our $DA_RUNNING_UNIT_TESTS = 1;

sub Main() {
    plan(6);

    # Test 1: Successful copy
    {
        my $srcFile  = "$RealBin/../data/${RealScript}.lis";
        my $destFile = "$RealBin/../data/${RealScript}.lis_copy";
        my @expected = (1,"-I- Copied file successfully from\n\t '$srcFile'\n      to\n\t'$destFile'\n");
        $VERBOSITY = HIGH;
        ok(stdout_is(1, \&da_copy, $srcFile, $destFile, \@expected), 'da_copy should be success');
        unlink($destFile) if( -e $destFile );
        $VERBOSITY = NONE;
    }
    # Test 2: Successful copy to a destintation directory
    {
        my $srcFile  = "$RealBin/../data/${RealScript}.lis";
        my $destDir  = "$RealBin/../data/da_copy";
        my $destFile = "$destDir/${RealScript}.lis";
        mkdir($destDir);
        my @expected = (1,"-I- Copied file successfully from\n\t '$srcFile'\n      to\n\t'$destDir'\n");
        $VERBOSITY = HIGH;
        ok(stdout_is(2, \&da_copy,$srcFile,$destDir, \@expected), 'da_copy should be success');
        unlink($destFile) if( -e $destFile );
        $VERBOSITY = NONE;
        rmdir($destDir) if( -e $destDir );
    }
    #Test 3: Source file doesn't exist
    {
        my $srcFile = "$RealBin/../data/${RealScript}";
        my $destFile = "/tmp/${RealScript}.lis_copy_$$";
        my @expected = (0,colored("-W- The file '$srcFile' used in the copy operation doesn't exist.\n",'yellow'));
        ok(stdout_is(3, \&da_copy,$srcFile,$destFile, \@expected), 'No source file');
    }
    #Test 4: Destination directory doesn't exist
    {
        my $srcFile = "$RealBin/../data/${RealScript}.lis";
        my $destDir = "$RealBin/../data/da_copy";
        my $destFile = "$destDir/${RealScript}.lis_copy";
        my @expected = (0,colored("-W- The destination directory '$destDir' doesn't exist!\n".
                                  "Unable to copy to '$destFile'.\n",'yellow'));
        ok(stdout_is(4, \&da_copy,$srcFile,$destFile, \@expected), 'No destination directory');
    }
    #Test 5: No write permission to destination directory
    {
        my $srcFile = "$RealBin/../data/${RealScript}.lis";
        my $destDir = "$RealBin/../data/da_copy";
        my $destFile = "$destDir/${RealScript}.lis_copy";
        mkdir($destDir);
        chmod(0555, $destDir);
        my @expected = (0,colored("-W- The user doesn't have write permission in the destination ".
                                "directory '$destDir'.\n".
                                "Unable to copy to '$destFile'.\n",'yellow'));
        ok(stdout_is(5, \&da_copy,$srcFile,$destFile, \@expected), 'No write permission to destination directory');
        rmdir($destDir) if( -e $destDir );
    }
    #Test 6: No write permission to destination file
    {
        my $srcFile = "$RealBin/../data/${RealScript}.lis";
        my $destFile = "$RealBin/../data/${RealScript}.lis_copy";
        open(my $fh,">$destFile");
        close($fh);
        mkdir($destFile);
        chmod(0555, $destFile);
        my @expected = (0,colored("-W- The file '$destFile' is not writtable. ".
                                  "Cannot complete the copy operation.\n",'yellow'));
        ok(stdout_is(6, \&da_copy,$srcFile,$destFile, \@expected), 'No write permission to destination file');
        unlink($destFile);
    }

    done_testing();

    return 0;
}

sub get_temp_filename($$){
    my $tstnum     = shift;
    my $stdout_err = shift;
    my $fh = File::Temp->new(
        TEMPLATE => "unit_test_18_Misc_da_copy_${tstnum}_${stdout_err}_XXXXX",
        DIR      => '/tmp',
        SUFFIX   => '.log'
    );
    return $fh->filename;
}

sub stdout_is($$$$) {
    my $tstnum      = shift;
    my $ref_da_copy = shift;
    my $srcFile     = shift;
    my $destFile    = shift;
    my @expected    = @{+shift};
    my $temp_file   = get_temp_filename($tstnum, "stdout");
    my $ret_status;
    do {
        local *STDOUT;
        unlink($temp_file) if ( -e $temp_file );
        open(STDOUT, '>', $temp_file) || return 0;
        $ret_status = $ref_da_copy->($srcFile, $destFile);
    };
    open(my $fh, '<', $temp_file) || return 0;
    my @lines = <$fh>;
    close($fh);
    my $stdout_line = join("",@lines);
    #print("DEBUG: ret_status='$ret_status'  expected='@expected[0]' stdout='$stdout_line'\n");
    return( ($ret_status eq $expected[0]) && ($stdout_line eq $expected[1]) );
}

Main();

