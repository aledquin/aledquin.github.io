#!/depot/perl-5.14.2/bin/perl
#############################################################################
#
# Name    : perl_lint.pl
# Author  : James Laderoute
# Date    : Mar 2 2022
# Purpose : To do some checks to see that a perl script conforms to our standard
#
# Modification History
#     000 James Laderoute  3/2/2022
#         Created this script
#     001 James Laderoute 9/8/2022
#         Checking for back-ticks; should use run_system_cmd() instead
#     002 James Laderoute 10/20/2022
#         Added a comment about how to bypass a lint rule.
#
# Bypassing lint:
#
#   If you add a comment in your code like # nolint SOMETHING, then that
#   is a way to tell this linter to not report it as an issue. This 
#   is usually a global setting, that is, it will skip it for the entire file
#   if it is mentioned anywhere.
#
#   We also have by-line # nolint statements that can be used to indicate 
#   to skip the linting only for that line of code. The #nolint must be
#   placed on the exact same line as the code you want to skip.
#
#############################################################################
use strict;
use warnings;

use Pod::Usage;
use File::Basename ;  # for filename parsing
use Cwd;              # for getpwuid
use English;          # English names in place of punctuation variables
use Getopt::Long;     # For command line parsing
use Data::Dumper;
use Carp  qw(cluck confess croak );
use FindBin qw( $RealBin $RealScript );
use Perl::Critic;     # Missing from /depot/perl-5.14.2/ but exists in /depot/perl-5.22.0/
my $USERNAME = getlogin() || getpwuid($<) || $ENV{'USER'} ;

# assuming perl_lint.pl is located in /admin
use lib "$RealBin/../sharedlib/perl/lib";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;

#---------------------------------------------------------------------------#
our $DEBUG = 0;
our $VERBOSITY = 0;
our $PROGRAM_NAME = $RealScript;
our $VERSION = '2022ww10';
#---------------------------------------------------------------------------#
use constant IGNORE_COMMENTS => TRUE;
use constant DONOT_IGNORE_COMMENTS => FALSE;


#---------------------------------------------------------------------------#
sub Main() {
    my %opt_defaults = ( 'usage' => 1, 'quiet' => 0 );
    my @required = qw/REQUIRED_ARGUMENTS/;
    my @filenames = ();
    my @myoptions = ( 'quiet', 'symlink!', 'force', 'short', 'debug:i', 'verbosity:i', 'usage!', 'man', 'help' );
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
    my $is_quiet = $returned_options{'quiet'};
    my $files_passed=0;
    my $files_failed=0;
    my $files_warning=0;
    my $files_skipped=0;

    my $total_fail=0;
    my $total_warn=0;
    my $nfiles = @filenames;
    my $filename = "";
    my $valid_perl = 0;
    my $isForce = $returned_options{'force'};

    foreach my $fname (@filenames){
        # we dont' want to check scripts under the /releases/ folder, we only
        # care about scripts in the dev/ areas.
        next if ( $fname =~ m|/releases/| );
        # we dont' want to run lint on anything under the .git directory
        next if ( $fname =~ m|\.git/| );

        my ($isScript, $isModule) = is_valid_perl( $fname );
        if ( $isScript or $isModule or $isForce ) {
            if ( ! -e $fname ) {
                eprint("NOFILE: '$fname' File Does Not Exist!\n") if ( ! $is_quiet );
                $files_skipped += 1;
                next;
            }
            
            $filename = $fname;
            $valid_perl = 1;

            my @lines;
            if( -e $filename ){
                @lines = read_file( $filename );
            }else{
                wprint( "File doesn't exist: '$filename'\n" );
            }
            my $href_nolint = perl_nolint_checks( \@lines );

            #
            # Do Perl::Critic linting
            #
            my $ncritic_fail = perl_critic_checks( $fname, 
                $returned_options{'short'}, $href_nolint  );

            $total_fail += $ncritic_fail;

            #
            # Do our own DDR DA Best Practices lint checks
            #
            my ($nddr_fail, $nddr_warn) = perl_script_checks( $filename, \@lines,
                                          $isScript, $isModule, $href_nolint );
            $total_fail    += $nddr_fail;
            $total_warn    += $nddr_warn;
            $files_warning += 1 if ( $nddr_warn > 0 );

            if ( ($nddr_fail + $ncritic_fail) > 0  || ($nddr_warn > 0) ) {
                eprint("FAILED: '$fname'\n") if ( ! $is_quiet );
                $files_failed += 1;
            }else{
                gprint("PASSED: '$fname'\n") if ( ! $is_quiet ); 
                $files_passed += 1;
            }
        } else {
            $files_skipped += 1;
            wprint("SKIPIT: '$fname' This does not appear to be a perl script or module\n") if ( ! $is_quiet );
        }
    }

    if ( ! $is_quiet ) {
        print("Files: Pass : Fail : Skip => $nfiles : $files_passed : $files_failed : $files_skipped\n");

    }

    if ( $total_fail > 0 ) {
        exit(1);
    }
    
    exit(0);
}


