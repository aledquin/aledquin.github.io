#!/depot/perl-5.14.2/bin/perl
#!/usr/bin/env perl

use strict;
use warnings;

use DBI;
use Clone qw(clone);
use Data::Dumper;
use File::Copy;
use Getopt::Long;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Cwd qw( abs_path );
use Carp qw(cluck confess croak);
use FindBin qw($RealBin $RealScript);

use lib "$RealBin/../../../sharedlib/lib";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;

use lib "$RealBin/../../../notify/dev/main/lib";
use Text::ASCIITable;
use SynopsysOrgData;
#use DateUtilities;

our $PROGRAM_NAME = $RealScript;
#----------------------------------#
our $DEBUG     = NONE;
our $VERBOSITY = NONE;
our $VERSION   = '2022ww11';
#----------------------------------#

BEGIN { our $AUTHOR='Patrick Juliano'; header(); } 
   Main();
END { footer(); }

our $href_from_file;

########  YOUR CODE goes in Main  ##############
sub Main {
   my( $opt_nomail, $opt_config, $opt_debug, $opt_verbosity, $optHelp,
       $opt_nousage_stats, $opt_batch, $opt_mailme )= process_cmd_line_args();
   
   utils__script_usage_statistics( abs_path($PROGRAM_NAME), $VERSION ) 
      unless( defined $opt_debug || $DEBUG || $opt_nousage_stats ); 

   my ($href_cfg, undef) = load_config_file( $opt_config ); 
   dprint(MEDIUM, "CFG data structure => \n" .scalar(Dumper $href_cfg). "\n" );

   my $fname_cfg_all_data = $href_cfg->{fname__all_data};
   my $fname_cfg_all_jira = $href_cfg->{fname__all_jira};
   load_href_cfg_file( $fname_cfg_all_data ); my %data      = %$href_from_file;
   load_href_cfg_file( $fname_cfg_all_jira ); my %all_jiras = %$href_from_file;

   my ($href_orig_cfg, undef) = load_config_file( $href_cfg->{fname__orig_cfg} );
   #print Dumper \%data;
   #print Dumper $href_orig_cfg;

   my $group_by_field = $href_cfg->{table}{NOTIFY}{group_by} || NULL_VAL;   
   my $where_suffix   = $href_cfg->{table}{NOTIFY}{where_suffix};
   my $primary_field  = assign_primary_field( $href_cfg->{table}{NOTIFY}{primary_field} ); # field to use for searching
   #---------
   #  Get columns/fields from CFG file. Check if scalar | aref ... then assign value(s) properly. 
   my @fields_to_retrieve = assign_add_columns( $href_cfg->{table}{NOTIFY}{add_column} ); # field to use for searching
   #---------
   my $order_by   = $href_cfg->{table}{NOTIFY}{row_ordering} || 'ORDER BY created';   # return records for this string
   #my @fields_to_retrieve = qw( key assignee reporter created elapsed_weeks updated email_subject ); 

   #--------
   my $table_name="NOTIFY";
   my $database = "notify.db";
   my $driver   = "SQLite"; 
   unlink($database);
   my $dsn      = "DBI:$driver:dbname=$database";
   my $userid   = "";
   my $password = "";
   #--------
   my $dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 , column => 1}) 
      or die $DBI::errstr;
   hprint( "Opened database successfully\n" );

   my @fields = qw(id  policy  key  issue_type  created  updated  assignee  assignee_firstname 
                   assignee_lastname  reporter  reporter_firstname  reporter_lastname  manager 
                   manager_firstname  manager_lastname  Mgr1  Mgr1_firstname  Mgr1_lastname  Mgr2 
                   Mgr2_firstname  Mgr2_lastname  elapsed_days  elapsed_weeks  elapsed_months 
                   email_FROM  email_TO  email_CC  email_subject  comment
   );
   create_table_NOTIFY( $dbh, $table_name, @fields );
   populate_table_NOTIFY( $dbh, $table_name, \@fields, \%all_jiras, \%data , $href_orig_cfg );
   
   #--------
   # Build the data set based on field user specified
   #    print Dumper \@selected_fields_values;
   my @primary_field_unique_values = @{ get_unique_field_vals_in_table( $dbh, $table_name, $primary_field  ) };
   my @group_by_field_unique_values;
   if( defined $group_by_field && $group_by_field ne NULL_VAL ){
      if( grep($group_by_field, @fields) ){
         @group_by_field_unique_values= @{ get_unique_field_vals_in_table( $dbh, $table_name, $group_by_field ) };
      }else{
         wprint( "Invalid field '$group_by_field' specified for variable 'group_by'! ... ignoring.\n" );
         # Single element, empty value, so that loop is executed once, but no filter created
         @group_by_field_unique_values= ( '' );
      }
   }else{
      # Single element, empty value, so that loop is executed once, but no filter created
      @group_by_field_unique_values= ( '' );
   }
   
   #--------
   # Create an ASCII table for each unique value in the user-specified
   #    field, based on 'WHERE' conditions
   @fields_to_retrieve = map{ $_ = "$_,"} @fields_to_retrieve;
   #print Dumper \@group_by_field_unique_values;
   prompt_before_continue(SUPER);
   foreach my $group_by_val ( sort @group_by_field_unique_values ){
      my $group_by_val_syntax = "AND $group_by_field = '$group_by_val'";
      if( $group_by_field eq NULL_VAL) {
         $group_by_val_syntax = '';
      }
      dprint(MEDIUM, "\$group_by_val_syntax=$group_by_val_syntax\n" );
      prompt_before_continue(SUPER);

      foreach my $field_val ( sort @primary_field_unique_values ){
         dprint(MEDIUM, "Build Table for $primary_field '$field_val'\n" );
   
         my $query = qq(SELECT @fields_to_retrieve FROM $table_name WHERE $primary_field='$field_val' $group_by_val_syntax $where_suffix $order_by;);
         $query =~ s/,\s*FROM / FROM /;

         # Can't have a comma preceding 'FROM'
         dprint(MEDIUM, "query=$query \n" );
         my $aaref = query_records_NOTIFY( $dbh, $query );
         next unless( scalar(@$aaref) > 1 );
         my $ascii_table = create_ASCII_table( $aaref );
         dprint(SUPER, "$ascii_table\n" );
         prompt_before_continue(LOW);
         my $from = 'juliano';
         my $to = 'juliano';
         if( $primary_field eq 'assignee' ){
           $to = $field_val;
         }
         my $cc = $aaref->[0][1];
         my $subject = 'Jira Idle too long ... ';
         my $body = "Please address the following Jira or make a plan with your manager ... \n$ascii_table\n";

         my $msg_from = " FROM : $from\n";
         my $msg_to   = " TO   : $to\n";
         my $msg_cc   = " CC   : $cc\n";
         print $msg_from . $msg_to . $msg_cc;
         print "-"x80 . "\n";

         print "Subject : $subject\n";
         print "Body    :\n$body\n";

         my $user_response;
         if( !defined $opt_batch ){
            print "-"x50 . "\n";
            hprint( "Do you wish to send the above email? (yes|*)\n" );
            $user_response = <STDIN>;
         }
         if( defined $opt_batch || $user_response eq "y\n" || $user_response eq "\Y\n" ){
            $body = "<pre>\n" . $body . "</pre>\n";
            $body =~ s|(P\d+-\d+) |<a href="https://jira.internal.synopsys.com/browse/$1">$1</a> |g;
            unless( defined $opt_nomail ){
               send_an_email( $to, $cc, $subject, $body, $from );
            }
         }
      }
   }

   $dbh->commit;
   exit(0);
}
############    END Main    ####################

