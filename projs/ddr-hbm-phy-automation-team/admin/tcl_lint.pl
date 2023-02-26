#!/depot/perl-5.14.2/bin/perl
#############################################################################
#
# Name    : tcl_lint.pl
# Author  : James Laderoute
# Date    : June 7 2022
# Purpose : To do some checks to see that a tcl script conforms to our standard
#
# Modification History
#     000 James Laderoute  6/7/2022
#         Created this script
#
#
#############################################################################
use strict;
use warnings;

use Pod::Usage;
use File::Basename ;  # for filename parsing
use Cwd;              # for getpwuid
use English;          # English names in place of punctuation variables
use Getopt::Long;     # For command line parsing
use Carp  qw(cluck confess croak );
use FindBin qw( $RealBin $RealScript );

my $USERNAME = getlogin() || getpwuid($<) || $ENV{'USER'} ;

# assuming tcl_lint.pl is located in /admin
use lib "$RealBin/../perl/lib";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;

#---------------------------------------------------------------------------#
our $DEBUG = LOW;
our $VERBOSITY = 0;
our $PROGRAM_NAME = $RealScript;
our $VERSION = '2022ww35';
#---------------------------------------------------------------------------#
use constant IGNORE_COMMENTS => TRUE;
use constant DONOT_IGNORE_COMMENTS => FALSE;

sub Main() {
    my %opt_defaults = ( 'usage' => 1 );
    my @required = qw/REQUIRED_ARGUMENTS/;
    my @filenames = ();
    my @myoptions = ( 'short!', 'symlink!', 'source', 'debug:i', 'verbosity:i', 'usage!', 'man', 'help' );
    my %returned_options = ();

    my @COPY_ARGV = @ARGV;
    my $error = script_process_cmd_line_args( 
        \@myoptions, 
        \%returned_options, 
        \%opt_defaults, 
        \@required, 
        \@filenames
        );
    if ( exists($returned_options{'man'}) ){
        pod2usage( {
             -exitval => 0,
             -verbose => 2 });
    }
    
    my $n_filenames = @filenames;
    if ( $n_filenames == 0 ) {
        pod2usage(0);
    }
    if ( $returned_options{'usage'} ){
        &utils__script_usage_statistics($PROGRAM_NAME, $VERSION, \@COPY_ARGV);
    }
    my $total_fail=0;
    my $total_warn=0;

    #
    # Use our own tcl linting code to handle rules that other linters 
    # can't handle.
    #
    my $href_nolint;
    foreach my $fname (@filenames){
        # we dont' want to check scripts under the /releases/ folder, we only
        # care about scripts in the dev/ areas.
        next if ( $fname =~ m|/releases/| );
        # we dont' want to run lint on anything under the .git directory
        next if ( $fname =~ m|\.git/| ); 

        # collect LINT waiveres, i.e. " # nolint <waiver> "
        $href_nolint = tcl_nolint_checks( $fname );

        # Determine if $fname is a TCL module or a script
        my ($isScript, $isModule) = is_valid_tcl($fname);
        # Run DDR-HBM WG specific Checks
        my ($nfail, $nwarn) = tcl_script_checks( $fname, $isScript, $isModule, $href_nolint, 
                $returned_options{'source'} );
        $total_fail += $nfail;
        $total_warn += $nwarn;
    }


    #
    # Now do the real tcl linting using tool named 
    #
    foreach my $fname ( @filenames) {
        my ($lint_errs, $lint_warns) = run_nagelfar( $fname, $href_nolint );
        $total_fail += $lint_errs;
        $total_warn += $lint_warns;
    }

    if ( $n_filenames > 1 ){
        if ($total_fail > 0 ){
            print("\nFAILED: ");
        }else{
            print("\nPASSED: ");
        }

        print("tcl_lint: Files: $n_filenames Failed: $total_fail Warnings: $total_warn\n");
    }

    if ( $total_fail > 0 ) {
        exit(1);
    }
    
    exit(0);
}

