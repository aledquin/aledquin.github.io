#!/depot/perl-5.14.2/bin/perl
#############################################################################
#
# Name    : python_lint.pl
# Author  : James Laderoute
# Date    : July 18 2022
# Purpose : To some checks to see that a python script conforms to our standard
#
# Modification History
#     000 James Laderoute  7/18/2022
#         Created this script
#     001 James Laderoute 10/17/2022
#         Add option -[no]symlink
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
use Capture::Tiny qw/capture/;

my $USERNAME = getlogin() || getpwuid($<) || $ENV{'USER'} ;

# assuming python_lint.pl is located in /admin
use lib "$RealBin/../perl/lib";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;

#---------------------------------------------------------------------------#
our $DEBUG = LOW;
our $VERBOSITY = 0;
our $PROGRAM_NAME = $RealScript;
our $VERSION = '2022ww30';
#---------------------------------------------------------------------------#
use constant IGNORE_COMMENTS => TRUE;
use constant DONOT_IGNORE_COMMENTS => FALSE;

sub Main() {
    my %opt_defaults = ( 'usage' => 1 );
    my @required = qw/REQUIRED_ARGUMENTS/;
    my @filenames = ();
    my @myoptions = ( 'debug:i', 'verbosity:i', 'usage!', 'man', 'help', 'short!', 'symlink!' );
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
    my $total_flake=0;

    my $interpreter = "/depot/Python/Python-3.8.0/bin/python";
    my $flake8_config = "$RealBin/../.flake8";

    foreach my $fname (@filenames){
        # we dont' want to check scripts under the /releases/ folder, we only
        # care about scripts in the dev/ areas.
        next if ( $fname =~ m|/releases/| );
        # we dont' want to run lint on anything under the .git directory
        next if ( $fname =~ m|\.git/| ); 

        my $href_nolint = python_nolint_checks( $fname );

        # Run DDR-HBM WG specific Checks
        my ($std_out, $nfail, $nwarn) = python_script_checks( $fname, $href_nolint );
        $total_fail += $nfail;
        $total_warn += $nwarn;
        if ( $nfail || $nwarn ) {
            print("DDRLINT:\n$std_out\n")
        }

        # Run Python linter checks        
        my ($std_out_err, $return_val) = python_flake8_checks( $fname, $interpreter, $flake8_config );
        if ( $return_val ){
            $total_flake += 1;
            print("FLAKE8:\n$std_out_err\n");
        } 
    }

    my $grand_total = $total_fail + $total_flake;
    if ( ($grand_total) > 0 ) {
        exit(1);
    }
    
    exit(0);
}

#
# This looks for comments that say not to do the lint checks for some of 
# our DDR checks.  'nolint xyz'
#
sub python_nolint_checks($){
    my $filename = shift;
    my $aref_out = {};
    my @lines;

    if ( -e $filename ) {
        open my $handle, '<', $filename;
        chomp( @lines = <$handle> );
        close $handle;

        foreach my $line ( @lines ) {
            if ( $line =~ m/^\s*#\s*nolint\s+(.*)\s*$/ ){
                $aref_out->{"$1"} = 1;
            }
        }
    }
    return $aref_out;
}

# ========================== #
# Flake 8 checks
# ========================== #

sub python_flake8_checks($$$) {

    my $fname = shift;
    my $interpreter = shift;
    my $flake8_config = shift;    

    my $PYTHON = $interpreter;

    if ( ! -e $flake8_config ) {
        eprint ("Could not find configuration file: $flake8_config\n");
        return 1;
    }    
    my $lint_cmd = "$PYTHON -m flake8 $fname --config  $flake8_config";
    
    my ($std_out_err, $ret) = run_system_cmd($lint_cmd, $VERBOSITY);    

    return($std_out_err, $ret);
   
}

# ========================== #
# Main Python Checker
# ========================== #

