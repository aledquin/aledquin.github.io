#!/depot/perl-5.14.2/bin/perl
use strict;
use warnings;
use Pod::Usage;
use Data::Dumper;
use File::Copy;
use Getopt::Std;
use Getopt::Long;

use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Cwd qw( abs_path getcwd );
use Carp qw( cluck confess croak );
use FindBin qw( $RealBin $RealScript );

use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;


#--------------------------------------------------------------------#
#our $STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
our $STDOUT_LOG   = EMPTY_STR;              # Empty String: Log msg to var => ON
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $PREFIX       = "ddr-utils-timing";
our $PROGRAM_NAME = $RealScript;
our $VERSION      = get_release_version() || 2023.01; # Syntax: YYYYww##[.#] optional day 1-7
                                            # The work week number can be found in
                                            # your outlook calendar. The days are 1=sunday
                                            # 2=monday ... 7=saturday

#--------------------------------------------------------------------#

BEGIN { our $AUTHOR = 'bhattach'; header(); }

END {
    write_stdout_log("${PROGRAM_NAME}.log");
    footer();
    utils__script_usage_statistics( "$PREFIX-$RealScript", $VERSION );
}

use Getopt::Long;
use File::Basename;
use Cwd 'abs_path';
use Pod::Usage;
use File::Copy;
use File::Basename;
use Capture::Tiny qw/capture/;
use File::Basename qw(dirname basename);
use FindBin qw($RealBin $RealScript);
use List::Util qw( min max );

ShowUsage("$RealBin/$RealScript") unless(@ARGV);


  my ($help,$cell_list,$pvt_list,$out_lib_name);

  my $result = GetOptions(
    "cell_list=s" => \$cell_list,
    "pvt_list=s" => \$pvt_list,
    "out_lib_name=s" => \$out_lib_name,
    "h" => \$help,
    "help" => \$help,
    );

&ShowUsage("$RealBin/$RealScript") if ($help);;
&Main();

