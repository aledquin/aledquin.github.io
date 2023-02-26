#!/depot/perl-5.14.2/bin/perl
###############################################################################
#
# Name    : <the name of your script goes here>
# Author  : <your name here>
# Date    : <creation date here>
# Purpose : <description of the script.. You can write this on multiple lines>
#
# Modification History
#     000 <YOURNAME>  <CURRENT_DATE>
#         Created this script
#     001 YOURNAME DATE_OF_YOUR_CHANGES
#         Description of what you have changed.
#     
###############################################################################

use strict;        # always use this to catch problems early on
use warnings;      # always use this to catch problems early on
use Pod::Usage;
use Getopt::Long;
use Cwd;
use FindBin qw( $RealBin $RealScript );

use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;   # Example: TRUE, FALSE, NULL_VAL, LOW, MEDIUM, HIGH... 
use Util::Misc;           # Example: open_file(), write_file() ...
use Util::Messaging;      # Example: iprint(), dprint(), viprint(), ...
#use Util::DateUtilities;  # Subroutines to manage dates/time etc
#use Util::DS;             # Subroutines for data-structures
#use Util::P4;             # Subroutines for perforce operations

#--------------------------------------------------------------------#
our $STDOUT_LOG; # Initiailized in the BEGIN block
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $PROGRAM_NAME = $RealScript;
our $LOGFILENAME  = getcwd() . "/$PROGRAM_NAME.log";
our $VERSION      = get_release_version();
our $TESTMODE     = 0;  # if set then your script should not do anything
                        # destructive like 'p4 submit' commands. Intead just
                        # print an info about it.

BEGIN {
    our $AUTHOR='<your name>';
    #$STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
    $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
    header();
}
Main()  unless caller();
END {
   local $?;   # to prevent the exit() status from getting modified
   footer();
   write_stdout_log( $LOGFILENAME );
}

########  YOUR CODE goes in Main  ##############

sub Main {
   my @orig_argv   = @ARGV;  # keep this here because GetOpts modifies ARGV

   #
   # This function 'process_cmd_line_args' is where all the @ARGV switches
   # are parsed out.
   my( $opt_nousage ) = process_cmd_line_args();
   
   # How to display your POD usage statement
   #
   # pod2usage will print a usage message for the invoking script (using its 
   # embedded pod documentation) and then exit the script with the desired 
   # exit status. The usage message printed may have any one of three levels 
   # of "verboseness": If the verbose level is 0, then only a synopsis is 
   # printed. If the verbose level is 1, then the synopsis is printed along 
   # with a description (if present) of the command line options and 
   # arguments. If the verbose level is 2, then the entire manual page is 
   # printed.
   #
   # Example:
   #     use Pod::Usage;
   #     pod2usage(0);   # for short synopsys
   #     pod2usage(1);   # Synopsys and description of options and arguments
   #     pod2usage(2);   # Entire manual page is printed
   #
   #     The following style can be used to control the exit status that
   #     normally gets returned from pod2usage() calls. Typically 0 means
   #     success and other than 0 means a failure (eg. 1)
   #
   #     pod2usage( { -exitval => 0, -verbose => 0} );

   # Use NFS constant, it means Not Forward Slash
   # if ( $filename =~ s|/(${\NFS})/(${\NFS})/(${\NFS})| )
   
   # All scripts should include tracking of script invocations. Use the subroutine below
   #    to track invocations. Debugging user Jira is facilitated by capturing CMD line args.
   #    Pass aref to list @ARGV in 2nd argument to sub call (this is optional).
   #    Below are fives styles for calling usage routine, and style 1 is recommended to all.
   #    The rest are less desireable in practice, in order.
   #
   # Style 1: unless( $DEBUG || defined $opt_nousage ){ utils__script_usage_statistics( $PROGRAM_NAME, $VERSION, \@ARGV ); }
   # Style 2: unless( $DEBUG ){ utils__script_usage_statistics( $PROGRAM_NAME, $VERSION, \@ARGV ); }
   # Style 3: unless( $DEBUG ){ utils__script_usage_statistics( $PROGRAM_NAME, $VERSION ); }
   # Style 4: utils__script_usage_statistics( $PROGRAM_NAME, $VERSION, \@ARGV ); 
   # Least Preferred: Style 5: utils__script_usage_statistics( $PROGRAM_NAME, $VERSION );

   unless( $main::DEBUG || $opt_nousage ) {
       # This logs the useage of this script to a known database.
       utils__script_usage_statistics( $PROGRAM_NAME, $VERSION, \@orig_argv);
   }

   exit(0);  
}
############    END Main    ####################

#
# This is used to print help for your script. It's designed to work with
# POD (plain old documentation). The POD help goes at the end of the script.
#
sub usage($){
    my $exit_status = shift;
    my $message_text = "<specific message here>";
    my $verbose_level = 1;      # The verbose level to use
    my $filehandle = \*STDERR;  # The filehandle to write to

    pod2usage({
        -message => $message_text ,
        -exitval => $exit_status,
        -verbose => $verbose_level,
        -output  => $filehandle
        }
    );
}

#
# This is the script specific command line parser. These are currently
# setup to cover our standard list of command line options.
#
sub process_cmd_line_args(){
    my ( $opt_debug, $opt_verbosity, $opt_help, $opt_nousage, $opt_dryrun);
    my $status = GetOptions(
        "debug=i"     => \$opt_debug,
        "verbosity=i" => \$opt_verbosity,
        "nousage"     => \$opt_nousage,  # when enabled, skip logging usage data
        "dryrun!"     => \$opt_dryrun,   # do not run destructive p4 commands
        "help"        => \$opt_help,     # Prints help
     );

    $main::VERBOSITY = $opt_verbosity if ( defined $opt_verbosity);
    $main::DEBUG     = $opt_debug     if ( defined $opt_debug );
    $main::TESTMODE  = 1              if ( defined $opt_dryrun && $opt_dryrun );

    usage(0) if ( $opt_help ) ;

    if ( ! $status ){
        # Something went wrong with the parsing of ARGV
        usage(1);
    }

    return( $opt_nousage);
}
1;

__END__

=head1 NAME

 std_template

=head1 VERSION
 2023.02

=head1 ABSTRACT

 An abstract of the new script

=head1 SYNOPSIS

 std_template.pl [-debug #] [-verbosity #] [-nousage] [-dryrun] [-help]

 A synopsis of the new script

=head1 DESCRIPTION

 Provide an overview of functionality and purpose of this script

=head1 OPTIONS

=head2 ARGS

=over 8

=item B<-debug <level>> 

  To control debug messages printed via dprint(level, text)

=item B<-verbosity <level>> 

  To control debug messages printed via viprint(level, text)

=item B<-nousage> 

  Stops the logging of the usage of this code. That is; it does not send
  the script, user, options etc to Kibana.

=item B<-dryrun> 

  When this is used, any code that would normally do p4 operations should
  be skipped in this code.

=item B<-help> 

  Prints this help.

=back

=cut