# Returns:
#   error_text,  nerrors,  nwarnings
#
sub python_script_checks($$){
    my $filename    = shift;
    my $href_nolint = shift;
    
    my ($fname, $fpath, $suffix) = fileparse( $filename, '\.py$' );
    my $is_python_module = FALSE;
    my $is_python_script = FALSE;

    $is_python_script = TRUE if ( $suffix eq '.py');
    if ( $suffix eq '' ) {
        dprint(LOW, "File: '$filename' does not have a suffix.  fname='$fname' fpath='$fpath' suffix='$suffix'\n");
        # try and use the unix 'file' command to determine if this
        # might be a python script without the .py extension.
        my ($t_result, $exit_val) = run_system_cmd( "file $filename", NONE);
        if ( $exit_val == 0 ) {
            if ( $t_result =~ m/Python/ ){
                $is_python_script = TRUE;
            } elsif( $t_result =~ m/xxxx/ ){
                $is_python_module = TRUE;
            }
        }
    }

    # If this script is located under /Util; then we can assume it's a module
    if ( $fpath =~ m/Util/){
        $is_python_script = FALSE;
        $is_python_module = TRUE;
    }

    if ( !$is_python_module && !$is_python_script) {
        hprint("SKIP: '$filename' This does not appear to be a python script or module. It has suffix '$suffix'\n");
        return(0,0); ;
    }

    my @lines;
    if ( $filename ){
        if ( ! -e $filename ){
            fatal_error( "Can not find File $filename\n" );
        }
        open my $handle, '<', $filename;
        chomp( @lines = <$handle> );
        close $handle;
    }

    my $failures = 0;
    my $warnings = 0;
    my $failed = 0;
    my $comment = '';

    # ========================== #
    # Python QA Check Version and Main
    # ========================== #

    my $std_out = "";

    if ( $is_python_script ) {

        if ( ! $href_nolint->{'check_python_version'} ) {
            ( $failed, $comment ) = &check_python_version( \@lines );
            if ( $failed == TRUE ) {
                $failures += 1;
                $std_out .= "-E- ${comment}\n";
            }
        }
        if ( ! $href_nolint->{'main'} ) {
            ( $failed, $comment) = &check_Main( \@lines );
            if ( $failed == TRUE ) {
                $failures += 1;
                $std_out .= "-E- ${comment}\n";
            }
        }
    }

    # ========================== #
    # Python QA Check Alpha_common Usage
    # ========================== #

    ( $failed, $comment) = &check_use_alpha_common( \@lines, $href_nolint );
    if ( $failed == TRUE ) {
        $warnings += 1;
        $std_out .= "-W- ${comment}\n";
    }
 
    # ========================== #
    # Python QA Check using required subs
    # ========================== #

    my $found_using_required;
    ( $found_using_required, $comment ) = &check_using_required_subs(
        $is_python_script, \@lines, $href_nolint );
    if ( $found_using_required == FALSE ) {
        $failures += 1;
        #eprint($comment);
    }
 
#    iprint("Done  Failures: $failures  Warnings: $warnings\n");
 
    return ( $std_out, $failures, $warnings);
}

# ========================== #
# DDR-HBM Specific Checks
# ========================== #

sub check_Main($){
    my $aref_lines = shift;
    my $pattern = '^\s*def\s+[Mm]ain\s*';
    my $nlines = 200;

    my $not_found = &search_for_pattern_in_list( $pattern, $aref_lines, $nlines, 
        IGNORE_COMMENTS);
    return ($not_found, "Missing 'def main' within first $nlines lines of the code");
}

sub check_using_required_subs($$$){
    my $is_python_script = shift;
    my $aref_lines       = shift;
    my $href_nolint      = shift;

    # Each key is the name of a subroutine. It points to an array that contains:
    #    [0] ~ TRUE|FALSE  TRUE if this is only for python-scripts and not for 
    #          python modules.
    #    [1] ~ The regular expression pattern to look for
    #
    # TODO Add Misc.setup_script

    my %patterns = ( 
        'utils__script_usage_statistics'=>[TRUE,'\s*&?(utils__script_usage_statistics)|(Misc.setup_script)\s*\('], 
    );

    my $all_required_subs_used = TRUE;


    for my $subname (keys(%patterns)){
        next if ( !$is_python_script && $patterns{$subname}[0]==TRUE);

        if ( ! $href_nolint->{"$subname"} ){

            my $not_found = &search_for_pattern_in_list( $patterns{$subname}[1], 
                $aref_lines, 0, IGNORE_COMMENTS);
            if ( $not_found == TRUE ){
                # the pattern was not FOUND but should have been
                $all_required_subs_used = FALSE;
                eprint( "Required subroutine call '$subname' is missing\n" ); 
            }
        }
    }

    return ( $all_required_subs_used, "Missing required subroutine calls");
}

sub check_use_alpha_common($){
    my $aref_lines  = shift;
    my $href_nolint = shift;

    my $pattern = '/alpha_common/';

    my $not_found = &search_for_pattern_in_list( $pattern, $aref_lines, 0, 
        IGNORE_COMMENTS);
    if ( ! $not_found ){
        $not_found = 1 if (exists $href_nolint->{'alpha_common'});
    }

    return (! $not_found, "Found /alpha_common/");
}

sub check_python_version($){
    my $aref_lines = shift;

    my @good_patterns = (
        '/Python-3\.8\.0',
        '/Python-3\.10',
    );
    my $found;
    foreach my $pattern ( @good_patterns ) {
        $found |= ! &search_for_pattern_in_list( $pattern , $aref_lines , 4
        , DONOT_IGNORE_COMMENTS);
        
    }
    return (
        ! $found, 
        "Not using required version of Python. The valid version is one of @good_patterns"
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
    my $comment_pattern = '^#\s*';

    my $lineno=0;
    foreach my $line ( @$aref_lines ) {
        if ( $ignore_comments == IGNORE_COMMENTS ) {
            next if ( $line =~ m/${comment_pattern}/ ); 
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

 python_lint

=head1 VERSION

 2022ww30

=head1 SYNOPSIS

 python_lint [options] [file ...]

 Options:
   -help            brief help message
   -man             full documentation

 This script checks the given python files to make sure that they are
 following the python code best practice rules.

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

=item B<-short>

Suppress flake8 warnings from the standard output.

=back

=head1 DESCRIPTION

This script checks the given python files to make sure that they are
following the python code best practice rules.

=head1 RETURN VALUE

Returns 0 if there are no warnings or errors
Returns 1 if there are warnings or errors

=cut
