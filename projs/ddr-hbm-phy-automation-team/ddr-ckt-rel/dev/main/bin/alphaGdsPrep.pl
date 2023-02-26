#!/depot/perl-5.14.2/bin/perl
use strict;
use warnings;
use Capture::Tiny qw/capture/;
use Getopt::Long;  # GetOptions
use File::Basename;
use File::Copy;
use Carp qw(cluck confess croak);
use Cwd 'abs_path';
use Cwd 'fast_abs_path';
use Cwd 'realpath';
use Cwd 'getcwd';
use Pod::Usage;

use FindBin qw($RealBin $RealScript);
use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;

#--------------------------------------------------------------------#
our $STDOUT_LOG; # Initiailized in the BEGIN block
our $DEBUG        = NONE;
our $TESTMODE     = NONE;
our $VERBOSITY    = NONE;
our $PROGRAM_NAME = $RealScript;
our $LOGFILENAME = getcwd() . "/$PROGRAM_NAME.log";

our $VERSION      = '2022.10';
#--------------------------------------------------------------------#

BEGIN{
    our $AUTHOR='clouser, ljames';
    #$STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
    $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
    header();
}
&Main();
END{
    local $?;
    footer();
    write_stdout_log( $LOGFILENAME );
}

my $tmpDir = "";

my $strict_leading_dot    = 0;
my $strict_wildcard_slash = 0;