sub Main {
my $ArgOK = 1;
$ArgOK &= CheckRequiredArg($cell_list, "cell_list");
$ArgOK &= CheckRequiredArg($pvt_list, "pvt_list");

if (!$ArgOK) {die "Exiting on missing required arguments\n"}

my $FileOK = 1;
$FileOK &= CheckFileRead($cell_list);
$FileOK &= CheckFileRead($pvt_list);

if (!$FileOK) {die "Exiting on unreadable file(s)\n"}


my @OPFILE;
push @OPFILE, "create char\nexec cp $RealBin/configure.tcl char/config/\nset_location char\nexec mkdir -p $out_lib_name\n";
my $WriteStatus1 = write_file(\@OPFILE, "TEST.tcl");


my @TFILE1;
push @TFILE1, "#!/bin/sh\ncd $out_lib_name/\nforeach c (`cat ../$pvt_list`)\nsed -i -e 's/library(.*/library($out_lib_name\_'\$c') {/g' $out_lib_name\_{\$c}\_pg.lib\nend\nsed -i -e '1,9d' *.lib\nsed -i -e 's/current_unit : \"1uA\" ;/current_unit : \"1uA\" ;\\n  leakage_power_unit : \"1uW\" ;/g' *.lib\nmkdir -p lib lib_pg\ncd ../"; #nolint Backticks
my $WriteStatus2 = write_file(\@TFILE1, "dir1.sh");

my @TFILE;
push @TFILE, "#!/bin/sh\nmodule unload ddr-utils-timing\nmodule load ddr-utils-timing\nmodule unload siliconsmart\nmodule load siliconsmart\nforeach c ( `cat $pvt_list `)\nforeach d ( `cat $cell_list `)\nmkdir  -p \$c {\$c}_pg\ncp -rf {\$d}/lib_pg/{\$d}*{\$c}_pg.lib {\$c}_pg\ncp -rf {\$d}/lib_pg/{\$d}*{\$c}_pg.lib ./\ncp -rf {\$d}/lib/{\$d}*{\$c}.lib \$c\ncp -rf {\$d}/lib/{\$d}*{\$c}.lib ./\nmv {\$c}_pg/{\$d}*{\$c}_pg.lib {\$c}_pg/{\$d}.lib\nmv \$c/{\$d}*{\$c}.lib \$c/{\$d}.lib\nend\nend\nmodule load siliconsmart\n"; #nolint Backticks
my $WriteStatus3 = write_file(\@TFILE, "dir.sh");


my ($stdout1, $stderr1) = run_system_cmd  ("/bin/csh ./dir.sh", "$VERBOSITY");


my @cell_file = read_file($cell_list);
my @pvt_file = read_file($pvt_list);

for my $number (@pvt_file) {
chomp @cell_file;
chomp @pvt_file;
my $joining = join ' ',  @cell_file;


opendir(DIR, ".");
my @files = grep{/\_pg.lib$/} readdir(DIR);
closedir(DIR);     


opendir(DIR, ".");
my @files2 = grep{/c.lib$/} readdir(DIR);
closedir(DIR);     
 
     if (-e $files[0]) {
     push @OPFILE, "set cells {$joining}\nmerge -directory $number\_pg/ -output $out_lib_name\_$number\_pg.lib \$cells\nsource $RealBin/update_library_name.tcl\nrename_library_to_match_filename $out_lib_name\_$number\_pg.lib\nexec mv $out_lib_name\_$number\_pg.lib $out_lib_name\n";
     my $WriteStatus4 = write_file(\@OPFILE, "TEST.tcl");
     }
     
     if (-e $files2[0]){
     push @OPFILE, "set cells {$joining}\nmerge -directory $number/ -output $out_lib_name\_$number.lib \$cells\nsource $RealBin/update_library_name.tcl\nrename_library_to_match_filename $out_lib_name\_$number.lib\nexec mv $out_lib_name\_$number.lib $out_lib_name\n";
     my $WriteStatus5 = write_file(\@OPFILE, "TEST.tcl");
     }

}

opendir(DIR, ".");
my @files_2 = grep{/\_pg$/} readdir(DIR);
closedir(DIR);     
my ($stdout2, $stderr2) = run_system_cmd  ("/global/apps/siliconsmart_2019.06/bin/siliconsmart TEST.tcl;rm -rf *.lib;rm -rf char;rm -rf @pvt_file;rm -rf @files_2;rm -rf dir.sh;rm -rf TEST.tcl;/bin/csh ./dir1.sh;rm -rf dir1.sh;\nmv $out_lib_name/*_pg.lib $out_lib_name/lib_pg;\nmv $out_lib_name/*c.lib $out_lib_name/lib;\n\n\necho Updated liberty file can be found inside of $out_lib_name directory", "$VERBOSITY");

        #print("$stdout2\n\n");
	iprint("Liberty file merging is working. Updated liberty file can be found inside of $out_lib_name/lib and $out_lib_name/lib_pg directory.\n");

}

sub CheckRequiredArg
{
    my $ArgValue = shift;
    my $ArgName = shift;
    if (!defined $ArgValue)
    {
	eprint("Error:  Required argument \"$ArgName\" not supplied\n");
	return 0;
    }
    return 1;
}

sub CheckFileRead
{
    my $filename = shift;
    if (!(-r $filename))
    {
	eprint("Error: Cannot open $filename for read\n");
	return 0;
    }
    return 1;
}


sub ShowUsage
{
    my $ScriptPath = shift;
    iprint("Current script path:  $ScriptPath\n");
    pod2usage(0);

}


__END__

=head1 SYNOPSIS

    ScriptPath/liberty_marger.pl -cell_list <<cell_list>> -pvt_list <<PVT_LIST>> -out_lib_name <<output lib file name>>
    [-help \]
    [-h]
