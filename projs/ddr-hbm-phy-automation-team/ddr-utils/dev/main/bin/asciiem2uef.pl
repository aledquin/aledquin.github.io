#!/depot/perl-5.14.2/bin/perl -w
#!/depot/perl-5.8.0/bin/perl
###############################################################################
# Name    : asciiem2uef.pl
# Author  : dkang
# Date    : 2015-03-05
# Purpose : N/A
#
# Modification History
# Revision 1.0
# Oct-30-2017 dkang : grapped from /slowfs/us01dwt3p219/anilsa/em_script_work/asciiem2uef_update.pl, acpc was updated. Used by alpha team. 
# Sep-25-2014 dkang : create the first version
######################################################################################################
### Setup defaults
##################################################################
use strict;
use warnings;
use File::Basename;
use POSIX qw(log10);
use Getopt::Long;
use Pod::Usage;
use File::Basename;
use Cwd;

use FindBin qw( $RealBin $RealScript );
use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;


#----------------------------------#
our $STDOUT_LOG; # Initiailized in the BEGIN block
our $DEBUG               = NONE;
our $VERBOSITY           = NONE;
our $TESTMODE            = undef;
our $PROGRAM_NAME        = $RealScript;
our $LOGFILENAME         = getcwd() . "/$PROGRAM_NAME.log";
our $VERSION             = get_release_version();
our $AUTO_APPEND_NEWLINE = 1;
#----------------------------------#
our $PREFIX              = "ddr-utils";
#----------------------------------#

BEGIN {
    our $AUTHOR = 'dkang';
    #$STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
    $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
    header();
}

END {
    footer();
    write_stdout_log( $LOGFILENAME );
    utils__script_usage_statistics( "$PREFIX-$PROGRAM_NAME", $VERSION );
}

my ($OUTFILE, $CSVFILE, $LOADFILE, $FILTERFILE );

sub Main(){
    return();
}

my $emTypesDefault = "iavg irms acpc";
my $filterfactor = "1 2 5 10";
my $asciiPath = getcwd();
my $emTypes = "";
my $opt_debug;
my $opt_verbosity;


chomp($asciiPath);
my $cellName; 
my $pathhier = dirname $asciiPath;
$cellName = basename $asciiPath;
if ($cellName eq "ascii") {
    $cellName = basename $pathhier;
}

GetOptions (
   't=s' => \$emTypes,
   'f=s' => \$filterfactor,
   'a=s' => \$asciiPath,
   'c=s' => \$cellName,
   'd=i' => \$opt_debug,
   'v=i' => \$opt_verbosity,
);

$main::VERBOSITY = $opt_verbosity if( defined $opt_verbosity );
$main::DEBUG     = $opt_debug     if( defined $opt_debug     );
 

pod2usage(
   {-msg => "\nusage : $0 \
   --t <emTypes>        required. Avaiable Types : $emTypesDefault \
   --c [cellName]       optional. Default : $cellName (necessary for loading uef) \
   --f [filterfactor]   optional. Define min I/Imax filterfactor and bad/worst/must factor. Default : $filterfactor \
   --a [asciipath]      optional. Default : current path ($asciiPath) \
   --d [debug]          optional. Default value = 0 \
   --v [verbosity]      optional. Default value = 0 \
   \n\n------------------------------------------------------------------------------ \
--- Run Example : \
---   > $PROGRAM_NAME --t \"$emTypesDefault\"
\n------------------------------------------------------------------------------ \
---   Description : \
---      1. filter EM I/Imax < min filter factor from ascii output files \
---      2. Convert <cell>_post-<net>_iavg.ascii coordinate file into uef format to be able to be loaded into CD \
--- \
---   Tips   \
---      1. How to load to uef file in CD?        \
---         > inside CD Console window, type uev \
---         > load uef file \
--- \
---   SUPPORT     : dkang\@synopsys.com                                     --- \
------------------------------------------------------------------------------ \n",
   -verbose => 0,exitval=>0}
) if (not $emTypes);

 my $ratio     ="" ; 
 my $layer     ="" ;
 my $xc        ="" ; 
 my $yc        ="" ;
 my $width     ="" ;
 my $length    ="" ;
 my $ruleshort ="" ; 
 my @ratios    ="" ;
 my $rulename  ="" ;
 my $x1        ="" ; 
 my $y1        ="" ;
 my $x2        ="" ;