#-------------------------------------------------
sub Main() {
    my @orig_argv = @ARGV;

    logger( pretty_print_aref( \@ARGV ));
    logger( "\n" );

    ShowUsage( $RealBin, 1 ) unless(@ARGV);

    my %options = ();
    my %defaults = (
          "tagLevel" => 0    ,
          "tagAlign" => 'sw' ,
          "useTmp"   => 1    ,
          "debug"    => 0    ,
        );
    my @required = qw/REQUIRED_ARGUMENTS/;

    process_cmd_line_args( \%options, \%defaults, \@required);

    my $now = localtime;
    my $gds = $options{gds};

    my $fileOK = 1;
    $fileOK &= myAbsPath(\$gds   , "in", "Input GDS");
    $fileOK &= myAbsPath(\$options{'fltf'}  , "in", "fltf");
    $fileOK &= myAbsPath(\$options{'rfltf'} , "in", "rfltf");
    $fileOK &= myAbsPath(\$options{'gfltf'} , "in", "gfltf");
    $fileOK &= myAbsPath(\$options{'output'}, "out", "Output GDS");
    if (!$fileOK) {
        iprint "Aborting. Failed file checks for one of gds, fltf, rfltf, gfltf or output.\n";
        exit(2);
    }

    my $macro = $options{'macro'};

    if ( ! defined $macro ){
        if ( $gds =~ /([^\/]+)\.gds/ ){
            $macro = $1;
        }else{
            confess "Error:  Cannot determine macro name\n";
        }
    }

    if ( (defined $options{'rfltf'}) && (defined $options{'gfltf'}) ){
        eprint "Cannot use both rfltf and gfltf\n";
        exit(3);
    }

    my $prefix = $options{'prefix'};
    if (!(defined $prefix)){
        $prefix = "${macro}_";
    }

    unless( $options{'nousage'} ){
        utils__script_usage_statistics( $RealScript, $VERSION, \@orig_argv);
    }

    my $gdsSuffix = "gds";

    $gds = abs_path($gds);
    my ($stdout_err, $file_status) = run_system_cmd("file $gds");
    my @o = split(/\n/, $stdout_err);
    my $inCompressed = 0;
    if ( $o[0] =~ /gzip compressed data/ ){
        $gdsSuffix = "gds.gz";
        $inCompressed = 1;
    }

    my $thisDir = abs_path("./");
    $now = time();

    my $USERNAME  = get_username();
    $tmpDir = "/tmp/alphaGdsPrep_${macro}_${USERNAME}_$now";
    if ( $options{'useTmp'} ){
        mkdir $tmpDir;
        if ( (-e $tmpDir) || (-d $tmpDir) ){
            chdir $tmpDir;
            iprint "Working in $ENV{HOST}:$tmpDir\n";
        }else{
            wprint "Could not create $tmpDir; Working locally\n"
        }
    }

    iprint( "gds = $gds");
    if ($inCompressed) {
        nprint ", compressed\n";
        my ($out, $err) = run_system_cmd("gunzip -c $gds > $macro.gds", $main::DEBUG);
        $gds = "$macro.gds"
    }else{
        nprint ", uncompressed\n";
    }

    my $output = $options{'output'};
    iprint "macro = $macro\n";
    iprint "prefix = \"$prefix\"\n";
    my $outCompressed;
    if (defined $output) {
        if ( $output =~ /\.gds$/ ){
            ##  A simple, uncompressed gds
            $outCompressed = 0;
        } elsif ( $output =~ /\.gds\.gz$/ ){
            ##  A simple, compressed gds
            $outCompressed = 1;
        } elsif ( $output =~ /\.gz$/ ){
            ##  Probably compressed.
            $outCompressed = 1;
        } else {
            ## Not sure what it is.  Assume uncompressed
            $outCompressed = 0;
        }
    }else{
        ##  No output specified.  Used default name, and compress if input was compressed
        $output = "$thisDir/$macro.prepped.$gdsSuffix";
    #    $output = abs_path($output);
        $outCompressed = $inCompressed;
    }

    my @t = split(/\//, $output);
    my $outRoot = pop @t;
    my $outPath = join("/", @t);

    my $outCompressedTag = ($outCompressed) ? "compressed" : "uncompressed";
    iprint "output = $output, $outCompressedTag\n";

    if ( ! ( -e $outPath ) ){
        ##  Output directory doesn't exist.
        eprint "Output directory '$outPath' does not exist\n";
        exit(4);
    } elsif ( ! (-d $outPath) ){
        ##  Output directory isn't a directory
        eprint "Output directory $outPath is not a directory\n";
        exit(5);
    }

    ##  Check prefix for illegal characters
    if ( $prefix =~ /([^a-zA-Z0-9_\?\$])/ ){
        ##  Some illegal character found
        eprint "Prefix \"$prefix\" contains an illegal character \"$1\"\n";
        exitGracefully();
    }

    #print "Info:  Checking for presence of cell \"$macro\" in gds:  ";
    #my @o = doCommand("msip_layTree -f  $gds", "cellExists");
    #
    #my $found = 0;
    #foreach (@o) {
    #    if (/^\s*$/) {next}
    #    if (/Defined Structures/) {next}
    #    if (/^\s*$macro\s*$/) {
    #    ##  Found the cell
    #    $found = true;
    #    last;
    #    }
    #}
    #
    #if (!$found) {
    #    print "Error:  Cell $macro not found in $gds\n";
    #    exitGracefully();
    #}

    iprint "Checking for illegal characters in cell names:  ";
    @o = doCommand("gds_characters_check $gds", "charCheck_$macro");
    vhprint(LOW, "gds_characters_check output is '@o'\n");
    my @cellRenames;
    foreach my $line (@o) {
        if ($line =~ /SNPS_ERROR  : GDS cell name \'(\S+)\' contains non-GDS characters \'(\S+)\'/) {
            my $cellName    = $1;
            my $badChar     = quotemeta $2;
            my $newCellname = $cellName;
            $newCellname    =~ s/$badChar/_/g;

            push @cellRenames, "$cellName $newCellname\n";
        }
    }

    if (@cellRenames > 0){
        iprint "Remapping illegal characters in cell names\n";
        foreach (@cellRenames) {nprint "\t$_"}
        my $mapFile = "$macro.map.tmp";
        write_file( \@cellRenames, $mapFile);
        my @out = doCommand("gds_namemap -map $mapFile $macro $gds $macro.remapped.gds"
            , "remap_${macro}");
        vhprint(LOW, "gds_namemap output is '@out'\n");
        unlink( $mapFile             ) unless( $DEBUG );
        unlink( "$macro.gds_name.map") unless( $DEBUG ); 
    }else{
        iprint "No illegal characters found\n";
        copy($gds, "$macro.remapped.gds");
    }

    iprint "Prefixing:  ";
    my $gfltf = $options{'gfltf'};
    my $rfltf = $options{'rfltf'}; # if gfltf is defined then this will be undef
    if ( defined $gfltf ){
        ##  Have a glob-pattern filter file.
        if ( ! ( -r $gfltf ) ){
            eprint "Cannot open $gfltf for read\n";
            exit(6);
        }

        # Construct rfltf from gfltf
        my $basename = basename($gfltf);
        $rfltf = "$basename.regex";
        my @lines = read_file( $gfltf );
        my @output;
        foreach my $line ( @lines ){
            $line =~ s/\#.*//;     ##  Uncomment  #.*
            $line =~ s/\/\/.*//;   ##  Uncomment  //.*
            my @t = Tokenify($line);
            foreach my $p (@t) {
                my $rp = glob_to_regex_string($p);
                push(@output, "$rp\n");
            }
        }
        write_file( \@output, $rfltf );
    }

    my $fltf   = $options{'fltf'};
    my $rfltfS = "";
    my $fltfS  = "";
    if (defined $rfltf) {
        $rfltfS = "-rfltf $rfltf";
    }
    if (defined $fltf) {
        $fltfS = "-fltf $fltf";
    }

    my @namemap_output = doCommand("gds_namemap -pre $prefix $rfltfS $fltfS $macro $macro.remapped.gds $macro.prefixed.gds"
        , "prefix_${macro}");
    vhprint(LOW, "gds_namemap command returned: '@namemap_output'\n");
    if (defined $gfltf){
        ##  rfltf came from a gfltf arg.  Delete it.
        if ( ! $DEBUG  && defined $rfltf){
            unlink $rfltf;
        }
    }
    unlink( "$macro.remapped.gds" ) unless( $DEBUG);

    if ( -e "$macro.prefixed.gds" ){
        my $lvlFile = "${macro}_vs_${macro}.LVL_ERRORS";
        if ( -e $lvlFile ){
            my @lines = read_file( $lvlFile );
            my $line  = shift(@lines);
            if( $line =~ /LVL ERRORS RESULTS: CLEAN/ ){
                ##  LVL passed
                iprint "LVL passed\n";
                unlink( $lvlFile ) unless( $DEBUG );
            }else{
                wprint "LVL failed\n";
            }
        }else{
            confess "Error:  LVL file missing\n";
        }
    }else{
        confess "Error:  Prefixing failed. Unable to find file '$macro.prefixed.gds'\n";
    }

    iprint "Remapping brackets:  ";

    my @out = doCommand("msip_layReplaceBrackets $macro.prefixed.gds -keepGDS -o $macro.prefixed_BracketReplaced.gds"
        , "rebracket_${macro}");
    vhprint(LOW, "doCommand msip_layReplaceBrackets returned '@out'\n");
    if ( $main::DEBUG > LOW ) {
        foreach my $line ( @out ) {
            dprint(LOW, $line);
        }
    }

    if ( exists $out[1] ) {
        if ( $out[1] =~ /Did not find anything/ ){
            iprint( "Rebracket did not find anything\n");
            my ($out, $err) = run_system_cmd( "cp -f $macro.prefixed.gds $macro.prefixed_BracketReplaced.gds", $main::DEBUG);
        }
    }

    if ( ! ( -e "$macro.prefixed_BracketReplaced.gds" ) ){
        confess "Error: msip_layReplaceBrackets failed. File '$macro.prefixed_BracketReplaced.gds' does not exist!\n";
    } else {
        unlink( "$macro.prefixed.gds" ) unless( $DEBUG );
    }

    iprint "Removing empty cells:  ";
    @out = doCommand("msip_layDeleteEmptyCells $macro.prefixed_BracketReplaced.gds -o $macro.prefixed_BracketReplaced_noEmpty.gds"
         , "delEmpty_${macro}");
    vhprint(LOW, "msip_layDeleteEmptyCells returned '@out'\n");
    ##  msip_layDeleteEmptyCells handles gzipped gds's, but fouls up the output name.
    #if ($inCompressed) {rename "$macro.prefixed_BracketReplaced_noEmpty.gds", "$macro.prefixed_BracketReplaced_noEmpty."}
    if ( -e "$macro.prefixed_BracketReplaced_noEmpty.gds" ){
        unlink( "msip_layDeleteEmptyCells.log"       ) unless( $DEBUG );
        unlink( "$macro.prefixed_BracketReplaced.gds" ) unless( $DEBUG );
    }else{
        eprint "msip_layDeleteEmptyCells failed\n";
        exit(7);
    }

    my $tagFile  = $options{'tagFile'};
    my $tagLevel = $options{'tagLevel'};
    my $tagAlign = $options{'tagAlign'};
    my $tagTsmc  = $options{'tsmc'};
    my $tagLayer = $options{'tagLayer'};
    my $bndLayer = $options{'bndLayer'};

    if ( defined $tagFile ){
        ##  Adding a tag
        my $tagCommand = "msip_layGdsTagger $macro.prefixed_BracketReplaced_noEmpty.gds -out $macro.prefixed_BracketReplaced_noEmpty_tagged.gds -tag $tagFile -level $tagLevel -align $tagAlign";
        if (defined $tagTsmc)  { $tagCommand .= " -tsmc"}
        if (defined $tagLayer) { $tagCommand .= " -layer $tagLayer"}
        if (defined $bndLayer) { $tagCommand .= " -metricBndLayer $bndLayer"}
        iprint "Tagging:  ";
        my @out = doCommand($tagCommand, "tag_${macro}");
        vhprint(LOW, "msip_layGdsTagger command returned output '@out'\n");
    }else{
        ##  Not tagging.
        rename "$macro.prefixed_BracketReplaced_noEmpty.gds", "$macro.prefixed_BracketReplaced_noEmpty_tagged.gds";
    }

    if ( -e "$macro.prefixed_BracketReplaced_noEmpty_tagged.gds" ){
        unlink( "$macro.prefixed_BracketReplaced_noEmpty.gds" ) unless( $DEBUG );
        
        if ($outCompressed) {
            my ($out, $err) = run_system_cmd( "gzip $macro.prefixed_BracketReplaced_noEmpty_tagged.gds", $main::DEBUG);
            ($out, $err)    = run_system_cmd( "mv -f $macro.prefixed_BracketReplaced_noEmpty_tagged.gds.gz $output", $main::DEBUG);
        }else{
            my ($out, $err)  = run_system_cmd( "mv -f $macro.prefixed_BracketReplaced_noEmpty_tagged.gds $output", $main::DEBUG);
        }
    }else{
        #    print "Error: msip_layGdsTagger failed\n";
        eprint "msip_layGdsTagger failed";
    }

    run_system_cmd( "rm -rf $tmpDir" ) unless( $DEBUG );
    exit(0);
} # end of Main()

#-------------------------------------------------
sub doCommand($$){
    my $cmd = shift;
    my $id  = shift;
    my $now = localtime;
    my $cwd = getcwd();

    iprint "[$now] '$cmd' id='$id'\n";
    vhprint(LOW, "doCommand: current working dir is '$cwd'\n");

    my $script = "$id.csh";
    my @SCR;
    push(@SCR, "#!/bin/csh\n" );
    push(@SCR, "module unload msip_shell_rename\n" );
    push(@SCR, "module load msip_shell_rename/2022.03\n" ); #P10020416-35208
    push(@SCR, "module unload msip_lynx_hipre\n" );
    push(@SCR, "module load msip_lynx_hipre\n" );
    push(@SCR, "module unload msip_shell_lay_utils\n" );
    push(@SCR, "module load msip_shell_lay_utils\n" );
    push(@SCR, "\n" );
    push(@SCR, "$cmd\n" );
    write_file( \@SCR, $script );
    
    vhprint(LOW, "doCommand: Created file '$script'\n");
    if ( ! -e $script ) {
        eprint("'$script' File does not exist!\n");
    } else {
        if ( $main::DEBUG >= LOW ){
            my ($stdout_err, $cat_status) = run_system_cmd("pwd; cat $script");
            my @x = split(/\n/, $stdout_err);
            dprint(LOW, "Doing: pwd; cat $script\n");
            dprint(LOW, "@x");
        }
    }

    my @output;
    if ( $main::TESTMODE ){
        hprint("TESTMODE: chmod +x $script; ./$script");
        push( @output, "$TESTMODE: $script did not get run");
    }else{
        # Note: chmod +x $script will add the execute bit on owner, group and other
        my ($out1, $err1) = run_system_cmd( "chmod +x $script", $main::DEBUG );
        if ( $err1 ) {
            eprint("Unabled to change permission on '$script'\n");
            eprint($out1);
        }
        my ($out2, $err2) = run_system_cmd( "./$script", $main::DEBUG);
        if ( $err2 ) {
            eprint("Failed to succesfully run './$script' !\n");
            push(@output, split(/\n/,$out2));
        } else {
            push(@output, split(/\n/, $out2));
        }
        # @output = `chmod +x $script; ./$script`;
    }
    unlink( $script ) unless( $DEBUG );
    if( 0 == @output ){
        push(@output, "NO OUTPUT from running $script");
    }

    return @output;
}

#-------------------------------------------------
sub ShowUsage($$) {
    my $script_path = shift;
    my $status      = shift;

    iprint "Current script path: '$script_path'\n";
    pod2usage({
            -pathlist => "$RealBin",
            -exitval => $status,
            -verbose => 1 });
}

#-------------------------------------------------
sub Tokenify($){
    ## Splits, stripping leading and trailing whitespace first to get clean tokens
    my $line = shift;

    $line =~ s/^\s+?(.*)\s+$/$1/;
    $line =~ s/\s*=\s*/=/g;   ## Strip any whitespace around "=" signs.  Makes later parsing easier.
    return split(/\s+/, $line);
}


#-------------------------------------------------
sub glob_to_regex_string($){
    my $glob = shift;

    if ($glob eq "") {return ""}  ##  Preserve empty string
    my ($regex, $in_curlies, $escaping);
    local $_;
    my $first_byte = 1;
    for ($glob =~ m/(.)/gs) {
        if ($first_byte) {
            if ($strict_leading_dot) {
                $regex .= '(?=[^\.])' unless $_ eq '.';
            }
            $first_byte = 0;
        }
        if ($_ eq '/') {
            $first_byte = 1;
        }
        if ($_ eq '.' || $_ eq '(' || $_ eq ')' || $_ eq '|' ||
            $_ eq '+' || $_ eq '^' || $_ eq '$' || $_ eq '@' || $_ eq '%' ) {
            $regex .= "\\$_";
        } elsif ($_ eq '*') {
            $regex .= $escaping ? "\\*" :
                      $strict_wildcard_slash ? "[^/]*" : ".*";
        } elsif ($_ eq '?') {
            $regex .= $escaping ? "\\?" :
                      $strict_wildcard_slash ? "[^/]" : ".";
        } elsif ($_ eq '{') {
            $regex .= $escaping ? "\\{" : "(";
            ++$in_curlies unless $escaping;
        } elsif ($_ eq '}' && $in_curlies) {
            $regex .= $escaping ? "}" : ")";
            --$in_curlies unless $escaping;
        } elsif ($_ eq ',' && $in_curlies) {
            $regex .= $escaping ? "," : "|";
        } elsif ($_ eq "\\") {
            if ($escaping) {
                $regex .= "\\\\";
                $escaping = 0;
            } else {
                $escaping = 1;
            }
            next;
        } else {
            $regex .= $_;
            $escaping = 0;
        }
        $escaping = 0;
    }
#    print "# $glob $regex\n" if debug;

    $regex = "^$regex\$";   ##  Need to match entire string
    return $regex;
}

#-------------------------------------------------
sub myAbsPath($$$){
    my ($file, $type, $id) = @_;

    ##  $file is a reference; returns abs_path to the same spot.
    
    $type = lc $type;
    if ( ! (defined $$file) ){
        return 1;
    }

    if ($type eq "in") {
        ##  File would be expected to exist.
        if ( -e $$file ){
            $$file = abs_path($$file);
            iprint "$id:  '$$file'\n";
            return 1;
        } else {
            eprint "$id '$$file' does not exist\n";
            $$file = undef;
            return 0;
        }
    }

    if ($type eq "out") {
        ##  File may or may not exist, but path should
        my $fileFull = abs_path($$file);
        if ($fileFull eq ""){
            eprint "Output path for $id '$$file' does not exist\n";
            return 0;
        }else{
            ##  All good.
            $$file = $fileFull;
            iprint( "$id  '$$file'\n");
            return 1;
        }
    }
}

#-------------------------------------------------
sub process_cmd_line_args($$$){
    my $href_options  = shift;
    my $href_defaults = shift;
    my $aref_required = shift;

    my $get_status = GetOptions($href_options, 
        "gds=s"      , 
        "macro=s"    , 
        "prefix=s"   , 
        "output=s"   ,  
        "rfltf=s"    , 
        "gfltf=s"    , 
        "fltf=s"     , 
        "tagFile=s"  , 
        "tagLevel=i" , 
        "tagAlign=s" ,
        "bndLayer=s" , 
        "tsmc"       , 
        "tagLayer=s" , 
        "tmp!"       , 
        'testmode'   ,
        'nousage'    ,
        'verbosity=i',
        'debug=i'    ,
        'help'
    );

    if( $href_options->{'help'} ){
        dprint(LOW, "get_status=$get_status");
        ShowUsage( $RealBin, 0 );
    }

    if( ! defined $href_options->{'gds'} ){
        ShowUsage( $RealBin, 1 );
    }

    if( ! $get_status ) {
        dprint(LOW, "get_status=$get_status");
        ShowUsage( $RealBin, 1 );
    }
    
    #-------------------------------
    # Make sure there are no missing REQUIRED arguments
    my $have_required = 1;
    foreach my $argname ( @{$aref_required} ){
        next if $argname eq "REQUIRED_ARGUMENTS";
        if (   ! exists($href_options->{"$argname"} ) 
            || ! defined($href_options->{"$argname"} ) ){
            $have_required = 0;
            eprint( "Missing Required Argument -$argname\n" );
        }
    }
    if ( ! $have_required ){
        dprint(LOW, "! have_required ");
        ShowUsage( $RealBin, 1 );
    }

    #------------------------------
    # Set defaults
    foreach my $argname ( keys( %{$href_defaults} ) ){
        $href_options->{"$argname"} = $href_defaults->{"$argname"}
                unless( defined $href_options->{"$argname"}  && exists( $href_options->{"$argname"} ) );
   }

   $main::DEBUG     = $href_options->{'debug'}     if( defined $href_options->{'debug'}     );
   $main::VERBOSITY = $href_options->{'verbosity'} if( defined $href_options->{'verbosity'} );
   $main::TESTMODE  = $href_options->{'testmode'}  if( defined $href_options->{'testmode'}  );

   return(0); ## success
};


__END__
=head1 SYNOPSIS

    ScriptPath/alphaGdsPrep.pl -gds <gdsfile> \
    [-macro <MACRO> \]
    [-prefix <prefix> \]
    [-output <output-gds> \]
    [-rfltf <file> \]
    [-gfltf <file> \]
    [-fltf <file> \]
    [-tagFile <tag-file> \]
    [-tagLevel <0|1> \]
    [-tagAlign <c|nw|n|ne|e|se|s|sw|w> \]
    [-bndLayer <layer> \]
    [-tsmc \]
    [-tagLayer <tag-layer> \]
    [-debug <integer> \]
    [-nousage \]
    [-testmode \]
    [-verbosity <integer> \]
    [-h,-help]


This script is designed to execute the steps required to prepare a raw gds for a release.  All steps are performed with msip-standard scripts; this just wraps all into
a single, easy-to-run package.  The steps include:

=item B<Illegal characters:>

Checks for illegal characters in structure names. (msip_lynx_hipre/gds_characters_check).  If illegal characters are detected, they're replaced with "_" using msip_shell_rename/gds_namemap.

=item B<Prefixing>

All cells, other than the top, and those specified with the rfltf, gfltf and fltf options are prefixed.  The prefix used is the toplevel cellName, or the prefix provided with the -prefix option

=item B<Bracket remapping>

"<>" brackets are replaced with "[]" using msip_shell_lay_utils/msip_layReplaceBrackets

=item B<Empty cell removal>

Empty cells are removed using msip_shell_lay_utils/msip_layDeleteEmptyCells

=item B<Tagging>

A gds tag is added using msip_shell_lay_utils/msip_layGdsTagger.  This is optional, and triggered by the presence of the tagFile command-line option.

=head1 ARGUMENTS

=item B<-gds>

The only argument is the name of the input gds file.  Required.

=head1 OPTIONS

=item B<-macro>

The name of the macro, presumed toplevel structure in the gds.  Used by default as the prefix.  If not specified, the input gds name is assumed to be $macro.gds.

=item B<-prefix>

The prefix to be used.  If not provided, ${macro}_ is used.

=item B<-output>

The name of the output gds file.  If not provided, "$macro.prepped.gds" is used.

=item B<-rfltf>

Give a filter file of cell regexp patterns that will be ignored for prefixing. (See msip_shell_rename/gds_namemap -rfltf). Cannot use with -gfltf.

=item B<-gfltf>

Give a filter file of cell glob patterns that will be ignored for prefixing. Cannot use with -rfltf.

=item B<-fltf>

Give a filter file of cell names that will be ignored for prefixing. (See msip_shell_rename/gds_namemap -fltf)

=item B<-tagFile>

The file containing the tag information to be added.  If not supplied, no tagging is done. (See msip_shell_lay_utils/msip_layGdsTagger -tag)

=item B<-tagLevel>

Defines the hierarchy level on which to place the tag.  For simple, single-structure gds's, this will generally be 0.  For gds's containing multiple structures, this will generally be 1.  
(See msip_shell_lay_utils/msip_layGdsTagger -level)

=item B<-tagAlign>

<c|nw|n|ne|e|se|s|sw|w>: Set the text alignment for tags. Default alignment is 'sw' (See msip_shell_lay_utils/msip_layGdsTagger -align)

=item B<-tagLayer>

Specifies the layer on which the tag should be placed.  The default is 63:63.  (See msip_shell_lay_utils/msip_layGdsTagger -layer)

=item B<-bndLayer>

Defines the boundary layer for metric calculation. (See msip_shell_lay_utils/msip_layGdsTagger -metricBndLayer)

=item B<-tsmc>

Applicable to tagging, indicates that the gds is for a tsmc process, and adds the tag on layer 6:0, in addition to the default layer, or whatever is specified with -layer.    
(See msip_shell_lay_utils/msip_layGdsTagger -tsmc)

=item B<-useTmp>

Use an area in /tmp to work in.

=item B<-debug> 
    Enable internal debug setting. 
    This -debug just prevents files from getting removed that would 
    normally be removed as part of the cleanup work. This allows the files
    to hang around so you can examine them.
    Set debug level, used with dprint() calls

=item B<-verbosity> 
    Verbosity level

=item B<-testmode> 
    Enable test mode

=item B<-h,-help>

Prints this usage info.

