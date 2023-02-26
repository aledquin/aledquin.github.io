############################################################
# Utility subroutines for the date calculations
#
#  Author : Patrick Juliano
############################################################
package Util::DateUtilities;

use strict;
use warnings;

use Cwd;
use Carp;
use File::Spec::Functions qw( catfile );
use File::Basename;
use Getopt::Std;
use Cwd 'abs_path';
use Test2::Bundle::More;
use Data::Dumper;
use Date::Calc qw(:all);       #  Today()
use Date::Simple ('date', 'today');

$Data::Dumper::Sortkeys = sub { [sort keys %{$_[0]}] };

#use lib dirname(abs_path $0);
use FindBin qw($RealBin $RealScript);
use lib "$RealBin/../../lib/";
use Util::CommonHeader;
use Util::Misc;              # get_call_stack
use Util::Messaging;         # dprint

use Exporter;

our @ISA   = qw(Exporter);

# Symbols (subs or vars) to export by default 
our @EXPORT    = qw( 
   days_from_now 
   delta_days
   delta_weeks 
   get_work_week_from_YMD
   get_YMD_from_jira_CreatedDate 
   months_from_now 
   weeks_from_now 
);

# Symbols to export by request 
our @EXPORT_OK = qw();
#----------------------------------#

sub run_TESTs_DateUtilities($){
   my $cnt = shift;
   $cnt = TEST__days_from_now( $cnt );
   $cnt = TEST__weeks_from_now( $cnt );
   $cnt = TEST__months_from_now( $cnt );
   $cnt = TEST__delta_days( $cnt );
   $cnt = TEST__delta_weeks( $cnt );
   $cnt = TEST__get_work_week_from_YMD( $cnt );
   $cnt = TEST__get_YMD_from_jira_CreatedDate( $cnt );
   return( $cnt );
}

#-----------------------------------------------------------
#  Subroutine 'days_from_now' :  given a date in format
#      'YYYY-MM-DD', return the integer abs(#days) between
#      now and that date.  
#         => if date provided is invalid, return
#            constant defined by NULL_VAL (i.e. 'N/A')
#-----------------------------------------------------------
sub days_from_now($;$){
   my $YMD = shift;
   my $now = shift;  # arg for testing only

   unless( defined $now ){
      $now = get_date__now();
   }

   my $num_days = delta_days( $YMD, $now );

   return( $num_days );
}

#-----------------------------------------------------------
#  Subroutine 'weeks_from_now' :  given a date in format
#      'YYYY-MM-DD', return the integer abs(#wks) between
#      now and that date.  
#         => if date provided is invalid, return
#            constant defined by NULL_VAL (i.e. 'N/A')
#-----------------------------------------------------------
sub weeks_from_now($;$){
   my $YMD = shift;
   my $now = shift;  # arg for testing only

   unless( defined $now ){
      $now = get_date__now();
   }

   my $num_wks = delta_weeks( $YMD, $now );

   return( $num_wks );
}

#-----------------------------------------------------------
#  Subroutine 'months_from_now' :  given a date in format
#      'YYYY-MM-DD', return the integer abs(#months) between
#      now and that date.  
#         => if date provided is invalid, return
#            constant defined by NULL_VAL (i.e. 'N/A')
#-----------------------------------------------------------
sub months_from_now($;$){
   my $YMD = shift;
   my $now = shift;  # arg for testing only

   unless( defined $now ){
      $now = get_date__now();
   }

   my $num_months = delta_months( $YMD, $now );

   return( $num_months );
}


#sub Today {
#    my $dateCmd = localtime();     #Wed Sep 28 16:34:08 2022
#    my ($day,$month,$date,$time,$year) = 
#        ($dateCmd =~ /^([\w]+)\s+([\w]+)\s+([\d]+)\s+([\d\:]+)\s+([\d]+)/i);
#    my %months = (
#        'Jan' => 1,
#        'Feb' => 2,
#        'Mar' => 3,  
#        'Apr' => 4, 
#        'May' => 5, 
#        'Jun' => 6, 
#        'Jul' => 7, 
#        'Aug' => 8, 
#        'Sep' => 9, 
#        'Oct' => 10,
#        'Nov' => 11,
#        'Dec' => 12,
#    );
#    return ( $year, $months{"$month"}, $date);
#}