my @emTypes = split /\s+/, $emTypes;
my $emNum = @emTypes;

my $i=1;
foreach my $fileType (@emTypes) {

    my $emfiles = `ls $asciiPath/*_${fileType}.ascii*`;  #nolint
    my $type1=${fileType};
    #print "$type1";

    my @emfiles = "";
    if ($emfiles eq "") {
        print "   ($i/$emNum) : Skip collecting $cellName $fileType EM errors due to $asciiPath/*_${fileType}.ascii* do not exist.\n";
        exit;
    } else {
        print "   ($i/$emNum) : Collecting $cellName $fileType EM violations with \"$filterfactor\"  from $asciiPath/*_${fileType}.ascii*\n";
        @emfiles = split /\n/, $emfiles;
    }


    my $rulename = "";

    my $commentCount = 0;
    my $commentText = "";
    my $netName = "";


    if (! -d "$asciiPath/run_details") {
        `mkdir $asciiPath/run_details`;
    }
    if (-f "$asciiPath/em_errors.${fileType}.uef") {
        `rm -f $asciiPath/em_errors.${fileType}.uef`;
    }
    if (-f "$asciiPath/run_details/drc_errors.${fileType}.csv") {
        `rm -f $asciiPath/run_details/drc_errors.${fileType}.csv`;
    }
    if (-f "$asciiPath/em_violations_summary.${fileType}") {
        `rm -f $asciiPath/em_violations_summary.${fileType}`;
    }
    if (-f "$asciiPath/run_details/em_filter_resulst.${fileType}") {
        `rm -f $asciiPath/run_details/em_filter_resulst.${fileType}`;;
    } 
    
    open( $OUTFILE,   ">","$asciiPath/em_errors.${fileType}.uef");  # nolint open>
    open( $CSVFILE,   ">","$asciiPath/run_details/drc_errors.${fileType}.csv");  # nolint open>
    open( $LOADFILE,  ">","$asciiPath/em_violations_summary.${fileType}_ascii");  # nolint open>
    open( $FILTERFILE,">","$asciiPath/run_details/em_filter_resulst.${fileType}_ascii");  # nolint open>
       print $OUTFILE "CELL $cellName\n";
       if (@emfiles > 0) { &em2Error(\@emfiles,$filterfactor,$type1); }
       print $OUTFILE "\n\n";
    close( $OUTFILE    );
    close( $CSVFILE    );
    close( $LOADFILE   );
    close( $FILTERFILE );
    print "           Done collecting $cellName EM/IR errors into \n";
    print "           $cellName Output files: \n";
    print "              em_errors_${fileType}.uef                         : UEV file\n";
    print "              em_violations_summary.${fileType}_ascii           : EM I/IMax > $emTypes[0]\n\n";
    
    $i=$i+1;
} # END foreach $fileType