sub is_valid_tcl($){
    my $filename      = shift;

    my $is_tcl_module = FALSE;
    my $is_tcl_script = FALSE;


    my ($fname, $fpath, $suffix) = fileparse( $filename, '\.tcl$' );

    $is_tcl_script = TRUE if ( $suffix eq '.tcl');
  
    # 99% of the time a tcl file will have an extension
    if ( $suffix eq '' ) {
        dprint(LOW, "File: '$filename' does not have a suffix.  fname='$fname' fpath='$fpath' suffix='$suffix'\n");
        # try and use the unix 'file' command to determine if this
        # might be a tcl script without the .tcl extension.
        my ($t_result, $exit_val) = run_system_cmd( "file $filename", NONE);
        if ( $exit_val == 0 ) {
            if ( $t_result =~ m/tclsh script|tcl8\..*script|wish script|Tcl script/ ){
                $is_tcl_script = TRUE;
            } elsif( $t_result =~ m/xxxx/ ){
                $is_tcl_module = TRUE;
            }
        } 
    }

    # note: look for tclPackage and see if this fname is in it somewhere; that
    # is how we know a .tcl file is a module or a script file
    if ( $fpath =~ m{(.*)tcl/Util} ){
        my $pkgIndex = $1 . "tcl/pkgIndex.tcl";
        if ( -e $pkgIndex ){
            my @content = read_file($pkgIndex);
            foreach my $line (@content){
                chomp $line;
                if ($line =~ m/$fname\.tcl\]/){
                    $is_tcl_script = FALSE;
                    $is_tcl_module = TRUE;
                    last; # jump out of foreach loop
                }
            }
        }
    }


    return($is_tcl_script, $is_tcl_module);
}

#
# This will run the negalfar tcl linter on the given tcl file
#
sub run_nagelfar($$) {
    my $filename    = shift;
    my $href_nolint = shift;

    my $nwarn=0;
    my $nerror=0;

    #my $exe     = "/global/freeware/Linux/RHEL7/nagelfar-132/nagelfar132.linux";
    my $exe     = "$RealBin/../ext-tools/nagelfar132/nagelfar.tcl";
    my $options = "";

    my ($stdout, $status) = run_system_cmd("$exe $options $filename", $VERBOSITY);
    if ( $status ) {
        eprint($stdout);
        return(1,0);
    }

    my @lines = split(/\n/, $stdout);
    foreach my $line ( @lines ) {
        my $skip = FALSE;
        next if ( $line =~ m/W\s+Unknown\s+command/);
        next if ( $line =~ m/E\s+Unknown\s+variable/);
        next if ( $line =~ m/W\sNo\sbraces\saround\sexpression\sin\sif\sstatement./);

        # check the NAGELFAR violation to see if it is waived
        # Oct 13, 2022 (juliano,alvaro) : Decision to only 
        #    obey waiver if a line # is included
        foreach my $waiver ( keys %$href_nolint ){
           if( $waiver =~ m/Line\s+\d+:/ && $line =~ m/$waiver/ ){
              $skip = TRUE;
              last;
           }
        }
        next if( $skip == TRUE );
        $nwarn++  if( $line =~ m/:\s+W\s+/ );
        $nerror++ if( $line =~ m/:\s+E\s+/ );
        print("$filename: $line\n");
    }


    return ($nerror,$nwarn);

}

#
# This looks for comments that say not to do the lint checks for some of 
# our DDR checks.  'nolint xyz'
#
sub tcl_nolint_checks($){
    my $filename = shift;
    my $aref_out = {};
    my @lines;

    if ( -e $filename ) {
        open my $handle, '<', $filename;
        chomp( @lines = <$handle> );
        close $handle;

	      # Oct 13, 2022 : (juliano,alvaro)
	      # LEGAL -> Example of a waiver for a specific violation for a specific line
	      # nolint Line 149: W Expr without braces
	      #
	      # Oct 13, 2022 : (juliano,alvaro)
	      # ILLEGAL -> Example of a waiver for a specific violation -- ALL lines in file
	      # nolint W Expr without braces
	      #
	      # Oct 13, 2022 : (juliano,alvaro)
	      # ILLEGAL -> Example of a waiver for a specific violation -- ALL lines in file
	      # nolint $perl_regex
        # 
        foreach my $line ( @lines ) {
            if ( $line =~ m/^\s*#\s*nolint\s+(.*)\s*$/ ){
                # $1 = waiver -- and can be a regex
                $aref_out->{"$1"} = 1;
            }
        }
    }
    return $aref_out;
}