#-----------------------------------------------------------
#  Subroutine 'get_date__now' :  
#     Inputs:  optional argument for testing purposes
#-----------------------------------------------------------
sub get_date__now(){
   # For testing, pass in a fixed date for 'now'.
   my ($year, $month, $day) = Today();
   my $now = "$year-$month-$day";
      
   dprint(CRAZY+10, get_call_stack() . "No date provided for 'now'...assign current date '$now'\n" );
   return( $now );
}

#-----------------------------------------------------------
#  Subroutine 'delta_weeks' :  
#     Inputs:  2 dates in format 'YYYY-MM-DD'
#     Ret Val: integer number weeks between dates provided
#         => if any date provided is invalid, return
#            constant defined by NULL_VAL (i.e. 'N/A')
#-----------------------------------------------------------
sub delta_weeks($$){
   my $YMD_1 = shift;
   my $YMD_2 = shift;

   my $num_days = delta_days( $YMD_1, $YMD_2 );
   dprint(CRAZY, get_call_stack() . " : (YMD_1, YMD_2)=>($YMD_1, $YMD_2)=>$num_days\n" );

   if( isa_int($num_days) ){
      return( int($num_days/7) );
   }else{
      return( NULL_VAL );
   }
}
#-----------------------------------------------------------
#  Subroutine 'delta_months' :  
#     Inputs:  2 dates in format 'YYYY-MM-DD'
#     Ret Val: integer number months between dates provided
#         => if any date provided is invalid, return
#            constant defined by NULL_VAL (i.e. 'N/A')
#-----------------------------------------------------------
sub delta_months($$){
   my $YMD_1 = shift;
   my $YMD_2 = shift;

   my $num_days = delta_days( $YMD_1, $YMD_2 );
   dprint(CRAZY, get_call_stack() . " : (YMD_1, YMD_2)=>($YMD_1, $YMD_2)=>$num_days\n" );

   # Not perfect, but assume 30days / month
   if( isa_int($num_days) ){
      return( int($num_days/30) );
   }else{
      return( NULL_VAL );
   }
}

#-----------------------------------------------------------
#  Subroutine 'delta_days' :  
#     Inputs:  2 dates in format 'YYYY-MM-DD'
#     Ret Val: number of days between dates provided
#         => if any date provided is invalid, return
#            constant defined by NULL_VAL (i.e. 'N/A')
#-----------------------------------------------------------
sub delta_days($$){
   my $YMD_1 = shift;
   my $YMD_2 = shift;

   my $err=FALSE;
   my $delta_days = NULL_VAL;
   my ($year,$month,$day);
   my ($num_days_1, $num_days_2);

   $num_days_1 = get_num_days($YMD_1);
   $num_days_2 = get_num_days($YMD_2);
   if( isa_int($num_days_1) && isa_int($num_days_2) ){
      # only compute value if there weren't errors
      $delta_days = abs($num_days_2 - $num_days_1);
   }else{
      $delta_days = NULL_VAL;
   }
   dprint(CRAZY+10, get_call_stack() . "(delta-days, #days1, #days2)=($delta_days, $num_days_1, $num_days_2 )\n" );
   dprint(CRAZY+10, "-----------------------------------------------------\n" );
   return( $delta_days );
}

#-----------------------------------------------------------
#  Subroutine 'get_num_days' : given a date in format 
#     'yyyy-mm-dd', check the validity of date and return
#     integer number days since Jan 1st, 0001 A.D.
#     If date provided is invalid, return constant defined
#     by NULL_VAL
#-----------------------------------------------------------
sub get_num_days($){
   my $YMD = shift;

   my $num_days = NULL_VAL;
   my ($year, $month, $day) = split(/-/, $YMD);
   if( check_date($year, $month, $day) ){
      dprint(CRAZY+10, get_call_stack() . "(y,m,d)=($year,$month,$day)\n" );
      $num_days = Date_to_Days($year, $month, $day);
   }else{
      $num_days = NULL_VAL;
      eprint( get_call_stack . "\n\tInvalid date provided '$YMD'\n" );
   }
   return( $num_days );
}

#----%----%----%----%----%----%----%----%----%----%----%----%----%----#
 