#-------------------------------------------------------------------------------
# Get the unique values in the specified field/column of the table
#-------------------------------------------------------------------------------
sub get_unique_field_vals_in_table($$$){
   my $dbh           = shift;
   my $table_name    = shift;
   my $field_name    = shift;

   hprint( "grabbing unique field vals => '$field_name'\n" );
   my $query = qq(SELECT $field_name FROM $table_name;);
   my $aaref = query_records_NOTIFY( $dbh, $query );
   my @selected_fields_values;
   foreach my $aref ( @$aaref ){
      push(@selected_fields_values, $aref->[0] );
   }
   my @unique_field_values = list__get_unique_scalars( \@selected_fields_values );

   return( \@unique_field_values ); 
}

#-------------------------------------------------------------------------------
# Must have a one or more values specified for variable 'add_column' in CFG file.
#-------------------------------------------------------------------------------
sub assign_add_columns($){
   my $add_columns = shift;

   my $default_value = 'assignee';
   my @fields_to_retrieve;
   if( isa_aref( $add_columns ) ){
      @fields_to_retrieve = @{ $add_columns };
   }elsif( isa_scalar( $add_columns ) ){
      @fields_to_retrieve = ( $add_columns );
   }elsif( isa_href( $add_columns ) ){
      fatal_error( "Nested data structure NOT allowed for variable 'add_columns' in CFG file.\n" );
   }else{
      fatal_error( "Expected string or array of values for variable 'add_columns' in CFG file.\n" );
   }
   unless( defined $fields_to_retrieve[0] ){
      fatal_error( "In CFG, 'add_columns' is not defined! Fix before proceeding.\n" );
   }
   unless( $fields_to_retrieve[0] =~ m/\w+/ ){
      wprint( "In CFG, 'add_columns' empty, using default value 'assignee'\n" );
      $fields_to_retrieve[0] = $default_value;
   }

   vhprint(MEDIUM, "add_columns    =>". join(",", @fields_to_retrieve) ."\n" );
   return( @fields_to_retrieve );
}