#--------------------------------------------------
# This looks for comments that say not to do the lint checks for some of 
# our DDR checks.  'nolint xyz'
#
# Let's say you want to turn of a lint rule, then add the the following:
#    "# nolint [rule]
#
# Example:
#   # nolint [ValuesAndExpressions::ProhibitConstantPragma] 
#--------------------------------------------------
sub perl_nolint_checks($){
    print_function_header();
    my @lines = @{ shift(@_) };
    my $href_skip_rules;

    foreach my $line ( @lines ) {
        if ( $line =~ m/^\s*#\s*nolint\s+(.*)\s*$/ ){
            dprint(MEDIUM, "line skip='$1'\n" );
            $href_skip_rules->{$1} = 1;
        }
    }
    dprint(MEDIUM, scalar(Dumper $href_skip_rules) . "\n" );

    print_function_footer();
    return( $href_skip_rules );
}

#------------------------------------------------------
sub perl_critic_checks($$$){
    print_function_header();
    my $fname       = shift;
    my $short       = shift;
    my $href_nolint = shift;

    #
    # Use Perl::Critic to do more extensive checks
    #
    my $CRITIC_PROFILE = "$RealBin/../.perlcriticrc";
    # https://metacpan.org/pod/Perl::Critic::Violation
    if ( $short  ) {
        Perl::Critic::Violation::set_format("%f: [%p] %m at line %l column %c. %e.\n");
    } else {
        Perl::Critic::Violation::set_format("%f: [%p] %m at line %l column %c. %e. \n%d\n");
    }

    # NOTE: severity can be set to one of 'gentle', 'stern', 'harsh', 'cruel' and 'brutal'
    my $critic = Perl::Critic->new( 
        '-profile'            => $CRITIC_PROFILE,
    );
    #print( $critic->policies() );
    my @violations = $critic->critique($fname);
    # https://metacpan.org/dist/Perl-Critic/view/lib/Perl/Critic/PolicySummary.pod
    my $nfail = @violations;
    if ( $nfail > 0 ) {
        $nfail=0; #reset and recount, but filter out lint-skip violations
        #print("\n-------------- PERL::CRITIC Violations --------------------\n");
        foreach my $violation ( @violations) {
            # Allow a user to waiver a violation. Skip if waiver found.
            my $skip = FALSE;
            foreach my $rule ( keys %$href_nolint ){
               $skip = TRUE if( $violation =~ m/$rule/);
            }
            print $violation unless( $skip == TRUE );
            $nfail++         unless( $skip == TRUE );
        }
    }

    return ($nfail);
}

#------------------------------------------------------
sub is_valid_perl($){
    print_function_header();
    my $filename = shift;

    my ($fname, $fpath, $suffix) = fileparse( $filename, '\..*' );
    my $is_perl_module = FALSE;
    my $is_perl_script = FALSE;
    $is_perl_module = TRUE if ( $suffix eq '.pm' );
    $is_perl_script = TRUE if ( $suffix eq '.pl');
    if ( $suffix eq '' ) {
        # try and use the unix 'file' command to determine if this
        # might be a perl script without the .pl extension.
        my ($t_result, $exit_val) = run_system_cmd( "file $filename", NONE);
        if ( $exit_val == 0 ) {
            if ( $t_result =~ m/Perl script/ ){
                $is_perl_script = TRUE;
            } elsif( $t_result =~ m/Perl5 module/ ){
                $is_perl_module = TRUE;
            }
        }
    }

    return ( $is_perl_script, $is_perl_module );
}