#-----------------------------------------------------------
#  Subroutine 'TEST__delta_days' :  
#-----------------------------------------------------------
sub TEST__delta_days($){
   my $cnt = shift;

   # Date pairs, ordered lists
   my @YMD_earlier = qw( 2016-12-31 2019-12-30  2020-12-30  2020-01-01  2020-01-01  2020-01-01  2020-02-10  2020-10-03  2020-10-00  2020-10-00 ); 
   my @YMD_later   = qw( 2017-01-01 2021-01-01  2021-01-01  2021-12-30  2020-12-30  2020-02-00  2020-03-10  2020-12-30  2020-12-30  2020-12-00 ); 
   dprint(CRAZY+10, get_call_stack() . ": \@YMD_earlier=(" .join(',', @YMD_earlier ) .")\n" );
   dprint(CRAZY+10, get_call_stack() . ": \@YMD_later  =(" .join(',', @YMD_later   ) .")\n" );

   my @computed_times_expected = ( 1, 368, 2, 729, 364, NULL_VAL, 29, 88, NULL_VAL, NULL_VAL );
   my @computed_times;
   my $i;
   if( scalar(@YMD_earlier) == scalar(@YMD_later) ){
      for( $i=0; $i < scalar(@YMD_earlier); $i++ ){
         push(@computed_times, delta_days( $YMD_earlier[$i], $YMD_later[$i] ) );
      }
   }else{
      fatal_error( "In ". get_call_stack() ."\n ...the list sizes were different!\n");
   }

   my $tot= $cnt+$i;
   is_deeply( \@computed_times, \@computed_times_expected, "TESTs($cnt-$tot) : 'delta_days' ... ran '$i' unit tests" );
   
   return( ++$tot );
}

#-----------------------------------------------------------
#  Subroutine 'TEST__days_from_now' :  
#-----------------------------------------------------------
sub TEST__days_from_now($){
   my $cnt = shift;
   my $now='2021-06-08';

   # Date pairs, ordered lists
   my @YMD = qw( 2021-06-03  2021-05-08  2021-05-04
                 2021-06-11  2020-06-08  Patrick
               ); 
   dprint(CRAZY+10, "Test: \@YMD= (" .join(',', @YMD) .")\n" );
   dprint(NONE, "Test: \@YMD= (" .join(',', @YMD) .")\n" );

   my @computed_times_expected = ( 5, 31, 35, 3, 365, NULL_VAL, 0 );
   my @computed_times;
   
   my $i;
   for( $i=0; $i < scalar(@YMD); $i++ ){
      push(@computed_times, days_from_now($YMD[$i] , $now) );
   }
   # Test single value in arg list
   my ($year, $month, $day) = Today();
   $now = "$year-$month-$day";
   push(@computed_times, days_from_now($now) );
   my $tot= $cnt+$i;
   is_deeply( \@computed_times, \@computed_times_expected, "TESTs($cnt-$tot) : 'days_from_now' ... '$i' unit tests" );

   return( ++$tot );
}

#-----------------------------------------------------------
#  Subroutine 'TEST__weeks_from_now' :  
#-----------------------------------------------------------
sub TEST__weeks_from_now($){
   my $cnt = shift;
   my $now='2021-06-08';

   # Date pairs, ordered lists
   my @YMD = qw( 2021-06-03  2021-05-08  2021-05-04
                 2021-07-08  2021-01-01  2020-12-30
                 2020-02-00  2020-12-00
               ); 
   dprint(CRAZY+10, "Test: \@YMD= (" .join(',', @YMD) .")\n" );

   my @computed_times_expected = ( 0, 4, 5, 4, 22, 22, NULL_VAL, NULL_VAL, 0);
   my @computed_times;
   
   my $i;
   for( $i=0; $i < scalar(@YMD); $i++ ){
      push(@computed_times, weeks_from_now($YMD[$i] , $now) );
   }
   # Test single value in arg list
   my ($year, $month, $day) = Today();
   $now = "$year-$month-$day";
   push(@computed_times, weeks_from_now($now) );
   my $tot= $cnt+$i;
   is_deeply( \@computed_times, \@computed_times_expected, "TESTs($cnt-$tot) : 'weeks_from_now' ... '$i' unit tests" );

   return( ++$tot );
}

#-----------------------------------------------------------
#  Subroutine 'TEST__months_from_now' :  
#-----------------------------------------------------------
sub TEST__months_from_now($){
   my $cnt = shift;
   my $now='2021-06-08';

   # Date pairs, ordered lists
   my @YMD = qw( 2021-06-03  2021-05-08  2021-05-04
                 2021-07-08  2021-01-01  2020-12-30
                 2020-02-00  2020-12-00
               ); 
   dprint(CRAZY+10, "Test: \@YMD= (" .join(',', @YMD) .")\n" );

   my @computed_times_expected = ( 0, 1, 1, 1, 5, 5, NULL_VAL, NULL_VAL, 0 );
   my @computed_times;
   
   my $i;
   for( $i=0; $i < scalar(@YMD); $i++ ){
      push(@computed_times, months_from_now($YMD[$i] , $now) );
   }
   # Test single value in arg list
   my ($year, $month, $day) = Today();
   $now = "$year-$month-$day";
   push(@computed_times, months_from_now($now) );
   my $tot= $cnt+$i;
   is_deeply( \@computed_times, \@computed_times_expected, "TESTs($cnt-$tot) : 'months_from_now' ... '$i' unit tests" );

   return( ++$tot );
}