#-------------------------------------------------------------------------------
# Must have a single value specified for variable 'primary_field' in CFG file.
#-------------------------------------------------------------------------------
sub assign_primary_field($){
   my $cfg_val = shift;

   my $default_value = 'assignee';
   my $primary_field;
   if( isa_scalar( $cfg_val ) ){
      $primary_field = $cfg_val;
   }elsif( isa_aref( $cfg_val ) ){
      eprint( "Multiple fields specified for 'primary_field' in CFG file. Only one field can be used.\n" );
      wprint( "Using first field specified in CFG for 'primary_field' ...\n" );
      my $aref = $cfg_val;
      $primary_field = shift( @$aref );
   }elsif( isa_href( $cfg_val ) ){
      fatal_error( "Nested data structure NOT allowed for variable 'primary_field' in CFG file.\n" );
   }else{
      fatal_error( "Expected string or array of values for variable 'primary_field' in CFG file.\n" );
   }
   unless( defined $primary_field ){
      fatal_error( "In CFG, 'primary_field' is not defined! Fix before proceeding.\n" );
   }
   unless( $primary_field =~ m/\w+/ ){
      wprint( "In CFG, 'primary_field' empty, using default value 'assignee'\n" );
      $primary_field = $default_value;
   }
   vhprint(MEDIUM, "Primary Field  => $primary_field\n" );
   return( $primary_field );
}

#-------------------------------------------------------------------------------
sub create_ASCII_table($$){
   my $aref_table  = shift;

   my $aref_headers = shift @$aref_table;

   my $t = Text::ASCIITable->new({ headingText => "SNPS Org Data" });
   $t->setOptions( {undef_as=>"-", alignHeadRow=>'center'} );
   
   # Build table based on manager names
   $t->setCols(@$aref_headers);
   $t->addRowLine();

   foreach my $aref_values ( @$aref_table ){
      $t->addRow( @$aref_values );
   }
   $t->addRowLine();

   return( $t );
}