#------------------------------------------------------
sub perl_script_checks($$$$$){
    print_function_header();
    my $filename       = shift;
    my @lines          = @{ shift(@_) };
    my $is_perl_script = shift;
    my $is_perl_module = shift;
    my $href_nolint    = shift;

    dprint(CRAZY, "lines = " . scalar(Dumper \@lines) ."\n" );
    prompt_before_continue(INSANE);
    
    my $failures = 0;
    my $warnings = 0;
    my $failed   = 0;
    my $comment  = '';

    if( $is_perl_script ){

        if ( ! $href_nolint->{'check_perl_version'} ) {
            ( $failed, $comment ) = &check_perl_version( \@lines );
            if ( $failed == TRUE ) {
                $failures += 1;
                eprint("${filename}: ${comment}\n");
            }
        }

        if ( !$href_nolint->{'Main'} && !$href_nolint->{'main'} ) {
            ( $failed, $comment) = &check_Main( \@lines );
            if ( $failed == TRUE ) {
                $failures += 1;
                eprint("${filename}: ${comment}\n");
            }
        }

    }

    ( $failed, $comment) = &check_use_alpha_common( \@lines );
    if ( $failed == TRUE ) {
        $warnings += 1;
        wprint("${filename}: ${comment}\n");
    }

    my $old_utilities_being_used = FALSE;
    ( $failed, $comment) = &check_use_utilities( \@lines );
    if ( $failed == TRUE ) {
        $old_utilities_being_used = TRUE;
        $warnings += 1;
        wprint("${filename}: ${comment}\n");
    }
    (my $found_using, $comment) = &check_using_nonprefered_subroutines( 
        $filename, \@lines , $href_nolint);
    if ( $found_using == TRUE ) {
        $failures += 1;
    }

    (my $not_found, $comment ) = &check_using_backticks( \@lines, $href_nolint );
    unless ( $not_found ) {
        $failures += 1;
        eprint("${filename}: ${comment}\n");
    }

    if ( $old_utilities_being_used == FALSE ){
        my $found_using_old;
        ( $found_using_old, $comment) = &check_using_old_subroutines( 
            $filename, \@lines );
        if ( $found_using_old == TRUE ) {
            $failures += 1;
            #eprint($comment);
        }

        my $found_using_required;
        ( $found_using_required, $comment ) = &check_using_required_subs(
            $filename, $is_perl_script, \@lines, $href_nolint );
        if ( $found_using_required == FALSE ) {
            $failures += 1;
            #eprint($comment);
        }
    }

#    iprint("Done  Failures: $failures  Warnings: $warnings\n");

    return ( $failures, $warnings );
} # perl_script_checks


#------------------------------------------------------
sub check_Main($){
    print_function_header();
    my $aref_lines = shift;
    my $pattern = '^\s*sub\s+Main\s*';
    my $nlines = 250;

    my ($not_found, $lineno, $rep01, $mline) = &search_for_pattern_in_list( $pattern, $aref_lines, $nlines, 
        IGNORE_COMMENTS);
    return ($not_found, "Missing 'sub Main' within first $nlines lines of the code");
}