#-----------------------------------------------------------
#  Subroutine 'TEST__delta_weeks' :  
#-----------------------------------------------------------
sub TEST__delta_weeks($){
   my $cnt = shift;

   # Date pairs, ordered lists
   my @YMD_earlier = qw( 2016-12-31 2019-12-30  2020-12-30  2020-01-01  2020-01-01  2020-01-01  2020-02-10  2020-10-03  2020-10-00  2020-10-00 ); 
   my @YMD_later   = qw( 2017-01-01 2021-01-01  2021-01-01  2021-12-30  2020-12-30  2020-02-00  2020-03-10  2020-12-30  2020-12-30  2020-12-00 ); 
   dprint(CRAZY+10, "Test: \@YMD_earlier   = (" .join(',', @YMD_earlier ) .")\n" );
   dprint(CRAZY+10, "Test: \@YMD_later     = (" .join(',', @YMD_later   ) .")\n" );

   my @computed_times_expected = ( 0, 52, 0, 104, 52, NULL_VAL, 4, 12, NULL_VAL, NULL_VAL );
   my @computed_times;
   my $i;
   if( scalar(@YMD_earlier) == scalar(@YMD_later) ){
      for( $i=0; $i < scalar(@YMD_earlier); $i++ ){
         push(@computed_times, delta_weeks( $YMD_earlier[$i], $YMD_later[$i] ) );
      }
   }else{
      fatal_error( "In ". get_call_stack() ."\n ...the list sizes were different!\n");
   }
   my $tot= $cnt+$i;
   is_deeply( \@computed_times, \@computed_times_expected, "TESTs($cnt-$tot) : 'delta_weeks' ... ran '$i' unit tests" );
   return( ++$tot );

}
#----%----%----%----%----%----%----%----%----%----%----%----%----%----#

#-----------------------------------------------------------
#  Subroutine 'get_YMD_from_jira_CreatedDate' :  
#-----------------------------------------------------------
sub get_YMD_from_jira_CreatedDate($){
   my $created_date = shift;

   if( $created_date =~ m/^(\d\d\d\d)-(\d\d)-(\d\d)T\d\d:\d\d:\d\d\.\d\d\d-\d\d\d\d/ ){
       my $year = $1;
       my $month= $2;
       my $day  = $3;
       return( $year, $month, $day );
   }else{
       eprint( "Tried to extract date from Jira CreateDate '$created_date' ... invalid format.\n" ); 
   }
   return( NULL_VAL, NULL_VAL, NULL_VAL );
}

#-----------------------------------------------------------
#  Subroutine 'TEST__get_YMD_from_jira_CreatedDate' :  
#    This sub expects single value input in the following
#    format, based on data extracted from JIRA using script
#    'msip_jira_mq_issue.py' => '2020-09-09T08:19:57.872-0700',
#    This sub returns 3 strings:  Year, Month, Day
#-----------------------------------------------------------
sub TEST__get_YMD_from_jira_CreatedDate($){
   my $cnt = shift;
   my $href = {
         'P80001562-79669' => {
                   'fields/created' => '2020-09-09T08:19:57.872-0700',
                   'fields/updated' => '2021-03-08T22:19:23.859-0800'
         },
         'P80001562-79670' => {
                   'fields/created' => '2020-09-09T08:20:01.223-0700',
                   'fields/duedate' => '2020-09-11',
                   'fields/updated' => '2021-03-08T22:18:01.408-0800'
         },
         'P80001562-79710' => {
                   'fields/created' => '2020-09-09T12:14:20.139-0700',
                   'fields/updated' => '2021-04-09T06:53:50.737-0700'
         },
   };
   my @list_of_YMD__got;
   my @list_of_YMD__expected = qw(
             2020-09-09 N/A-N/A-N/A 2021-03-08
             2020-09-09 N/A-N/A-N/A 2021-03-08
             2020-09-09 N/A-N/A-N/A 2021-04-09
   );
   my $start_cnt=$cnt;
   foreach my $jira_id ( sort keys %$href ){
      $cnt++;
      my($y,$m,$d);
      ($y,$m,$d) = get_YMD_from_jira_CreatedDate( $href->{$jira_id}{'fields/created'} );
      push(@list_of_YMD__got , "$y-$m-$d" );
      $cnt++;
      ($y,$m,$d) = get_YMD_from_jira_CreatedDate( $href->{$jira_id}{'fields/duedate'} );
      push(@list_of_YMD__got , "$y-$m-$d" );
      $cnt++;
      ($y,$m,$d) = get_YMD_from_jira_CreatedDate( $href->{$jira_id}{'fields/updated'} );
      push(@list_of_YMD__got , "$y-$m-$d" );
      $cnt++;
   }
   is_deeply( \@list_of_YMD__got, \@list_of_YMD__expected, "TESTs($start_cnt-$cnt): 'get_YMD_from_jira_CreatedDate': ran unit tests... " );
   return( $cnt );
}