sub tcl_script_checks($$;$){
    my $filename      = shift;
    my $is_tcl_script = shift;
    my $is_tcl_module = shift;
    my $href_nolint   = shift;
    my $is_source     = shift;

    my ($fname, $fpath, $suffix) = fileparse( $filename, '\.tcl$' );

    $is_tcl_module = $is_tcl_module || $is_source;

    if ( !$is_tcl_module && !$is_tcl_script) {
        hprint("SKIP: '$filename' This does not appear to be a tcl script or module. It has suffix '$suffix'\n");
        return(0,0); ;
    }

    my @lines;
    if ( $filename ){
        if ( ! -e $filename ){
            fatal_error( "Can not find File $filename\n" );
        }
        @lines = read_file( $filename );
    }

    print("---------------- $filename -----------------\n");
    
    my $failures = 0;
    my $warnings = 0;
    my $failed = 0;
    my $comment = '';

    if ( $is_tcl_script && !$is_tcl_module ) {

        if ( ! $href_nolint->{'check_tcl_version'} ) {
            ( $failed, $comment ) = &check_tcl_version( \@lines );
            if ( $failed == TRUE ) {
                $failures += 1;
                eprint("${filename}: ${comment}\n");
            }
        }

        if ( ! $href_nolint->{'Main'} ) {
            ( $failed, $comment) = &check_Main( \@lines );
            if ( $failed == TRUE ) {
                $failures += 1;
                eprint("${comment}\n");
            }
        }
    }


    ( $failed, $comment) = &check_use_alpha_common( \@lines );
    if ( $failed == TRUE ) {
        $warnings += 1;
        wprint("${filename}: ${comment}\n");
    }
 
    my $found_using_required;
    ( $found_using_required, $comment ) = &check_using_required_subs(
        $filename, $is_tcl_script, \@lines, $href_nolint );
    if ( $found_using_required == FALSE ) {
        $failures += 1;
        #eprint($comment);
    }
 
    iprint("Done  Failures: $failures  Warnings: $warnings\n");
 
    return ( $failures, $warnings);
}


sub check_Main($){
    my $aref_lines = shift;
    my $pattern = '^\s*proc\s+Main\s*';
    my $nlines = 400;

    my $not_found = &search_for_pattern_in_list( $pattern, $aref_lines, $nlines, 
        IGNORE_COMMENTS);
    return ($not_found, "Missing 'proc Main' within first $nlines lines of the code");
}

sub check_using_required_subs($$$$){
    my $filename = shift;
    my $is_tcl_script = shift;
    my $aref_lines = shift;
    my $href_nolint = shift;

    # Each key is the name of a subroutine. It points to an array that contains:
    #    [0] ~ TRUE|FALSE  TRUE if this is only for tcl-scripts and not for 
    #          tcl modules.
    #    [1] ~ The regular expression pattern to look for
    #
    my %patterns = ( 
        'utils__script_usage_statistics'=>[TRUE,'\s*&?utils__script_usage_statistics\s+'], 
    );

    my $all_required_subs_used = TRUE;

    for my $subname (keys(%patterns)){
        next if ( !$is_tcl_script && $patterns{$subname}[0]==TRUE);
        if ( ! $href_nolint->{"$subname"} ){

            my $not_found = &search_for_pattern_in_list( $patterns{$subname}[1], 
                $aref_lines, 0, IGNORE_COMMENTS);
            if ( $not_found == TRUE ){
                # the pattern was not FOUND but should have been
                $all_required_subs_used = FALSE;
                eprint( "${filename}: Required subroutine call '$subname' is missing\n" ); 
            }
        }
    }

    return ( $all_required_subs_used, "Missing required subroutine calls");
}


sub check_use_alpha_common($){
    my $aref_lines = shift;
    my $pattern = '/alpha_common/';

    my $not_found = &search_for_pattern_in_list( $pattern, $aref_lines, 0, 
        IGNORE_COMMENTS);
    return (! $not_found, "Found /alpha_common/");
}

