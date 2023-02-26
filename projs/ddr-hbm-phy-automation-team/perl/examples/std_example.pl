#!/depot/perl-5.14.2/bin/perl
###############################################################################
#
# Name    : std_example.pl
# Author  : James Laderoute
# Date    : Feb 15 2022 
# Purpose : To Demo a typical script using the standard template. 
#
#           It demos some of the Util subroutines that you can use.
#               header
#               write_stdout_log
#               footer 
#               utils__script_usage_statistics 
#               p4print
#               iprint
#               eprint
#               wprint
#               viprint
#               dprint
#               print_function_header
#               print_function_footer
#               prompt_before_continue
#               run_system_cmd
#
#           It demos some of the rules and recommendations for cleaner code
#               Using BEGIN{} and END{} sections
#               Using a Main() subroutine as the starting point in your script
#               80 column lines
#               4 space tabs (but using spaces and not actual tabs)
#               Using Carp module (confess instead of die)
#               Using prototypes in your subroutine declarations
#               Using POD (Plain Old Documentation) for your help messages
#               Aligning variable assignments so they look more pleasant
#               
#
# Modification History
#     000 James Laderoute Feb 15 2022 
#         Created this script
#     
###############################################################################
use strict;
use warnings;
use Pod::Usage;
use Getopt::Std;
use Getopt::Long;  # GetOptions
use File::Basename qw( dirname );
use Cwd  qw( abs_path );
use Carp qw(cluck confess croak);
use FindBin qw($RealBin $RealScript);

use lib "$RealBin/../lib/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;

#--------------------------------------------------------------------#
#our $STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
our $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $TESTMODE     = NONE;
our $PROGRAM_NAME = $RealScript;
our $VERSION      = '2022ww20';
#--------------------------------------------------------------------#

BEGIN{ our $AUTHOR='James Laderoute'; header(); } 
&Main();
END{
    write_stdout_log("${PROGRAM_NAME}.log");
    footer(); 
}

########  YOUR CODE starts here. Create a Main subroutine.  ##############

sub Main{

    my %options  = ( 'cfg'=>1, 'demo'=>1, 'born'=>undef );
    my %defaults = ( 'demo' => 1 );
    my @required = qw/born/;
    
    my $error = script_process_cmd_line_args( \%options, \%defaults, \@required ); 
    if ( $error ){
        exit( $error );
    }

    unless( $options{'nousage'} ){
        utils__script_usage_statistics( $PROGRAM_NAME, $VERSION, \@ARGV );
    }

    wprint( "%options are:\n" );
    my @keys = keys( %options );
    foreach my $key ( @keys ){
        wprint( "key is $key\n" );
    }

    #
    # If our debug level has been set to CRAZY, then this call will
    # prompt you to continue otherwise it will do nothing.
    # 
    prompt_before_continue( CRAZY );

    my $system_cmd = 'date';
    my ( $stdout, $retval ) = run_system_cmd( $system_cmd, $VERBOSITY );
    if ( $retval ){
        # A warning wprint() is colored Yellow
        wprint( "Unable to access date from the system command." );

        # Access and print date using the perl localtime() function.
        my @months = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
        my @days   = qw( Sun Mon Tue Wed Thu Fri Sat Sun );

        my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) 
            = localtime();
        iprint( "The current date is $mday $months[$mon] $days[$wday]\n" );

    }else{
        # An informational iprint has no color.
        iprint( "The current date is $stdout\n" );
    }

    if ( $options{'demo'} ){
        p4print( "p4print: This should be a green message.\n" );
        iprint( "info: This is an info message\n" );
        wprint( "wprint: This is a warning message\n" );
        viprint( MEDIUM, "viprint:MEDIUM This is an info message that's only "
            ."printed if the VERBOSITY variable is >=2.\n" );
        eprint( "eprint: This is an error message.\n" );
        dprint( HIGH, "'\$DEBUG': '$DEBUG': This is a debug message.\n" );
        prompt_before_continue( HIGH );
        #fatal_error( "This is a fatal message.\n" );  # Fatal messages will exit() 
                                                  #the program 
    }

    # We use confess() instead of die() and carp() which does not exit
    #    my $fh;
    #    open($fh, "/e/d/blah") || carp("I'm gonna die!\n");
    #    close($fh);

    iprint( "calling exit(0)\n" );
    exit(0); 
}
############    END Main    ####################
#
#
###############################################################################
sub my_random_sub($){
   print_function_header();
   my $firstVar = shift;

   iprint( "hello world $firstVar!\n" );
   print_function_footer();
   return;
}

#------------------------------------------------------------------------------
sub script_process_cmd_line_args($$$){
    my $href_options  = shift;
    my $href_defaults = shift;
    my $aref_required = shift;

    my $get_status = GetOptions($href_options 
        , 'cfg=s'
        , 'demo!'
        , 'born=i'
        , 'nousage'
        , 'debug' 
        , 'testmode' 
        , 'verbosity' 
        , 'h|help'
    );
    if ( ! $get_status || $href_options->{'help'} ){
        dprint(LOW, "get_status=$get_status");
        pod2usage(0);
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
        dprint(LOW, "do not have required!");
        pod2usage(0);
        return(0);
    }

    #
    # Set defaults
    #
    foreach my $argname ( keys( %{$href_defaults} ) ){
        if ( ! defined( $href_options->{"$argname"} ) or
             ! exists( $href_options->{"$argname"} ) ){
            $href_options->{"$argname"} = $href_defaults->{"$argname"};
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

   my $opt_testmode = $href_options->{'testmode'};
   if( defined $opt_testmode ){
       $main::TESTMODE = $opt_testmode;
   }


   return(0); ## success
};

#
# https://perldoc.perl.org/perlpodstyle
#

__END__

=pod

=head1 NAME

std_example

=head1 VERSION

2022ww20

=head1 SYNOPSIS

'A short usage summary for programs and functions.'

This script will display the current time and calculate your age given
your birth year.

=head1 DESCRIPTION

The main purpose of this script is to provide an example of a perl script
that uses the Util messages and some of the Util misc functions.

=head1 OPTIONS

'Detailed description of each of the command-line options taken by the program'

=head2 ARGS

=over 8

=item B<-config> Configuration file.

=item B<-born> [Required] What year was the client born?

=item B<-demo> Demo the Messaging routines.

=item B<-testmode> Enable test mode

=item B<-debug> Set debug level

=item B<-v> Verbosity level

=item B<-h> send for help (just spits out this POD by default, but we can 
chose something else if we like 

=back

=head1 RETURN VALUE

'What the program or function returns, if successful. This section can be
omitted for programs whose precise exit codes aren't important, provided they 
return 0 on success and non-zero on failure as is standard.'

=head1 ERRORS

=head1 DIAGNOSTICS

=head1 EXAMPLES

-head1 ENVIRONMENT

'Environment variables that the program cares about, normally presented as a 
list using '=over', '=item', and '=back'

=head1 FUNCTIONS

=head1 BUGS

Please report any bugs or feature requests using the Synopsys bug reporting
methodology.

=head1 SUPPORT

You can find documentation for this script with the perldoc command.

=head1 AUTHORS

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT_AND_LICENSE

Copyright 2021-2022, Synopsys

This software is owned by Synopsys; you are not allowed to redistribute it
and/or modify it.

=cut