#-------------------------------------------------------------------------------
sub query_records_NOTIFY{
   my $dbh  = shift;
   my $stmt = shift;

   #dprint(NONE, "STMT='$stmt'\n" );
   my $result = $dbh->prepare( $stmt );
   my $rv = $result->execute() or die "in stmt '$stmt' " . $DBI::errstr;
   
   if($rv < 0) {
      print $DBI::errstr;
   }

   #my $fields = join(',', @{ $result->{NAME_lc} });

   my $aaref_table;
   # Grab the TABLE's field names/column headers
   push(@$aaref_table, \@{ $result->{NAME} });

   # Print the rows of the TABLE that were fetched
   while(my @row = $result->fetchrow_array()) {
      push(@$aaref_table, \@row);
         print join("\t", @row) . "\n";
         prompt_before_continue(NONE);
   }

   #print pretty_print_aref_of_arefs( $aaref_table ) . "\n";
   return( $aaref_table );
}

#-------------------------------------------------------------------------------
sub populate_table_NOTIFY{
   my $dbh            = shift;
   my $table_name     = shift;
   my $aref_fields    = shift;
   my $href_all_jiras = shift;
   my $href_all_data  = shift;
   my $href_orig_cfg  = shift;

   my $cnt=1;
   my %jiras = %{clone $href_all_jiras};
   my %data  = %{clone $href_all_data};
   my @fields= @$aref_fields;
   #print "Fields=>" . scalar(Dumper \@fields) . "\n";
   #print Dumper \%jiras;
   #print Dumper \%data;
   foreach my $policy_name ( sort keys %jiras ){
      my $href_jiras = $jiras{$policy_name};
      foreach my $jiraID ( sort keys %$href_jiras ){
         my %row;
         next unless( keys $data{$policy_name} );
         $row{Mgr1}                = $data{$policy_name}{$jiraID}{Mgr1}           || "-";
         $row{Mgr1_firstname}      = $data{$policy_name}{$jiraID}{Mgr1_firstname} || "-";
         $row{Mgr1_lastname}       = $data{$policy_name}{$jiraID}{Mgr1_lastname}  || "-";
         $row{Mgr2}                = $data{$policy_name}{$jiraID}{Mgr2}           || "-";
         $row{Mgr2_firstname}      = $data{$policy_name}{$jiraID}{Mgr2_firstname} || "-";
         $row{Mgr2_lastname}       = $data{$policy_name}{$jiraID}{Mgr2_lastname}  || "-";
         $row{manager}             = $data{$policy_name}{$jiraID}{manager}        || "-";
         $row{manager_firstname}   = $data{$policy_name}{$jiraID}{manager_firstname} || "-";
         $row{manager_lastname}    = $data{$policy_name}{$jiraID}{manager_lastname}  || "-";
         $row{assignee}            = $data{$policy_name}{$jiraID}{jira}{assignee}    || '-' ;
         $row{assignee_firstname}  = $data{$policy_name}{$jiraID}{jira}{assignee_firstname} || '-' ;
         $row{assignee_lastname}   = $data{$policy_name}{$jiraID}{jira}{assignee_lastname}  || '-' ;
         $row{email_FROM}          = $data{$policy_name}{$jiraID}{$policy_name}{email_details}{email_FROM} || '-' ;
         $row{email_TO}            = $data{$policy_name}{$jiraID}{$policy_name}{email_details}{email_TO}   || '-' ;
         $row{email_CC}            = $data{$policy_name}{$jiraID}{$policy_name}{email_details}{email_CC}   || '-' ;
         $row{email_subject}       = $data{$policy_name}{$jiraID}{$policy_name}{email_details}{email_subject} || '-' ;
         $row{email_body}          = $data{$policy_name}{$jiraID}{$policy_name}{email_details}{email_body}    || '-' ;
         $row{policy}             = $policy_name || '-' ;
         $row{comment}            = $href_orig_cfg->{policies}{$policy_name}{comment}      || "-";
         $row{elapsed_days}       = $href_jiras->{$jiraID}{elapsed_days}     || '-' ;
         $row{elapsed_weeks}      = $href_jiras->{$jiraID}{elapsed_weeks}    || '-' ;
         $row{elapsed_months}     = $href_jiras->{$jiraID}{elapsed_months}   || '-' ;
         $row{created}            = $href_jiras->{$jiraID}{jira}{created}    || '-' ;
         $row{due_date}           = $href_jiras->{$jiraID}{jira}{due_date}   || '-' ;
         $row{issue_type}         = $href_jiras->{$jiraID}{jira}{issue_type} || '-' ;
         $row{key}                = $href_jiras->{$jiraID}{jira}{key}        || '-' ;
         $row{reporter}           = $href_jiras->{$jiraID}{jira}{reporter}   || '-' ;
         $row{reporter_firstname} = $href_jiras->{$jiraID}{jira}{reporter_firstname} || '-' ;
         $row{reporter_lastname}  = $href_jiras->{$jiraID}{jira}{reporter_lastname}  || '-' ;
         $row{status}             = $href_jiras->{$jiraID}{jira}{status}  || '-' ;
         $row{summary}            = $href_jiras->{$jiraID}{jira}{summary} || '-' ;
         $row{updated}            = $href_jiras->{$jiraID}{jira}{updated} || '-' ;
         $row{updated}            =~ s/T\d+.*$//;
         $row{id} = $cnt || '-' ;
         $cnt++;
         #print Dumper \%row;
         #prompt_before_continue( NONE );
         #my $values = "$cnt, '$policy_name', '$jiraID', '$issue_type'";
         my $values;
         foreach my $field ( @fields ){
            my $field_name = $field;
            $field_name =~ s/,//;
            if( $field_name eq 'id' ){
               $values = "$row{$field_name},";
            }else{
               # DBI needs proper formatting if/when there are single quotes in the field's value
               $row{$field_name} =~ s|\'|''|g;
               $values .= "'". $row{$field_name}. "',";
            }
         }
         # Sometimes, there's a preceding comma(s) -- remove them as it's not DBI friendly
         $values =~ s/^,*//;
         # Sometimes, there's a comma(s) after final field -- remove them as it's not DBI friendly
         $values =~ s/,*$//;
         dprint(SUPER, "values to insert=>\$values=$values\n" );
         insert_records_NOTIFY( $dbh, $table_name, \@fields, $values );
         prompt_before_continue( SUPER );
      }
   }
}