#######################################################################
sub em2Error {
    my @files        = @{shift @_};
    my $filterfactor = shift @_;
    my $type1        = shift @_;
    
    my @filterfactors = split /\s+/, $filterfactor;
    my $minfactor     = $filterfactors[0];
    my $badfactor     = $filterfactors[1];
    my $worstfactor   = $filterfactors[2];
    my $mustfixfactor = $filterfactors[3];

    my $processFilterLine = "";
    my $processSumLine    = "";

    foreach my $file (@files) {
        my $info = "           INFO : filtering EM errors I/Imax < $minfactor from   $file\n";
        if (! -f $file) {
            print "            WARNING : $file is not existing.\n";
            next;
        } else {
            print "$info";
            print $LOADFILE "$info";
            print $FILTERFILE "$info";
        }

        my $baseName = basename $file;
        my @items = split /(\.|_)/, $baseName;
        my $cellName = $items[0];

        my $commentCount = 0;
        my $netName="";
        my $count=0;
        my $line;
        foreach my $line ( read_file($file) ){
            chomp($line);
    
            my $commentCount = $commentCount + 1;
            my $y2;
            my $pointList;
            if ($commentCount < 3) {
                print $LOADFILE "$line\n";
                print $FILTERFILE "$line\n";

                next;
            }
            chomp($line);

            if( $line!~ m/^\s*$|^\s*#/ ){ #not empty line
                $line=~ s/^\s*(.*?)\s+ $/$1/; #get rid of trailing spaces
                $line=~ s/\[/\(/g; # replace [ with (
                $line=~ s/\]/\)/g; # replace ] with )


                if ($line=~m/^Processing net: (\S+)\s*$/) {
                    $netName = $1;
                    $processFilterLine = $line;
                    $processSumLine = $line;
                    
#                    print $LOADFILE "$_\n";
#                    print $FILTERFILE "$_\n";
                }
                if ($type1 !~ m/acpc/){
                    if( $line =~ m/^\S+\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)(.*)/i ){
                        $ratio = $3;
                        $layer = $4;
                        $xc    = $5;
                        $yc    = $6;
                        $width = $7;
                        $length= $10;

                        $ruleshort = "(I/Imax : $ratio) $layer ";
                        @ratios = split /\./, $ratio;
   #                     $rulename = "$ratios[0]-$netName-$layer";
                        $rulename = $netName;
                        my $commentText = "$ruleshort: $line";

                        if ($ratio >= $minfactor) {
                            if ($minfactor <= $ratio and $ratio < $badfactor) {
                                $rulename = "bad ($minfactor-$badfactor) $netName";
                            } elsif ($badfactor<= $ratio and $ratio <$worstfactor) {
                                $rulename = "worst ($badfactor-$worstfactor) $netName";
                            } elsif ($ratio >= $mustfixfactor) {
                                $rulename = "mustfix > $mustfixfactor $netName";
                            }

                            $x1 = $xc - $width/2;
                            $y1 = $yc - $length/2;
                            $x2 = $xc + $width/2;
                            $y2 = $yc + $length/2;

                           ### find EM errors at location
                           $pointList = "\{$x1 $y1\} \{$x2 $y2\}";

                           print $OUTFILE "ERR $rulename : $commentText\n";
                           print $OUTFILE "POL $pointList\n";

                           if ($rulename ne "") {print $CSVFILE "$rulename,$count,$commentText\n";}
                           $count = 1;

                           if ($processSumLine ne "") {
                               print $LOADFILE "\n$processSumLine\n";
                               $processSumLine = "";
                           }
                           print $LOADFILE "$line\n";
                        }else{
                            if ($processFilterLine ne "") {
                                print $FILTERFILE "\n$processFilterLine\n";
                                $processFilterLine = "";
                            }
                            print $FILTERFILE "$line\n";
                        }
                    }
                }
                
                if ($type1 =~m/acpc/){
                if ($line =~ m/^\S+\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)(.*)/i){
    
                     $ratio = $3;
                     $layer = $4;
                     $xc = $5;
                     $yc = $6;
                     $width = $7;
                     $length = $10;

                     $ruleshort = "(I/Imax : $ratio) $layer ";
                     @ratios = split /\./, $ratio;
#                     $rulename = "$ratios[0]-$netName-$layer";
                     $rulename = $netName;
                     my $commentText = "$ruleshort: $line";

                    if ($ratio >= $minfactor) {
                    if ($minfactor <= $ratio and $ratio < $badfactor) {
                        $rulename = "bad ($minfactor-$badfactor) $netName";
                    } elsif ($badfactor<= $ratio and $ratio <$worstfactor) {
                        $rulename = "worst ($badfactor-$worstfactor) $netName";
                    } elsif ($ratio >= $mustfixfactor) {
                        $rulename = "mustfix > $mustfixfactor $netName";
                    }

                    $x1 = $xc - $width/2;
                    $y1 = $yc - $length/2;
                    $x2 = $xc + $width/2;
                    $y2 = $yc + $length/2;

                    ### find EM errors at location
                    $pointList = "\{$x1 $y1\} \{$x2 $y2\}";

                    print $OUTFILE "ERR $rulename : $commentText\n";
                    print $OUTFILE "POL $pointList\n";

                    if ($rulename ne "") {print $CSVFILE "$rulename,$count,$commentText\n";}
                    $count = 1;

                    if ($processSumLine ne "") {
                        print $LOADFILE "\n$processSumLine\n";
                        $processSumLine = "";
                    }

                    print $LOADFILE "$line\n";

                    } else {
                        if ($processFilterLine ne "") {
                            print $FILTERFILE "\n$processFilterLine\n";
                            $processFilterLine = "";
                        }
                        print $FILTERFILE "$line\n";
                    }
                }
                }                
            }
        } # END while
    } # END foreach $file
} # END sub em2Error 