#-----------------------------------------------------------
#  Subroutine 'get_work_week_from_YMD' :  
#-----------------------------------------------------------
sub get_work_week_from_YMD($$$){
   my $year = shift;
   my $month= shift;
   my $day  = shift;


   my $ww   = NULL_VAL; # work week
   if( check_date($year, $month, $day) ){
       $ww = Week_Number( $year, $month, $day );
   }else{
       eprint( "Tried to extract work week from '$year-$month-$day' ... invalid format.\n" ); 
   }
   return( $ww );
}

#-----------------------------------------------------------
#  Subroutine 'TEST__get_work_week_from_YMD' :  
#-----------------------------------------------------------
sub TEST__get_work_week_from_YMD($){
   my $cnt = shift;
   my @list_of_YMD = qw(
       violating dates 2001-0-0 2001-01-00 2001-00-00 2001-01-00

       1901-01-01 2001-01-01 2019-01-01
       2021-10-01 2022-11-01 2024-12-01
       3010-01-01 2024-12-31 2025-01-01

       2012-01-01 2012-12-31 2013-01-01 2013-12-31 
       2014-01-01 2014-12-31 2015-01-01 2015-12-31 
       2016-01-01 2016-12-31 2017-01-01 2017-12-31 
       2018-01-01 2018-12-31 2019-01-01 2019-12-31 

       2020-01-01 2020-12-31 2021-01-01 2021-12-31 
       2022-01-01 2022-12-31 2023-01-01 2023-12-31 
       2024-01-01 2024-12-31 2025-01-01 2025-12-31 
       2026-01-01 2026-12-31 2027-01-01 2027-12-31 

       2028-01-01 2028-12-31 2029-01-01 2029-12-31 
   );
   my @list_of_work_weeks__got;
   my @list_of_work_weeks__expected = qw(
       N/A N/A N/A N/A N/A N/A 
         1  1  1
        39 44 48
         1 53  1

         0	53	1	53
         1	53	1	53
         0	52	0	52
         1	53	1	53

         1	53	0	52
         0	52	0	52
         1	53	1	53
         1	53	0	52

         0	52	1	53
   );
   my $i=0;
   foreach my $YMD (  @list_of_YMD ){
      my ($y, $m, $d) =  split(/-/, $YMD);
      dprint(CRAZY, '($y, $m, $d)'." = ($y, $m, $d)\n" );
      push( @list_of_work_weeks__got , get_work_week_from_YMD($y,$m,$d) );
      $i++;
   }
   my $tot=$cnt+$i;
   is_deeply( \@list_of_work_weeks__got, \@list_of_work_weeks__expected, "TESTs($cnt-$tot): 'get_work_week_from_YMD' ..." );

   return( ++$tot );
}


#-----------------------------------------------------------
#  Subroutine 'days_between_dates' :  
#-----------------------------------------------------------
sub days_between_dates($$){
   print_function_header();
   my $created = shift;
   my $current = shift;

   if ($created ne  m/^(\d\d\d\d)-(\d\d)-(\d\d)/){
     my $year = substr($created, 0, 4);
     my $month = substr($created, 5, 2);
     my $day = substr($created, 8, 2);
     $created = "$year-$month-$day";
   }
   dprint(CRAZY, "$created\n");
   my $diff = date($current) - date($created);
   return($diff);
}



################################
# A package must return "TRUE" #
################################

1;
 
__END__