#-------------------------------------------------------------------------------
sub insert_records_NOTIFY{
   my $dbh         = shift;
   my $table_name  = shift;
   my $aref_fields = shift;
   my $values      = shift;
   
   my $fields = join(",", @$aref_fields);
   my $record = qq(INSERT INTO $table_name (@$aref_fields)
                  VALUES ($values));
   dprint(HIGH, "record=$record\n" );
   my $rv = $dbh->do($record) or die $DBI::errstr;

   viprint(LOW, "Records created successfully\n" );
}

#-------------------------------------------------------------------------------
sub create_table_NOTIFY{
   my $dbh        = shift;
   my $table_name = shift;
   my @fields     = @_;

   my $stmt_test;
   foreach my $field ( @fields ){
      $field =~ s/,//g;
      $stmt_test.= qq($field  TEXT  NOT NULL,\n);
   }
   # Make sure ID is used as the primary index
   $stmt_test =~ s/^ID\s+TEXT\s+NOT\s+NULL/CREATE TABLE ${table_name}(\nID INT PRIMARY KEY    NOT NULL/i;
   # Make sure last field in table does not have a trailing comma
   $stmt_test =~ s/,$/)/;

   dprint(HIGH, "Create Table: \n$stmt_test\n" );
   prompt_before_continue( SUPER );

   my $rv = $dbh->do($stmt_test);
   if($rv < 0) {
      print $DBI::errstr;
   } else {
      viprint(LOW, "Table created successfully\n" );
   }
}