#------------------------------------------------------
sub check_using_required_subs($$$){
    print_function_header();
    my $filename = shift;
    my $is_perl_script = shift;
    my $aref_lines = shift;
    my $href_nolint = shift;

    # Each key is the name of a subroutine. It points to an array that contains:
    #    [0] ~ TRUE|FALSE  TRUE if this is only for perl-scripts and not for 
    #          perl modules.
    #    [1] ~ The regular expression pattern to look for
    #
    my %patterns = ( 
        'utils__script_usage_statistics'=>[TRUE,'\s*&?utils__script_usage_statistics\s*\('], 
    );

    my $all_required_subs_used = TRUE;

    for my $subname (keys(%patterns)){
        next if ( !$is_perl_script && $patterns{$subname}[0]==TRUE);

        if ( ! $href_nolint->{"$subname"} ) {
            my ($not_found, $lineno, $rep01, $mline) = &search_for_pattern_in_list( $patterns{$subname}[1], 
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

#------------------------------------------------------
sub check_using_nonprefered_subroutines($){
    print_function_header();
    my $filename    = shift;
    my $aref_lines  = shift;
    my $href_nolint = shift;

    dprint(INSANE+200, "lines = " . scalar(Dumper $aref_lines) ."\n" );
    prompt_before_continue(INSANE);

        #'open<'  => ['read_file or read_file_aref',  '^\s*open[^\w]+(.*<|[^>]*)' ],
        #'open>'  => ['write_file',                   'open[^\w]+.*[^2]>' ],
    my %patterns = ( 
        'system' => [  'run_system_cmd'    ,
                       '\s+&?system\s*\('  ,
                    ],
        'open<'  => [
                       'read_file or read_file_aref' , 
                       '^open[\s\(]+\s*(my |\$*\w+)[^>]+$|\s*([^\w]+|[\(\)!=]+)open[\s\(]+\s*(my |\$*\w+)[^\>]+' ,
                       \&preprocess_when_searching_for_open
                    ],
        'open>'  => [
                       'write_file',
                       'open[^\w]+.*[^2]>',
                       \&preprocess_when_searching_for_open
                    ],
    );

    # Regex for key 'open<' will match
    #    TRUE  => open( my $FP, "<$file" );
    #    TRUE  => open( my $FP, "<", $file );
    #    FALSE => open( my $FP, $file );
    #    FALSE => open( my $FP, "$file" );
 
    my $number_of_nonprefered_used = 0;

    for my $subname ( sort keys %patterns ){
        my $label      = $patterns{$subname}[0];
        my $regex      = $patterns{$subname}[1];
        my $preprocess_line = $patterns{$subname}[2];
        if ( ! $href_nolint->{"$subname"} ) {
            my @problems;
            my ($not_found) = &search_all_for_pattern_in_list( $patterns{$subname}[1], $aref_lines, 0,
                                                          IGNORE_COMMENTS, \@problems, $preprocess_line, $label);
            if ( $not_found == FALSE ){
                # the pattern was FOUND
                foreach my $problem ( @problems ){
                    my $mline = $problem->{'mline'};
                    next if ( $mline =~ m/nolint/ );
                    $number_of_nonprefered_used+= 1;
                    my $lineno = $problem->{'lineno'};
                    eprint( "${filename}: Found a call to subroutine '$subname' on line ($lineno),"
                           ." please use '$patterns{$subname}[0]' instead.\n" ); 
                    vhprint(LOW, "\t\t $mline\n" );
                }
            }
        }
    }

    my $found_using = $number_of_nonprefered_used > 0 ? TRUE : FALSE;
    return ( $found_using, "The code is using a non-prefered function(s)!'");
}

#------------------------------------------------------
sub check_using_old_subroutines($){
    print_function_header();
    my $filename   = shift;
    my $aref_lines = shift;

    my %patterns = ( 
        'halt'=> ['prompt_before_continue', '\s+&?halt\s*\('], 
    );

    my $number_of_old_subs_used = 0;

    for my $subname (keys(%patterns)){
        my ($not_found,$lineno,$rep01,$mline) = &search_for_pattern_in_list( $patterns{$subname}[1], 
            $aref_lines, 0, IGNORE_COMMENTS);
        if ( $not_found == FALSE ){
            # the pattern was FOUND
            $number_of_old_subs_used += 1;
            eprint( "${filename}: Found a call to old utilities subroutine '$subname', please use '$patterns{$subname}[0]' instead.\n" ); 
        }
    }

    my $found_using = $number_of_old_subs_used > 0 ? TRUE : FALSE;
    return ( $found_using, "The code is using old 'utilities' functions!'");
}


#------------------------------------------------------
sub check_use_utilities($){
    print_function_header();
    my $aref_lines = shift;
    my $pattern = '^\s*use\s+utilities\s*;';

    my ($not_found,$lineno, $rep01, $mline) = &search_for_pattern_in_list( $pattern, $aref_lines, 40, 
        IGNORE_COMMENTS);
    return ( ! $not_found, "You are using the old 'use utilities'; you should be using the newer 'use Util::*'");
}

#------------------------------------------------------
sub check_using_backticks($$){
    print_function_header();
    my $aref_lines = shift;
    my $href_nolint = shift;
    my $pattern = '\s*`([^`]+)`.*;';
    my $not_found = 1;
    my $lineno=0;
    my $paren1="";
    my $mline;

    if ( ! $href_nolint->{'backticks'} ){
        ($not_found, $lineno, $paren1, $mline) = &search_for_pattern_in_list( $pattern, $aref_lines, 0, 
            IGNORE_COMMENTS);
        $lineno = "" if ( ! $lineno );
        $paren1 = "" if ( ! $paren1 );
    }
    unless ( $not_found ) {
        $not_found = 1 if ( $mline =~  m/nolint/ );
        $not_found = 1 if ( $mline =~  m/grep/ );
    }


    return ( $not_found, "You are using backticks at line $lineno ($paren1); you should be using run_system_cmd");
}


#------------------------------------------------------
sub check_use_warnings($){
    my $aref_lines = shift;
    my $pattern = '^\s*use\s+warnings\s*;';

    my ($not_found,$lineno, $mline) = &search_for_pattern_in_list( $pattern, $aref_lines, 20, 
        IGNORE_COMMENTS);
    return ($not_found, "Missing 'use warnings'");
}

#------------------------------------------------------
sub check_use_alpha_common($){
    my $aref_lines = shift;
    my $pattern = '/alpha_common/';

    my ($not_found,$lineno,$mline) = &search_for_pattern_in_list( $pattern, $aref_lines, 0, 
        IGNORE_COMMENTS);
    return (! $not_found, "Found /alpha_common/");
}


#------------------------------------------------------
sub check_use_strict($){
    my $aref_lines = shift;
    my $pattern = '^\s*use\s+strict\s*;';

    my ($not_found,$lineno,$mline) = &search_for_pattern_in_list( $pattern, $aref_lines, 20,
        IGNORE_COMMENTS);
    return ($not_found, "Missing 'use strict'");
}

#------------------------------------------------------
sub check_perl_version($){
    my $aref_lines = shift;
    my $good_version = '/depot/perl-5.14.2/bin/perl';
    my $pattern = "^#!${good_version}";

    my ($not_found,$lineno) = &search_for_pattern_in_list( 
          $pattern
        , $aref_lines
        , 4
        , DONOT_IGNORE_COMMENTS);
    return (
        $not_found, 
        "Not using required version of Perl. The valid version is $good_version"
    );
}

#------------------------------------------------------
## search_for_pattern_in_list:
##
## Returns 4 values
##     1st:  TRUE:  if the pattern searched for was NOT found
##           FALSE: if the pattern searched for WAS found
##     2nd: line number in the file
##     3rd: value of first () match
##     4th: the text line that matched
#------------------------------------------------------
sub search_for_pattern_in_list($$$$){
    print_function_header();
    my $pattern = shift;
    my $aref_lines = shift;
    my $skip_after_n_lines = shift;
    my $ignore_comments = shift;

    my $not_found=TRUE;
    my $comment_pattern = '^\s*#\s*';
    my $re_p1="";

    my $lineno=0;
    my $match_line = "";
    foreach my $line ( @$aref_lines ) {
        $lineno += 1;
        if ( $ignore_comments == IGNORE_COMMENTS ) {
            next if ( $line =~ m/${comment_pattern}/ ); 
        }
        if ( $line =~ m/^\s*$/ ) {
            # skip blank lines
            next;
        }

        if ($skip_after_n_lines>0 && $lineno > $skip_after_n_lines) {
            last;
        }

        if ($line =~ m|${pattern}|) {
            $re_p1 = $1;
            $match_line = $line;
            $not_found = FALSE;
            last;
        }
    }
    return ($not_found, $lineno, $re_p1, $match_line);
}

#----------------------------------------------------------
sub preprocess_when_searching_for_open($){
   my $line = shift;

   if( $line =~ m/open/ ){
      dprint(INSANE, "line    = '$line' \n" );
      $line =~ s|"[^"]*open[^"]*"||; 
      $line =~ s|'[^']*open[^']*'||;
      $line =~ s|/[^/]*open[^/]*/||;
      dprint(INSANE, "line    = '$line' \n" );
   }

   my @regex_skip = ( 'opendir', 'p4 opened', ' \$\w+open', '#\s*nolint open(\<|\>)' );
   if( $line !~ m/open/ || test_regex( $line, \@regex_skip ) && vhprint(HIGH, "skip-->$line\n" ) ){
      return( 'skip' );
   }

   return( $line );
}

#----------------------------------------------------------
#  Check if regex is found in the line. '$regex' can be
#     a single value, or an AREF of regex to test.
#  Return Value: 
#     0 : regex NOT found in line
#     1 : regex found
#     NULL_VAL : something went wrong
#----------------------------------------------------------
sub test_regex($$){
   my $line  = shift;
   my $regex = shift;

   #--------------------
   # check if arg is a regex (scalar) or
   #     a list of regex (aref). Create a list
   #     and loop over it.
   my $aref;
   if( isa_scalar( $regex ) ){
       $aref = [ $regex ];
   }elsif( isa_aref( $regex ) ){
       $aref = $regex;
   }else{
       return( NULL_VAL );
   }

   #--------------------
   # Loop over regex list, test each vs the $line
   my $found = FALSE;
   foreach my $regex ( @$aref ){
       if( $line =~ m/$regex/ ){
           $found = TRUE;
           last;
       }
   }
   use constant PASS => 1;
   use constant FAIL => 0;

   if( $found eq TRUE ){
       return( PASS );
   }elsif( $found eq FALSE ){
       return( FAIL );
   }else{
       return( NULL_VAL );
   }

   print_function_footer();
   return( NULL_VAL );
}


#------------------------------------------------------
## search_all_for_pattern_in_list:
##
## Returns 4 values
##     1st:  TRUE:  if the pattern searched for was NOT found
##           FALSE: if the pattern searched for WAS found
#------------------------------------------------------
sub search_all_for_pattern_in_list($$$$;$$){
    print_function_header();
    my $pattern            = shift;
    my $aref_lines         = shift;
    my $skip_after_n_lines = shift;
    my $ignore_comments    = shift;
    my $aref_list          = shift;
    my $subref_preprocess  = shift;
    my $label              = shift;

    my $not_found=TRUE;
    my $comment_pattern = '^\s*#';

    my $lineno=0;
    my $match_line = "";
    foreach my $line ( @$aref_lines ){
        $lineno += 1;
        vhprint(HIGH, "line    = '$line' \n" );
        next if( $line =~ m/^\s*$/ ); # skip blank lines

        # ignore comments, unless caller indicates otherwise
        if( $ignore_comments == IGNORE_COMMENTS ){
            next if ( $line =~ m/${comment_pattern}/ ); 
        }

        # preprocess the line ... 
        my $processed_line=$line;
        if( defined $subref_preprocess ){
            # preprocess the line ... 
            $processed_line = &$subref_preprocess( $line );
            next if( $processed_line eq 'skip' );
        }


        if( $skip_after_n_lines>0 && $lineno > $skip_after_n_lines ){
            last;
        }

        dprint(CRAZY, "line    = '$line' \n" );
        dprint(CRAZY, "pattern = '$pattern' \n" );
        if( $processed_line =~ m|${pattern}| ){
            my $record = { 
                'mline'  => $line,
                'lineno' => $lineno,
                're_p1'  => $label,
            };
            push(@$aref_list, $record);
            $not_found = FALSE;
        }
    }
    return( $not_found );
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

 perl_lint

=head1 VERSION

 2022ww10

=head1 SYNOPSIS

 perl_lint [options] [file ...]

 Options:
   -force           run lint even when not recognized as a perl script/module
   -help            brief help message
   -man             full documentation

 This script checks the given perl files to make sure that they are
 following the perl code best practice rules.

=head1 OPTIONS

=over 8

=item B<-debug number>

Set a debug level, in order to control debug messages.

=item B<-verbose number>

Set the verbosity level on messages.

=item B<-force>

Run lint on the file even if we don't recognize it as a perl script

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

This script checks the given perl files to make sure that they are
following the perl code best practice rules.

=head1 RETURN VALUE

Returns 0 if there are no warnings or errors
Returns 1 if there are warnings or errors

=cut
