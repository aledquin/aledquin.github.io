package Comparator;
#
# NOTE: This perl module should reside in the same folder as to where
#       all the scripts reside that use this module. Currently that 
#       would be TOOL/dev/main/t/  where all the tests reside.
#
# nolint [Modules::ProhibitAutomaticExportation]
use strict;
use warnings;

use Cwd 'abs_path';
use File::Basename qw( fileparse );
use FindBin qw($RealBin $RealScript);
use lib "$RealBin/.";
use Util::CommonHeader;
use Util::Messaging;
use Util::Misc;
use Util::P4;

use Exporter;

our @ISA   = qw(Exporter);

# Symbols (subs or vars) to export by default 
our @EXPORT    = qw( comparator );  # nolint

# Symbols to export by request 
our @EXPORT_OK = qw(); # nolint

#+
# Subroutine Name:
#
#   comparator
#
# Purpose:
#
#   To open a .crr file (consisting of a filepath to the //depot per line)
#   Then see if those files exist in the specified perforce workarea
#
# Arguments:
#
#   p4ws:
#       The directory path to a perforce workspace root directory. This
#       script expects to find a /products/ dirpath under this area.
#
#   tdataDir:
#       This is the directory that holds the .crr files. The .crr files
#       contain a list of files and their revision from the perforce
#       server. The tdataDir directory is typically on the same dirlevel
#       as where these scripts are located. For testing, we usually store
#       required files in this /tdata/ area.
#
#   scriptName:
#       This is the name of the script that is using this comparator()
#       subroutine. This subroutine assumes that the .crr file name is
#       the same as the script name (with a different file extension).
#
#   testNumber:
#       This is the number of the test being run.
#
#   doDiff: optional
#       Boolean; if TRUE then actually compare the two files
#
#   Returns:
#       int: representing the number of failures spotted. 0 means success.
#-
sub comparator($$$$;$) {
    my $p4ws        = shift;  # the perforce workspace path to root 
    my $tdataDir    = shift;  # the directory path that holds .crr files
    my $scriptName  = shift;  # the script name running this subroutine
    my $testNumber  = shift;  # the number of the test
    my $doDiff      = shift;  # do a diff of the files 

    $scriptName     =~ s/\.[^.]+$//; # strip file extensions
    my $crrFileName = "${tdataDir}/${scriptName}_${testNumber}.crr";

    if ( ! -e $crrFileName ) {
        wprint("comparator: Missing file crrFileName='$crrFileName' p4ws='$p4ws'!\n");
        return -1;
    }

    # Now read the crr file and make sure those files exist in our
    # -p4ws tree somewhere
    my @datum;
    my $read_status = Util::Misc::read_file_aref( $crrFileName, \@datum);

    if ( $read_status ){
        my $msg = "comparator:read_file_aref('$crrFileName'...) failed.";
        my $ndatum = @datum;
        $msg .= "\n\t' . $datum[0]" if ( $ndatum);
        eprint("$msg\n");
        return 1;
    }

    my $errors = 0;  # success by default

    foreach my $filePath ( @datum ) {
        my $p4_filepath = $filePath;
        # //depot/products/lpddr5x_ddr5_phy/lp5x/project/.../file#4
        next if ( $filePath =~ m/^\s*#/);
        next if ( $filePath =~ m/^\s*$/);
        chomp $filePath;  # remove trailing linefeed

        $filePath =~ s|//depot/products/|$p4ws/products/|; 
        # strip the trailing revision number '#number'
        $filePath =~ s/#\d+$//;

        if ( ! -e $filePath ) {
            wprint( "comparator: File mentioned in the .crr File '$crrFileName' was Not Found In The Perforce WorkSpace '$filePath'\n");
            $errors ++;
        }else{
            if ( $doDiff ){
                my $server_output = da_p4_print_file($p4_filepath);

                # NOTE: ljames 10/27/2022 we need to have different file-diffs
                # depending on the file. What if it's a .gz file? What if it's
                # a .db file?
                my ($file_name, $dir_of_file, $suffix) = fileparse(abs_path($filePath), '\..*');
                viprint(LOW, "Comparing Files:\n\t$p4_filepath\n\t$filePath\n");
                if ( $suffix =~ m/db|gz/ ){
                    my $s_diskfile = -s $filePath; # returns filesize in bytes
                    vwprint(LOW, "Unable to diff '$suffix' files right now. Client file size on disk is $s_diskfile bytes\n");
                }else{
                    my @server_data = split /\n/,$server_output;
                    my @disk_data   = read_file( $filePath );
                    my $nserver     = @server_data;
                    my $ndisk       = @disk_data;
                    my $maxlen      = get_max_val($nserver, $ndisk); 
                    my $counter     = 0;
                    my $diffs       = 0;
                    viprint(LOW, "DEPOT FILE has $nserver lines.");
                    viprint(LOW, "CLIENT FILE has $ndisk lines.");
                    while ( $counter < $maxlen){
                        $counter ++;
                        my $server_line = shift @server_data;
                        my $disk_line   = shift @disk_data;
                        if ( ($server_line && $disk_line) && ($server_line ne $disk_line) ){
                            dprint(LOW, "Line $counter mismatch between files:\n\tserver='$server_line'\n\tdisk='$disk_line'\n");
                            $diffs++;
                        }
                    } 
                    if ( $diffs ){
                        eprint("Files do not compare!\n\t$p4_filepath\n\t$filePath\n");
                        $errors++;
                    }
                }
            }
        }
    }

    return $errors ;
}

################################
# A package must return "TRUE" #
################################


1;

__END__