#-------------------------------------------------------------------------------
sub load_href_cfg_file($){
   my $opt_cfg = shift;
   iprint( "Read config file: '$opt_cfg'\n" );
   my $header  = "package CFG;\n";
      $header .= "use Exporter;\n";
      $header .= "use strict;\n";
      $header .= 'our @ISA = qw(Exporter);'."\n";
   # Must already have 'href_from_file' declared using "our $href_from_file"
   my $footer  = '$main::href_from_file = $href;'."\n";
      $footer .= "1;\n";

   my $cfg_str = `cat $opt_cfg`;
      $cfg_str =~ s/^\$VAR1 = /my \$href =/;
   $cfg_str = $header . $cfg_str . $footer;
   my $fname = "config.file.cfg";
   while( -e $fname ){
      $fname .= int(rand(100));
      iprint("Temporary cfg filename exists ... randomizing filename before continuing.\n");
   }
   my $fp;
   open($fp, ">$fname") || die "Can't open file '$fname'\n";
      print $fp $cfg_str;
   close($fp);
   select((select(OUTPUT_HANDLE),$|=1)[0]);
   viprint(LOW, "Wrote temporary CFG file: '$fname'\n" );
   
   # Load data struct from file
   do $fname;

   # Remove tmp cfg file
   unless( $DEBUG ){
      viprint(LOW, "Removing temporary CFG file: '$fname'\n" );
      unlink($fname);
   }
}


#-------------------------------------------------------------------------------
sub process_cmd_line_args(){
   print_function_header();
    my ( $opt_nomail, $opt_batch, $opt_config, $opt_debug, $opt_verbosity,
        $opt_help, $opt_nousage_stats, $opt_mailme );
    GetOptions( 
          "cfg=s"       => \$opt_config,     # config files for check
          "debug=s"       => \$opt_debug,      # multi purposed->(1) debug level (2) will trigger re-using JIRA xml file so query can be skipped.
          "verbosity=s" => \$opt_verbosity,
          "batch"         => \$opt_batch,      # override the default to run interactive
          "mailme"       => \$opt_mailme,     # override email fields to user only
          "nomail"       => \$opt_nomail,     # skip the email related steps, dump XLS only
          "nousage"       => \$opt_nousage_stats,    # when enabled, skip logging usage data
          "help"         => \$opt_help,    # Prints help

    );

   # VERBOSITY will be used to control the intensity level of 
   #     messages reported to the user while running.
   if( defined $opt_verbosity ){
      if( $opt_verbosity =~ m/^\d+$/ ){  
         $main::VERBOSITY = $opt_verbosity;
      }else{
         eprint("Ignoring option '-v': arg must be an integer\n");
      }
   }

   # decide whether to alter DEBUG variable
   # '--debug' indicates DEBUG value ... set based on user input
   # Patrick : modified in order to specify a value >0 but <1
   if( defined $opt_debug ){
      if( $opt_debug =~ m/^\d+\.*\d*$/ ){  
         $main::DEBUG = $opt_debug;
      }else{
         eprint("Ignoring option '-d': arg must be an integer\n");
      }
   }

   if( defined $opt_help ){ print_help_msg(); }

   unless( defined $opt_config ){
       my $msg = "Must specify CFG filename using '-cfg' at cmd line!\n";
       print_help_msg( $msg );
   }
   unless( -e $opt_config ){
       my $msg = "CFG file missing: '$opt_config' \n";
       fatal_error( $msg );
   }
    return( $opt_nomail, $opt_config, $opt_debug, $opt_verbosity, $opt_help,
           $opt_nousage_stats, $opt_batch, $opt_mailme );
};

#-------------------------------------------------------------------------------
sub print_help_msg($){
   my $msg = shift;
   
   print "Usage:  $PROGRAM_NAME -cfg <filename> \n  Options: \n";
   print "\t -batch  => batch mode, no prompting before sending emails \n";
   print "\t -mailme => ONLY send email to user; ignore <escalation> field in CFG policies\n";
   print "\t -nomail => skip email generation \n";
   print "\t -v <#>  => user message verbosity \n";
   print "\t -d <#>  => intensity of debug messaging \n";
   print "\t -h      ... prints help msg\n" ;
   if( defined $msg ){ fatal_error( $msg ); }
   exit(-1);
}



1;