sub check_tcl_version($){
    my $aref_lines = shift;
    my @good_patterns = (
        '/tclsh8\.5',
        '/tclsh',
        '/wish',
        '/bin/tclsh',
    );
    my $found;
    foreach my $pattern ( @good_patterns ) {
        $found |= ! &search_for_pattern_in_list( $pattern , $aref_lines , 4
        , DONOT_IGNORE_COMMENTS);
        
    }
    return (
        ! $found, 
        "Not using required version of Tcl. The valid version is one of @good_patterns"
    );
}

#
## Returns:
##     TRUE:  if the pattern searched for was NOT found
##     FALSE: if the pattern searched for WAS found
##
sub search_for_pattern_in_list($$$$){
    my $pattern = shift;
    my $aref_lines = shift;
    my $skip_after_n_lines = shift;
    my $ignore_comments = shift;

    my $not_found=TRUE;
    my $comment_pattern = '^\s*#\s*';

    my $lineno=0;
    foreach my $line ( @$aref_lines ) {
        if ( $ignore_comments == IGNORE_COMMENTS ) {
            next if ( $line =~ m/${comment_pattern}/ ); 
            # strip comments
            $line =~ s/#.*//g;
        }
        if ( $line =~ m/^\s*$/ ) {
            # skip blank lines
            #dprint(HIGH, "blank line found '$line'--------------------\n");
            next;
        }

        $lineno += 1;
        if ($skip_after_n_lines>0 && $lineno > $skip_after_n_lines) {
            last;
        }

        if ($line =~ m|${pattern}|) {
            $not_found = FALSE;
            last;
        }
    }
    return $not_found;
}


#------------------------------------------------------------------------------
sub script_process_cmd_line_args($$$$$){
    my $aref_args      = shift; # the options to be looked for
    my $href_options   = shift; # what the user selected gets put in here
    my $href_defaults  = shift; # if you did not specify a value then defaults
    my $aref_required  = shift; # list of required arguments
    my $aref_filenames = shift; # list of args not specified

    my $get_status = GetOptions( $href_options, @$aref_args);
    if ( ! $get_status || $href_options->{'help'} ){
        pod2usage(1);
    }

    foreach my $fname ( @ARGV ) {
        push( @$aref_filenames , $fname);
    }

    #
    # Make sure there are no missing REQUIRED arguments
    #
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
        pod2usage(0);
        return(0);
    }

    #
    # Set defaults
    #
    if ( $href_defaults) {
        foreach my $argname ( keys( %{$href_defaults} ) ){
            if ( ! exists( $href_options->{"$argname"} ) ){
                $href_options->{"$argname"} = $href_defaults->{"$argname"};
            }
        }
    }

   # VERBOSITY will be used to control the intensity level of 
   #     messages reported to the user while running.
   my $opt_verbosity = $href_options->{'verbosity'};
   if( defined $opt_verbosity ){
      if( $opt_verbosity =~ m/^\d+$/ ){  
         $main::VERBOSITY = $opt_verbosity;
      }else{
         eprint( "Ignoring option '-v': arg must be an integer\n" );
      }
   }

   # decide whether to alter DEBUG variable
   # '--debug' indicates DEBUG value ... set based on user input
   # Patrick : modified in order to specify a value >0 but <1
   my $opt_debug = $href_options->{'debug'};
   if( defined $opt_debug ){
      if( $opt_debug =~ m/^\d+\.*\d*$/ ){
         $main::DEBUG = $opt_debug;
      }else{
         eprint( "Ignoring option '-d': arg must be an integer\n" );
      }
   }

   return(0); ## success is 0

}

Main();


__END__


=head1 NAME

 tcl_lint

=head1 VERSION

 2022ww10

=head1 SYNOPSIS

 tcl_lint [options] [file ...]

 Options:
   -help            brief help message
   -man             full documentation

 This script checks the given tcl files to make sure that they are
 following the tcl code best practice rules.

=head1 OPTIONS

=over 8

=item B<-debug number>

Set a debug level, in order to control debug messages.

=item B<-verbose number>

Set the verbosity level on messages.

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

This script checks the given tcl files to make sure that they are
following the tcl code best practice rules.

=head1 RETURN VALUE

Returns 0 if there are no warnings or errors
Returns 1 if there are warnings or errors

=cut
