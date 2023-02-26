#!/depot/perl-5.14.2/bin/perl

use strict;
use Clone qw(clone);
use Data::Dumper;
use File::Copy;
use Getopt::Long;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Cwd qw( abs_path );
use Carp qw(cluck confess croak);
use XML::LibXML;
use Excel::Writer::XLSX;
use DateTime;
use Test2::Bundle::More;
use Date::Simple ('date', 'today');
use FindBin qw($RealBin $RealScript);

use lib "$RealBin/../lib/";
use SynopsysOrgData;
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
use Util::DateUtilities;

our $PROGRAM_NAME = $RealScript;
our $VERSION      = '1.0';
#----------------------------------#
our $STDOUT_LOG  = undef;       # Log msg to var => OFF
#our $STDOUT_LOG   = EMPTY_STR; # Log msg to var => ON
our $DEBUG     = NONE;
our $VERBOSITY = NONE;
our $MGR       = 'highest_level_mgr';
#----------------------------------#
use constant VAR_START_HTML => '!!!';
use constant VAR_STOP_HTML  => '&&&';
#----------------------------------#

BEGIN { our $AUTHOR = 'Patrick Juliano';header(); } 
   Main();
END { write_stdout_log("${PROGRAM_NAME}.log"); footer(); }

#-----/-----/-----/-----/-----/-----/-----/-----/-----/-----/-----/-----/
#  MAIN
#-----/-----/-----/-----/-----/-----/-----/-----/-----/-----/-----/-----/
sub Main {
	 my( $opt_nomail, $opt_config, $opt_debug, $opt_verbosity, $optHelp,
       $opt_nousage_stats, $opt_test, $opt_batch, $opt_mailme )= process_cmd_line_args();
	 utils__script_usage_statistics( abs_path($PROGRAM_NAME), $VERSION ) unless( defined $opt_debug || $DEBUG || $opt_nousage_stats ); 

   run_tests( 'TEST__policy.cfg', $opt_test ) if( $opt_test == TRUE );

   my ($href_cfg, undef) = load_config_file( $opt_config ); 
      $href_cfg = interpolate_vars_in_CFG( $href_cfg ); # expand deep references, then interpolate
   
   #  If the user specifies special tags for the start/stop of an html tag, then 
   #     use their custom settings. Otherwise, use the defaults.
   my ( $VAR_START_HTML, $VAR_STOP_HTML ) = get_html_tag_demarcation_characters( $href_cfg );

   #  write out file for debug
   write_file( [scalar(Dumper $href_cfg), "\n" ], 'href_cfg.txt' ) if( defined $opt_debug || defined $opt_test);

   # Load organization data for VP/manager 
   my ($href_org_data, $href_mgr_mnemonics) = get_org_data( $href_cfg );
   write_file( [scalar(Dumper $href_org_data), "\n" ], 'href_org.txt' ) if( defined $opt_debug || defined $opt_test );  
   
   # Step 1 : flag WARNING to user when policy is INVALID
   # Step 2 : save list of valid policies
   # Step 3 : report VALID policies, then process each
   my (@valid_policy_list) = cross_check_policies( $href_cfg );

   # Each policy needs to be inspected and processed. Each policy consists
   # of the following 3 components:
   #   (1)  name of jira_query to run 
   #   (2)  name of manager escalation chain to use
   #   (3)  name of email template to use
   my %all_jiras;
   my %all_data;
   foreach my $policy_name ( sort @valid_policy_list ){
      my $policy = $href_cfg->{policies}->{$policy_name};
      iprint( "--------------------------------------------------------\n" );
      hprint( "Processing Policy '$policy_name'\n" );

      #-------------------------------------------------------------------
      # Define XML filename for storing JQL output
      $href_cfg->{'fname_jql_output'} = $href_cfg->{'filename__jql_output'} .
                                        ".$policy_name.xml";
   
      #-------------------------------------------------------------------
      #  Every Jire query consists of the JQL and potentially a suffix (or add-on).
      #      By including a suffix/'add-on',  the user can create custom JQL using
      #      a common JQL.
      #      Example: 
      #        base JQL finds all 8D stories in a given L1
      #           ->suffix can be used to include only L2 that are DDR related 
      #           ->suffix can be used to include only those issues that are older than 10wks
      #           ->suffix can be used to include only those issues owend by a given user
      my $jql_name  = $policy->{jql};
      my $jql_query = $href_cfg->{jira_queries}{$jql_name} .' '. $policy->{jql_suffix};

      # Run the JQL query, store results in XML file.
      run_jql_and_write_xml( $href_cfg->{'jira_env'}  , $href_cfg->{'fname_jql_output'},
                             $href_cfg->{'maxResults'}, $jql_query, $jql_name, $opt_debug );

      #-------------------------------------------------------------------
      # Load XML with JQL results, store in them in XLS for user; much easier
      #     to study & manipulate the data.
      my ($dom_xml, $aref_jira_issues) = load_xml_from_file( $href_cfg->{'fname_jql_output'}, $opt_debug );
      # Implicit in fact that the return values are UNDEF is the signal to move to
      #    the next policy, stop processing current policy.
      next unless( defined $dom_xml && defined $aref_jira_issues);
      my $href_jira = extract_jira_data_from_xml( $policy_name, $href_cfg, $dom_xml );
      
      #-------------------------------------------------------------------
      # Compute the time that's elapsed since the JIRA was created.
      #    Record the interger # of 1. days 2. weeks 3. months.
      #    Record reporter firstname, and reporter lastname.
      $href_jira = post_process_jira_href( $href_jira, $href_org_data );
      #-------------------------------------------------------------------
      # If debug is on, write to file, potentially STDOUT as well.
      dprint(SUPER, "Jira Data".scalar(Dumper $href_jira). "\n");
      if( defined $opt_debug ){  write_file( [scalar(Dumper $href_jira), "\n" ], 'href_jira.$policy_name.txt' ); };
      $all_jiras{$policy_name} = clone $href_jira;
      my $href_data = merge_org_and_jira_data($href_jira, $href_org_data );
      dprint(CRAZY, scalar(Dumper $href_data). "\n" );
      interpolate_all_email_fields( $policy_name, $href_cfg, $href_data, $href_mgr_mnemonics, $opt_test );
      if( defined $opt_debug ){  write_file( [scalar(Dumper $href_data), "\n" ], "href_data.$policy_name.txt" ); };

      unless( $opt_nomail ){
         prep_n_send_mail( $opt_mailme, $opt_batch, $policy_name, $href_data,
                           $VAR_START_HTML, $VAR_STOP_HTML );
      }
      $all_data{$policy_name} = clone $href_data;
   }
   if( defined $opt_debug ){  write_file( [scalar(Dumper \%all_jiras), "\n" ], 'href_all_jiras.txt' ); };
   if( defined $opt_debug ){  write_file( [scalar(Dumper \%all_data),  "\n" ], 'href_all_data.txt'  ); };
   write_all_jira_data_to_xls( $href_cfg, \%all_jiras );
   print_function_footer();
}
############    END Main    ####################

#------------------------------------------------------------------------------
#  sub 'write_all_jira_data_to_xls':  create an XLS summary of all JIRAs.
#      Each sheet captures JIRA issues for a single policy.
#      Info for one Jira is captured in each row.
#------------------------------------------------------------------------------
sub write_all_jira_data_to_xls($$){
   print_function_header();
   my $href_config   = shift;
   my $href_all_jira = shift;

   my $fname_XLS = $href_config->{filename__xls_output};
      $fname_XLS =~ s/(.xls.*)$/.summary$1/;
   viprint(LOW, "Generating XLS for all Jira issues: '$fname_XLS'\n" );

   my $workbook;
   if( -e $fname_XLS ){
      iprint( "XLS file exists: '$fname_XLS'...removing\n" );
      unlink( $fname_XLS );
   }
   $workbook = Excel::Writer::XLSX->new($fname_XLS);
   fatal_error( "FAILED: Unable to create workbook.\n") unless( defined $workbook ); 
   viprint( MEDIUM, "Creating XLS '$fname_XLS'...\n" );

   # Create a single sheet for every policy.
   foreach my $policy_name ( sort keys %$href_all_jira ){
      my $worksheet = $workbook->add_worksheet($policy_name);

      # define cell format for column headers
      my $col_hdr_format = $workbook->add_format( 
         border => 1, 
         valign => 'vcenter',
         align  => 'center',
      );
      $col_hdr_format->set_bold(); 

      #----------------------------------------------------
      # Setup an array to record the max string length found 
      #     in any given cell of the column.
      my @character_counts = qw( 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                                 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 );

      #---------------------------------------------------------
      # CFG specifies JIRA fields that will be captured in XLS
      #     For each JIRA field, create new column & label it
      # So, we will write column headers into the sheet using the
      #     fields extracted from JIRA.
      #     Example:  col1, col2, col3 ... etc
      #       assignee created due_date ... etc
      my $col = 0;   
      my $row = 0;
      for my $headers_workbook ( sort keys $href_config->{jira_fields} ){
	       $worksheet->write($row, $col, $headers_workbook, $col_hdr_format);
         $character_counts[$col] = get_max_val( $character_counts[$col],
                                                length($headers_workbook) );
	       $col++;
      }
      #---------------------------------------------------------
      # record the column of the Jira IDs/Keys ... 
      #   will need it in order to bump up the size of the
      #   col width later.
      my $col_jiraID;
      my $href_policy_jiras = $href_all_jira->{$policy_name};
      my $jira_cnt = keys $href_policy_jiras;
      if( !defined $jira_cnt || $jira_cnt <1){
         #---------------------------------------------------------
         # Special Case -> no jira issues ... provide a row
         #     with a message so user not confused by result.
	       $col = 0; 
         $row++;
	       my $str = "No Jira issues found for this policy.";
         $character_counts[$col] = get_max_val( $character_counts[$col],
                                                length($str) );
         my $bg_yellow = $workbook->add_format();
         $bg_yellow->set_bg_color('yellow');
	       $worksheet->write( $row, $col, $str, $bg_yellow );
      }else{
         foreach my $jiraID ( sort keys $href_policy_jiras ){
	          $col = 0; 
	          $row++;
            my $href_jira_issue = $href_policy_jiras->{$jiraID}{jira};
            dprint(CRAZY+5, "Jira($jiraID)".scalar(Dumper $href_jira_issue). "\n");
            foreach my $field ( sort keys $href_config->{jira_fields} ){
               my $jira_value = $href_jira_issue->{$field};
               $character_counts[$col] = get_max_val( $character_counts[$col],
                                                length($jira_value) );
               if( $jira_value eq $jiraID ){
                  $jira_value = "https://jira.internal.synopsys.com/browse/".$jiraID;
                  my $url_format = $workbook->get_default_url_format();
                  $url_format->set_bg_color('white');
	                $worksheet->write( $row, $col, $jira_value, $url_format, $jiraID );
                  $col_jiraID = $col;
               }else{
	                $worksheet->write( $row, $col, $jira_value );
               }
	             $col++;
               dprint(CRAZY+5, "Jira($jiraID, $field, $jira_value)\n" );
            }
         }
      }
      my $max_cols = $col;
      # Now, set the column widths based on the max # characters
      #    seen in each cell of the column
      for( my $col=0; $col<=$max_cols; $col++ ){
         my $col_width = 4 + 0.85*$character_counts[$col];
         if( $col == $col_jiraID ){
            $col_width+=2;
         }
         dprint(CRAZY+10, "Col'$col':Width'$col_width'\n" );
         $worksheet->set_column( $col, $col, $col_width );
      }
   }
   $workbook->close() or confess "Error closing XLS file: '$fname_XLS'.\n";
   iprint("Wrote Jira query results to XLS: '$fname_XLS'\n" );

   return( );
}

#-----------------------------------------------------------------------------
#  sub 'interpolate_all_email_fields' :  
#-----------------------------------------------------------------------------
sub interpolate_all_email_fields($$$){
   my $policy_name  = shift;
   my $href_cfg     = shift;
   my $href_data    = shift;
   my $href_mgr_mnemonics = shift;

   my $policy = $href_cfg->{policies}->{$policy_name};
   #-------------------------------------------------------------------
   # grab the list of fields identified in the escalation template
   my $escalation_scheme = $href_cfg->{escalations}{ $href_cfg->{policies}{$policy_name}{escalation} };

   #-------------------------------------------------------------------
   # At this point, still need to interpolate all the variables in the
   #     email templates that are referencing Jira fields, because they
   #     aren't defined in the CFG (and therefore interpolated earlier)
   #     and they are context-dependent upon the specific Jira issue.
   #     Same goes for the email fields. Typically, this will by the
   #     assignee, reporter, managers, etc.
   foreach my $jira_id ( sort keys %$href_data ){
      # Start from the list of people and references from the policy email template
      my (@email_fields__FROM) = get_user_list_From( $policy_name, $escalation_scheme );
      my (@email_fields__TO  ) = get_user_list_To  ( $policy_name, $escalation_scheme );
      my (@email_fields__CC  ) = get_user_list_CC  ( $policy_name, $escalation_scheme );

      dprint(CRAZY, "List of people in email field 'FROM': ". pretty_print_aref(\@email_fields__FROM) ."\n" );
      dprint(CRAZY, "List of people in email field 'TO'  : ". pretty_print_aref(\@email_fields__TO  ) ."\n" );
      dprint(CRAZY, "List of people in email field 'CC'  : ". pretty_print_aref(\@email_fields__CC  ) ."\n" );

      #----------------
      # Now, interpolate the references in email subject and body
      my $email_template_name = $policy->{template};
      my $email_subj = interpolate_vars_in_emails( 
                    $href_cfg, $href_data, $policy_name, $jira_id,
                    $href_cfg->{email_templates}{$email_template_name}{subject},
      );
      my $email_body = interpolate_vars_in_emails( 
                    $href_cfg, $href_data, $policy_name, $jira_id,
                    $href_cfg->{email_templates}{$email_template_name}{body},
      );
      #----------------
      # Now, interpolate the references in the list
      my $FROM = interpolate_vars_in_emails( $href_cfg, $href_data, undef, $jira_id, join(",",@email_fields__FROM) );
      my $TO   = interpolate_vars_in_emails( $href_cfg, $href_data, undef, $jira_id, join(",",@email_fields__TO)   );
      my $CC   = interpolate_vars_in_emails( $href_cfg, $href_data, undef, $jira_id, join(",",@email_fields__CC)   );
      dprint(CRAZY, "People in email field 'FROM': ". $FROM ."\n" );
      dprint(CRAZY, "People in email field 'TO'  : ". $TO   ."\n" );
      dprint(CRAZY, "People in email field 'CC'  : ". $CC   ."\n" );

      @email_fields__FROM= grep { /\S/ } split(/,/, $FROM);
      @email_fields__TO  = grep { /\S/ } split(/,/, $TO);
      @email_fields__CC  = grep { /\S/ } split(/,/, $CC);
      #@email_fields__FROM=  split(/,/, $FROM);
      #@email_fields__TO  =  split(/,/, $TO  );
      #@email_fields__CC  =  split(/,/, $CC  );

      # If any name is present more than once, preserve only 1 of the references
      @email_fields__FROM = unique_scalars( \@email_fields__FROM );
      @email_fields__TO   = unique_scalars( \@email_fields__TO );
      @email_fields__CC   = unique_scalars( \@email_fields__CC );
      dprint(CRAZY, "Unique people in email array 'FROM': ". pretty_print_aref(\@email_fields__FROM) ."\n" );
      dprint(CRAZY, "Unique people in email array 'TO'  : ". pretty_print_aref(\@email_fields__TO  ) ."\n" );
      dprint(CRAZY, "Unique people in email array 'CC'  : ". pretty_print_aref(\@email_fields__CC  ) ."\n" );

      #----------------
      # If references still exist (e.g. <director>) then remove them from the list
      @email_fields__FROM = filter_invalid_mgr_references( $href_mgr_mnemonics, \@email_fields__FROM );
      @email_fields__TO   = filter_invalid_mgr_references( $href_mgr_mnemonics, \@email_fields__TO   );
      @email_fields__CC   = filter_invalid_mgr_references( $href_mgr_mnemonics, \@email_fields__CC   );

      #----------------
      # Store all the emaili fiels that have been interpolated, can send later
      $href_data->{$jira_id}{$policy_name}{email_details} = store_email_details(
                    $email_subj,
                    $email_body,
                   \@email_fields__FROM,
                   \@email_fields__TO,
                   \@email_fields__CC
      );
   }
   return();
}

#-----------------------------------------------------------------------------
# If a reference to a manager mnemonic failed, remove it from the email list.
#     For example, lets say there is not 'Mgr_M-8', or no 'director', then the
#     reference will be unresolved and remain in the email list. Therefore,
#     remove it before sending email. This is performed using 'compare_lists',
#     which performs set operations and returns the computed sets.
#-----------------------------------------------------------------------------
sub filter_invalid_mgr_references{
   print_function_header();
   my $href = shift;
   my $aref_emails = shift;

   my (@mgr_mnemonics) = keys %$href;
   # Add variable reference demarcation characters to the manager references
   #     so ... 'SupvII','manager' becomes '<SupvII>','<manager>' ... etc
   (@mgr_mnemonics) = map { "<$_>" } @mgr_mnemonics;
   dprint(CRAZY, "Filtering mnemonics:\n\t". pretty_print_aref(\@mgr_mnemonics) ."\n" );
   my ($aref_common, $aref_firstOnly, $aref_secondOnly, $bool__lists_equiv) =
                  compare_lists( $aref_emails, \@mgr_mnemonics );
   return( @$aref_firstOnly );
}

#-----------------------------------------------------------------------------
#  interpolate_vars_in_emails( $href_cfg, $href_data, $policy_name, $jira_id, join(",",@email_fields__TO)   );
#-----------------------------------------------------------------------------
sub interpolate_vars_in_emails($$$$$){
   print_function_header();
   my $href_cfg    = shift;
   my $href_data   = shift;
   my $policy_name = shift;
   my $jira_key    = shift;
   my $object      = shift;

   my @vars_replaced;
   my %warnings;

   dprint(CRAZY, "Object to interpolate=>\n'$object'\n" );

   while( $object =~ m/<(\S+?[^-])>/g ){
      my $varname = $1;
      my $field_value;
      # Check if email field has variable reference to a policy field (e.g. 'desc')
      if( defined $policy_name && defined $href_cfg->{policies}{$policy_name} ){
         if( $varname =~ m/thispolicy->(\w+)/ ){
            my $policy_field = $1;
            $field_value = $href_cfg->{policies}{$policy_name}{$policy_field};
         }
      }
      unless( defined $field_value ){
         $field_value = interpolate_jira_vars($href_data, $varname, $jira_key);
         dprint(CRAZY, "Variable='$varname' Value='$field_value'\n" );
         
         # Didn't find varname in $href_data->{$jira_id} ... try checking href_data for varname 
         unless( defined $field_value ){
            dprint(CRAZY, "Not defined '$varname' in Jira labels...'$field_value' \n" );
            $field_value = $href_cfg->{$varname};
         }
      }
      #------------------------------------------------------------
      # Sometimes the $field_value is an AREF
      #      (the varname is 'misc_mgrs').
      if( isa_aref($field_value) ){
         dprint(CRAZY, "This variable reference is an AREF...\n");
         my $elem;
         for( my $i=0 ; $i < @$field_value; $i++ ){
            $elem = "$field_value->[$i],";
            dprint(CRAZY, "elem='$elem'\n") ;
         }
         $elem =~ s/,$//; #chop trailing comma ','
         $field_value = $elem;
      }
      #------------------------------------------------------------
      #  Now replace the variable reference with the field value(s)
      if( defined $field_value ){
         if( $field_value eq NULL_VAL ){
            $object =~ s/(<$varname>)//g;
         }else{
            $object =~ s/(<$varname>)/$field_value/g;
         }
         push(@vars_replaced, $varname);      
      }else{
         $warnings{$varname} = "Couldn't find the value for '$varname' ... skipping.\n";
      }
   }
   dprint(CRAZY, "Done interpolating variables in object\n\t" . join(",", @vars_replaced) ."\n");
   foreach my $warning ( values %warnings ){
      wprint( $warning );
   }
   dprint(CRAZY, "Object interpolated! =>\n'$object'\n" );
   return( $object );
}

#-----------------------------------------------------------------------------
#  sub 'interpolate_jira_vars' :  look into the JIRA hash structure for the
#      value of the field/variable provided
#-----------------------------------------------------------------------------
sub interpolate_jira_vars($$$){
   print_function_header();
   my $href_data  = shift;
   my $href_field = shift;
   my $jira_key   = shift;

   my $value;
   # Special cases: references to the jira fields are access thru '<jira->varname>'
   #   'varname' comes from the key specified for the jira field from 
   #    the var block '<jira_fields>' in the CFG file.
   if( $href_field =~ m/jira->(\w+)/ ){
      $value = $href_data->{$jira_key}{jira}{$1};
   }else{
      # Assume the $href_field references the proper hash element in $href_data
      #   Typical examples here include 'manager', 'SrMgr' etc.
      $value = $href_data->{$jira_key}{$href_field};
   }
   if( defined $value){
      dprint(CRAZY, "-------$href_field => $value\n");
   }else{
      # If you don't find the variable in the JIRA context, issue warning
      #    gets noisy when you have many vars in the email that are
      #    defined in the CFG because those are not interpolated yet
      vwprint(MEDIUM, "The field '$href_field' is not defined!\n" );
   }

   return( $value );
}

#-----------------------------------------------------------------------------
#  sub 'store_email_details' : simply story the email details, no 
#     transformations, processing, operations, etc.
#-----------------------------------------------------------------------------
sub store_email_details($$$$){
   print_function_header();
   my $subject   = shift;
   my $body      = shift;
   my $aref_FROM = shift;
   my $aref_TO   = shift;
   my $aref_CC   = shift;

   my $href_email;
   $href_email->{email_subject}= $subject;
   $href_email->{email_body}   = $body;
   $href_email->{email_FROM}   = join(';', @$aref_FROM);
   $href_email->{email_TO}     = join(';', @$aref_TO  );
   $href_email->{email_CC}     = join(';', @$aref_CC  );

   dprint(CRAZY, "Email FROM   : ". pretty_print_aref($href_email->{email_FROM} ) ."\n" );
   dprint(CRAZY, "Email TO     : ". pretty_print_aref($href_email->{email_TO}   ) ."\n" );
   dprint(CRAZY, "Email CC     : ". pretty_print_aref($href_email->{email_CC}   ) ."\n" );
   dprint(CRAZY, "Email Subject: $href_email->{email_subject}\n" );
   dprint(CRAZY, "Email Body   : $href_email->{email_body}\n"    );

   return( $href_email );
}

#-----------------------------------------------------------------------------
#  sub 'prep_n_send' :  
#-----------------------------------------------------------------------------
sub prep_n_send_mail($$$$$){
   print_function_header();
   my $opt_mailme    = shift;
   my $opt_batch     = shift;
   my $policy_name   = shift;
   my $href_data     = shift;
   my $VAR_START_HTML= shift;
   my $VAR_STOP_HTML = shift;

      #-------------------------------------------------------------------
      # Now that the email details are defined, start sending mail!
      foreach my $jira_id ( sort keys %$href_data ){
         print "-"x80 . "\n";
         my $from = $href_data->{$jira_id}{$policy_name}{email_details}{email_FROM};
         my $to   = $href_data->{$jira_id}{$policy_name}{email_details}{email_TO};
         my $cc   = $href_data->{$jira_id}{$policy_name}{email_details}{email_CC};
         my $subj = $href_data->{$jira_id}{$policy_name}{email_details}{email_subject};
         my $body = $href_data->{$jira_id}{$policy_name}{email_details}{email_body};

         $from =~ s/;/,/g;
         $to   =~ s/;/,/g;
         $cc   =~ s/;/,/g;
         $body =~ s/$VAR_START_HTML/</g;
         $body =~ s/$VAR_STOP_HTML/>/g;

         my $msg_from = " FROM : $from\n";
         my $msg_to   = " TO   : $to\n";
         my $msg_cc   = " CC   : $cc\n";
         print $msg_from . $msg_to . $msg_cc;
         print "-"x80 . "\n";

         print "Subject : $subj\n";
         print "Body    :\n$body\n";

         print "-"x50 . "\n";
         if( defined $opt_mailme ){
               # Add subject header for people to create Mail Filters in their mail client
               $subj = "NOTIFY DRYRUN: $subj";
               my $prefix;
               # Add mail header to preserve original mail settings (from/to/cc).
               my $username = getpwuid($<);
               $prefix .= "\tFROM : $username\n";
               $prefix .= "\tTo   : $username\n";
               $prefix .= "\tCC   : $username\n";
               # Warn user of the mail setting overrides
               hprint( "Overriding mail fields:\n$prefix");
               $prefix  = "<pre>\n" . $prefix;
               $prefix .= "</pre>\n";
               $body = $prefix . $body;
               
               # Override any email fields so that all email is sent to user only.
               $from = $username;
               $to   = $username;
               $cc   = $username;
         }
         my $user_response;
         if( !defined $opt_batch ){
            print "-"x50 . "\n";
            hprint( "Do you wish to send the above email? (yes|*)\n" );
            $user_response = <STDIN>;
         }
         if( defined $opt_batch || $user_response eq "y\n" || $user_response eq "Y\n" ){
            unless( defined $opt_batch ){
               my $sleep = 2;
               print "Sending email in ${sleep}sec ...\n";
               sleep($sleep);
            }
            send_an_email( $to, $cc, $subj, $body, $from );
         }
      }
      print "-"x80 . "\n";
}

#-----------------------------------------------------------------------------
#  sub 'get_html_tag_demarcation_characters' :  deal with the fact that
#      we need to use HTML tags sometimes in the CFG file, especially for
#      email templates.  And, the default HTML tags collide with the CFG
#      format for VARIABLE declarations.
#-----------------------------------------------------------------------------
sub get_html_tag_demarcation_characters($){
   print_function_header();
   my $href_cfg = shift;
   my $VAR_START_HTML = $href_cfg->{special_html_tags}{start};
   my $VAR_STOP_HTML  = $href_cfg->{special_html_tags}{stop};
   unless( defined $VAR_START_HTML && $VAR_START_HTML =~ m/\S+/ ){
      $VAR_START_HTML = VAR_START_HTML;
   }  
   unless( defined $VAR_STOP_HTML && $VAR_STOP_HTML =~ m/\S+/ ){
      $VAR_STOP_HTML = VAR_STOP_HTML;
   }  

   dprint(MEDIUM, "Specialized HTML tag start sequence = '$VAR_START_HTML'\n" );
   dprint(MEDIUM, "Specialized HTML tag stop  sequence = '$VAR_STOP_HTML'\n" );
   # Order matters ... must process the \ char first!
   my @list =  qw( \ | . * ? + / ) ;
   foreach my $special_regex_char ( @list ){
      $special_regex_char = '\\'. $special_regex_char;
      $VAR_START_HTML =~ s/($special_regex_char)/\\$1/g;
      $VAR_STOP_HTML  =~ s/($special_regex_char)/\\$1/g;
   }
   dprint(MEDIUM, "After escapes needed for REGEX, Specialized HTML tag start sequence = '$VAR_START_HTML'\n" );
   dprint(MEDIUM, "After escapes needed for REGEX, Specialized HTML tag stop  sequence = '$VAR_STOP_HTML'\n" );

   return( $VAR_START_HTML, $VAR_STOP_HTML );
}

#-----------------------------------------------------------------------------
#  sub 'cross_check_policies' : check if the policy meets requirements/rules,
#       and check if it's marked active, report those that are VALID vs INVALID
#       and those that are active vs NOT
#-----------------------------------------------------------------------------
sub cross_check_policies($){
   print_function_header();
   my $href_cfg = shift;
   
   # check if each policy meets rules/requirements, skip those that are not valid
   my (@policy_list) = sort keys %{$href_cfg->{policies}}; 
   viprint(LOW, "Found '". scalar(@policy_list) ."' policies in CFG file. Processing ... \n" );
   viprint(MEDIUM, "Checking if Policies are valid: \n\t". 
              join(", ", keys %{$href_cfg->{policies}}) ."\n" );

   my (@warn_msgs) = check_policy_rules( $href_cfg );

   # Issue warnings for invalid policies
   foreach my $warning_message ( @warn_msgs ){
      wprint("$warning_message\n" ); 
   }

   my @valid_policy_list;
   foreach my $policy_name ( sort keys %{$href_cfg->{policies}} ){
      my $policy = $href_cfg->{policies}->{$policy_name};
      if( $policy->{valid} == TRUE && $policy->{active} eq 'TRUE' ){
         push( @valid_policy_list, $policy_name );
      }else{
         if( $policy->{valid} == FALSE ){
            wprint( "Policy is invalid ... skipping: '$policy_name'\n" );
         }
         if( $policy->{active} ne 'TRUE' ){
            vwprint(LOW, "Policy 'active' field is not marked TRUE ... skipping: '$policy_name'\n" );
         }
         #iprint( "-------------------------------------\n" );
         next;
      }
   }
   #------------------------
   my $i=1; my $list;
   foreach my $name ( sort @valid_policy_list ){
      $list .= "\t($i) $name\n";
      $i++;
   }
   iprint( "Found '". scalar(@valid_policy_list) ."' VALID policies in CFG file. Processing in order...\n$list" );

   return(  @valid_policy_list )
}

#-----------------------------------------------------------------------------
#  sub 'run_test' :  call the unit test sub from each of the packaages
#-----------------------------------------------------------------------------
sub run_tests($){
   print_function_header();
   my $fname_test_cfg = shift;

      if( -e $fname_test_cfg ){
         iprint( "Running TESTs ... using CFG '$fname_test_cfg'\n" );
         my ($href_cfg, $aref)= load_config_file( $fname_test_cfg ); 
         write_file( [scalar(Dumper $href_cfg), "\n" ], 'test.href_cfg.log' );
         $href_cfg = interpolate_vars_in_CFG( $href_cfg ); # expand deep references, then interpolate
         write_file( [scalar(Dumper $href_cfg), "\n" ], 'test.href_cfg_vars.log' );
         my $cnt=1; # test counter
         $cnt = run_TESTs_SynopsysOrgData($cnt, $fname_test_cfg );
         $cnt = run_TESTs_DateUtilities( $cnt );
         #  write out file for debug
         write_file( [scalar(Dumper $fname_test_cfg), "\n" ], 'href_cfg.txt' );
         iprint( "Done running unit TESTs! Bye for now ...\n" );
         exit( 0 );
      }else{
         fatal_error( "Test CFG file doesn't exist: '$fname_test_cfg'\n" );
         exit( -1 );
      }
}

#------------------------------------------------------------------------------
#  Subroutine 'merge_org_and_jira_data': create a completely new data
#     struct that is essentially a copy of the JIRA and ORG data structs.
#     The primary key is ths JIRA ID. Here's example for just 1 JIRA issue.
#     $href_merged = {
#        'P80001562-79669' => {
#                    'fields/assignee/name' => 'tigranp',
#                    'fields/priority/name' => '2-Medium',
#                    'fields/reporter/name' => 'juliano',
#                    'fields/status/name'   => 'Validating',
#                    'fields/created' => '2020-09-09T08:19:57.872-0700',
#                    'fields/duedate' => '',
#                    'fields/summary' => '4D : GF12LP TC ESD CDM Failures',
#                    'fields/updated' => '2021-03-08T22:19:23.859-0800',
#                    'director'  => 'celio',
#                    'email'     => 'tigranp',
#                    'firstname' => 'Tigran',
#                    'lastname'  => 'Petrosyan',
#                    'manager'   => 'muraz',
#                    'mgr_chain' => [ 'muraz', 'celio', 'toffolon' ],
#                    'misc_mgrs' => 'N/A,
#                    'vp_name'   => 'toffolon'
#                    'elapsed'   => '33' # 33wks
#        },
#------------------------------------------------------------------------------
sub merge_org_and_jira_data($$){
   print_function_header();
   my $href_jira = shift;
   my $href_org  = shift;

   my %merged;
   foreach my $jira_id ( keys %$href_jira ){
      $merged{$jira_id} = $href_jira->{$jira_id};
      my $assignee = $href_jira->{$jira_id}{jira}{assignee};
      unless( $assignee =~ m/^\w+$/ ){
         $assignee = 'Unassigned';
         $merged{$jira_id}{jira}{'assignee'}= $assignee;
         $merged{$jira_id}{jira}{'assignee_firstname'}= $assignee;
         $merged{$jira_id}{jira}{'assignee_lastname'} = $assignee;
      }
      unless( defined $href_org->{$assignee} ){
         wprint( "Assignee 'Unassigned' for Jira '$jira_id' was not found in the organization database.\n" );
         next;
      }
      foreach my $key ( keys %{$href_org->{$assignee}} ){
         # Some of the data collected is in form an AREF. Must avoid
         #    storing pointer to the AREF, so copy the contents over. 
         #    Otherwise, the AREF points to existing data structure
         #    that may or may not be corrupted/deleted later. So,
         #    establish complete orthogonality between the data structures.
         if( isa_aref( $href_org->{$assignee}{$key}) ){
             my $aref = $href_org->{$assignee}{$key};
             my @copy;
             foreach my $elem ( @$aref ){
                push(@copy, $elem);
             }
             $merged{$jira_id}{$key} = \@copy;
         }elsif( isa_href( $href_org->{$assignee}{$key}) ){
	           my $call_stack = get_call_stack(); 
             eprint( "'$call_stack': found a hash ref where none is expected\n" );
         }else{
            # Gonna rename some of the fields at the time of transfer
            # By default, psql return the employee info using fields
            # 1. email 2. firsname 3. lastname
            # However, the convention in the flow is that each role/person has 3 names
            # 1. username  2. firstname 3. lastname
            #
            # Example for the jira 'reporter', 'manager', 'assignee'
            # 1. reporter 2. reporter_firstname 3. reporter_lastname
            # 1. assignee 2. assignee_firstname 3. assignee_lastname
            # 1. manager  2. manager_firstname  3. manager_lastname
            if( $key =~ m/^firstname$/ ){
               $merged{$jira_id}{jira}{'assignee_firstname'}= $href_org->{$assignee}{$key};
            }elsif( $key =~ m/^lastname$/ ){
               $merged{$jira_id}{jira}{'assignee_lastname'} = $href_org->{$assignee}{$key};
            }else{
               $merged{$jira_id}{$key} = $href_org->{$assignee}{$key};
            }
         }
      }
      dprint(CRAZY, scalar(Dumper \%merged) . "\n" );
   }

   return( \%merged );
}


#------------------------------------------------------------------------------
#  Subroutine 'get_org_data': grab org hierarchy data
#------------------------------------------------------------------------------
sub get_org_data($){
   print_function_header();
   my $href_cfg = shift;

   my $highest_level_mgr = $main::MGR;
   my $aref_psql_data;
   my $fname = $href_cfg->{psql_filename};
   if( defined $fname && -e $fname ){
      wprint("Organization DB file '$fname' exists already. Remove file to refresh data.\n" );
      my @list_psql_data = read_file($fname);
      $aref_psql_data = \@list_psql_data;
   }else{
      $aref_psql_data = query_orgdata_by_manager( $href_cfg->{$highest_level_mgr}, $href_cfg->{psql_cmd} );
      write_file($aref_psql_data, $fname);
   }

   # grab 1st row, which lists the field names
   my $href_field_map = get_index_of_each_field( shift($aref_psql_data) );
   my ($href_org_data, $href_mgr_mnemonics) = scrub_psql_org_data( $aref_psql_data, $href_field_map, $href_cfg);
   dprint(MEDIUM, "Here are the valid references to manager titles and mnemonics:\n" .scalar(Dumper $href_mgr_mnemonics). "\n" );
   return( $href_org_data, $href_mgr_mnemonics );
}

#------------------------------------------------------------------------------
#   Run the JQL (Jira Query Language) specified in the CFG file.
#      Using MSIP script to run JQL and write results to XML file.
#------------------------------------------------------------------------------
sub run_jql_and_write_xml ($$$) {
   print_function_header();
   my $jira_env_cfg   = shift;
   my $outputFilename = shift;
   my $maxResults_cfg = shift;
   my $jql_query      = shift;
   my $jql_name       = shift;
   my $opt_debug      = shift;
   
   my $format           = 'xml';
  
   my ($uname, $pwd) = get_login_info();

   if( -e $outputFilename && defined $opt_debug && $opt_debug =~ m/\S+/ ){
      wprint("XML file '$outputFilename' for policy exists already. Remove file to refresh data.\n" );
      return();
   }
   my $cmd = "msip_jira_mq_issue.py --maxResults $maxResults_cfg --outputFormat $format ".
             "--outputFile $outputFilename --jql '$jql_query' --user $uname ".
             " --pwd '$pwd' --qa '$jira_env_cfg'";
   viprint(LOW, "Running Jira Query '$jql_name': \n\t $jql_query\n" );
   my $cmd_to_display = $cmd;
   $cmd_to_display =~ s/pwd(\s+\S+\s+)/pwd ... /g;
   viprint(FUNCTIONS, "$cmd_to_display\n" );
   #------------------------------------------------------------------
   # The system command includes the user's password, so we need
   #     to make sure we don't display the actual command!
   #     See 'cmd_to_display' above
   #------------------------------------------------------------------
   my ($output, $retval) = run_system_cmd( $cmd, 0);
   if( $retval || $output =~ m/Error in the JQL Query/  ){
      eprint( "Syntax error in the JQL Query '$jql_name' ... fix before re-running!\n\t $jql_query\n" );
      if( $VERBOSITY >= MEDIUM ){ confess "System cmd failed:\n\t'$cmd'\n";  }
      hprint( "Want to continue despite above error?: (y/n) " );
      my $user_response = <STDIN>;
      if( $user_response =~ m/n/i ){ 
         fatal_error( "Aborting ... cmd failed:\n\t'$cmd'\n" );
      }
   }
   viprint(MEDIUM, "$output\n" );
   return();
}

#-------------------------------------------------------------------
# Compute the time that's elapsed since the JIRA was created.
#    Record the interger # of 1. days 2. weeks 3. months.
#    Record reporter firstname, and reporter lastname.
#-------------------------------------------------------------------
sub post_process_jira_href($$){
   print_function_header();
   my $href_jira     = shift;
   my $href_org_data = shift;
      #-------------------------------------------------------------------
      # Compute the time that's elapsed since the JIRA was created.
      #    Record the interger # of weeks.
      foreach my $jira_id ( keys %$href_jira ){
         my ($y,$m,$d) = get_YMD_from_jira_CreatedDate( $href_jira->{$jira_id}{jira}{created} );
         dprint(CRAZY+5, "My \$jira_id='$jira_id', createdDate='".  $href_jira->{$jira_id}{jira}{created} ."'\n" );

         # Instead of the default date reported by JIRA, scrub and report only Month/Day/Year
         #    default      => 021-06-09T11:34:02.906-0700
         #    replaced by  => 06/09/2021
         $href_jira->{$jira_id}{jira}{'created'}  = "$m/$d/$y";
         $href_jira->{$jira_id}{elapsed_days}   = days_from_now( "$y-$m-$d" );
         $href_jira->{$jira_id}{elapsed_weeks}  = weeks_from_now( "$y-$m-$d" );
         $href_jira->{$jira_id}{elapsed_months} = months_from_now( "$y-$m-$d" );
         dprint(CRAZY+5, "...elapsed days = '".   $href_jira->{$jira_id}{elapsed_days}  ."'\n" );
         dprint(CRAZY+5, "...elapsed weeks = '".  $href_jira->{$jira_id}{elapsed_weeks} ."'\n" );
         dprint(CRAZY+5, "...elapsed months = '". $href_jira->{$jira_id}{elapsed_months}."'\n" );
         #----------------------------------------------------------------
         # Record the first & last name of the user that created the JIRA.
         my $user_id_of_jira_reporter = $href_jira->{$jira_id}{jira}{reporter};
         if( !defined $user_id_of_jira_reporter ){
            wprint( "Jira Reporter not defined for '$jira_id'\n" );
         }elsif( !defined $href_org_data->{$user_id_of_jira_reporter} ){
            wprint( "Jira Reporter's username '$user_id_of_jira_reporter' not found in organization's data.\n" );
         }else{
            if( defined $href_org_data->{$user_id_of_jira_reporter}{firstname} ){
               $href_jira->{$jira_id}{jira}{reporter_firstname} = $href_org_data->{$user_id_of_jira_reporter}{firstname};
            }else{
               wprint( "In Jira ($jira_id), first name of the reporter ('$user_id_of_jira_reporter') was not found in the organization's database.\n" );
            }
            if( defined $href_org_data->{$user_id_of_jira_reporter}{lastname} ){
               $href_jira->{$jira_id}{jira}{reporter_lastname}  = $href_org_data->{$user_id_of_jira_reporter}{lastname};
            }else{
               wprint( "In Jira ($jira_id), last name of the reporter ('$user_id_of_jira_reporter') was not found in the organization's database.\n" );
            }
         }
      }
   return( $href_jira );
}

#------------------------------------------------------------------------------
sub load_xml_from_file($$){
   print_function_header();
   my $fname_xml = shift;
   my $opt_debug = shift;
   my $fh;
   
   unless( -e $fname_xml ){
      eprint( "File does NOT exist: '$fname_xml'.\n" );
      return( undef, undef );
   }
   open($fh, $fname_xml || confess  "FAILED: Unable to open '$fname_xml'.\n" );
      my $dom = XML::LibXML->load_xml(location => $fname_xml);
   close( $fh );

   my $href_jira_data;
   my @issues;
   foreach my $title ($dom->findnodes('/issues/item')) {
      my $jiraID = $title->findvalue('key');
      push(@issues, $jiraID);
   }
   
   iprint( "Found '" .scalar(@issues). "' Jira issues.\n" );
   unless( defined $opt_debug ){
      viprint(MEDIUM, "Removing XML file of the Jira issue data: '$fname_xml'\n" );
      unlink( $fname_xml );
   }
   
   # return the Document Object Module (dom)
   return( $dom, \@issues );
}
   
#------------------------------------------------------------------------------
#  sub 'extract_jira_data_from_xml':  Extract JIRA fields from XML and
#      write to XLS
#
#      We only need some of the data for each
#      JIRA issue. The CFG file specifies those JIRA fields we want to capture.
#      One row is used to record data for a single JIRA.
#------------------------------------------------------------------------------
sub extract_jira_data_from_xml($$){
   print_function_header();
   my $policy_name = shift;
   my $href_config = shift;
   my $dom = shift;

   my $fname_XLS = $href_config->{filename__xls_output};
      $fname_XLS =~ s/(.xls.*)$/.$policy_name$1/;
   viprint(LOW, "Generating XLS from Jira query: '$fname_XLS'\n" );

   my $workbook;
   if( -e $fname_XLS ){
      iprint( "XLS file exists: '$fname_XLS'...removing\n" );
      unlink( $fname_XLS );
   }

   $workbook = Excel::Writer::XLSX->new($fname_XLS);
   fatal_error( "FAILED: Unable to create workbook.\n") unless( defined $workbook ); 
   viprint( MEDIUM, "Creating XLS '$fname_XLS'...\n" );

   my $format;
   my $worksheet = $workbook->add_worksheet($policy_name);
   $format = $workbook->add_format();
   $format->set_bold(); 
   $format->set_bg_color( 'yellow' );
   # CFG specifies JIRA fields that will be captured in XLS
   #     For each JIRA field, create new column & label it
   my $row = 1;
   my $col = 0;   
   for my $headers_workbook (keys $href_config->{jira_fields}) {
	   $worksheet->write(0, $col, $headers_workbook, $format);
	   $col++;
   }

   # Extract JIRA fields from XML and write to XLS
   my $href_jira_data;
   foreach my $title ($dom->findnodes('/issues/item')) {
      my $jiraID = $title->findvalue('key');
      dprint(CRAZY+5, "$jiraID\n");
	    $col = 0; 
         foreach my $jira_label (keys $href_config->{jira_fields}){
            foreach my $jira_field_name ($href_config->{jira_fields}{$jira_label}) {
	             dprint(CRAZY+5, "$jira_field_name\n");
               # Next line uses XML field names defined in CFG such as:
               #     fields/status/name, fields/priority/name, fields/summary,
               #     fields/updated, fields/reporter/name 
               # $href_jira_data->{$jiraID}{$jira_field_name}       = $title->findvalue($jira_field_name);
               # Next line uses variable names defined in CFG such as:
               #     status, priority, reporter, 
               $href_jira_data->{$jiraID}{jira}{$jira_label} = $title->findvalue($jira_field_name);
	             $worksheet->write($row, $col, $href_jira_data->{$jiraID}{jira}{$jira_label});
	             $col++;
            }
            dprint(CRAZY+5, "Jira($jiraID)".scalar(Dumper $href_jira_data->{$jiraID}). "\n");
         }
	    $row++;
   }
   $workbook->close() or confess "Error closing XLS file: '$fname_XLS'.\n";
   dprint(CRAZY+5, "Jira Data".scalar(Dumper $href_jira_data). "\n");
   if( $DEBUG ){
      dprint(MEDIUM, "Wrote Jira query results to XLS: '$fname_XLS'\n" );
   }else{
      unlink( $fname_XLS );
   }

   return( $href_jira_data );
}


#------------------------------------------------------------------------------
sub process_cmd_line_args(){
   print_function_header();
	 my ( $opt_nomail, $opt_batch, $opt_test, $opt_config, $opt_debug, $opt_verbosity,
        $opt_help, $opt_nousage_stats, $opt_mailme );
	 GetOptions( 
		    "cfg=s"       => \$opt_config,     # config files for check
		    "debug=s"	  => \$opt_debug,      # multi purposed->(1) debug level (2) will trigger re-using JIRA xml file so query can be skipped.
		    "verbosity=s" => \$opt_verbosity,
		    "test"        => \$opt_test,       # run software unit tests
		    "batch"	      => \$opt_batch,      # override the default to run interactive
		    "mailme"	  => \$opt_mailme,     # override email fields to user only
		    "nomail"	  => \$opt_nomail,     # skip the email related steps, dump XLS only
		    "nousage"	  => \$opt_nousage_stats,    # when enabled, skip logging usage data
		    "help"	      => \$opt_help,    # Prints help

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

   unless( defined $opt_config || $opt_test == TRUE ){
       my $msg = "Must specify CFG filename using '-cfg' at cmd line!\n";
       print_help_msg( $msg );
   }
   unless( -e $opt_config || $opt_test == TRUE ){
       my $msg = "CFG file missing: '$opt_config' \n";
       fatal_error( $msg );
   }
	 return( $opt_nomail, $opt_config, $opt_debug, $opt_verbosity, $opt_help,
           $opt_nousage_stats, $opt_test, $opt_batch, $opt_mailme );
};

#------------------------------------------------------------------------------
sub print_help_msg($){
   my $msg = shift;
   
   print "Usage:  $PROGRAM_NAME -cfg <filename> \n  Options: \n";
   print "\t -batch  => batch mode, no prompting before sending emails \n";
   print "\t -mailme => ONLY send email to user; ignore <escalation> field in CFG policies\n";
   print "\t -nomail => skip email generation \n";
   print "\t -v <#>  => user message verbosity \n";
   print "\t -d <#>  => intensity of debug messaging \n";
   print "\t -h      ... prints help msg\n" ;
   if( defined $msg ){ 
       fatal_error( $msg, -1 ); 
   }
   exit(0);
}


#------------------------------------------------------------------------------
sub read_xlsx_file($$){
   print_function_header();
   my $xlsx_file_name = shift;
   my $xlsx_sheet_name = shift;

 

   print STDERR "-I- Reading Master Manifest from file : '$xlsx_file_name' \n";
   unless( -e $xlsx_file_name ){ fatal_error("File doesn't exist: '$xlsx_file_name' ... \n" ); }

 

   use Spreadsheet::Read;
   my $workbook = ReadData( $xlsx_file_name ) || confess "Couldn't parse file ... not in XLSX format!\n";
   unless( defined $workbook->[0]->{sheet}->{$xlsx_sheet_name} ){
       fatal_error( "XLSX sheet named '$xlsx_sheet_name' doesn't exist in workbook named '$xlsx_file_name'\n" );
   } 

   my $sheet_num = $workbook->[0]->{sheet}->{$xlsx_sheet_name};
   my $sheet = $workbook->[$sheet_num];

   my $aref;
   my $row_counter=0;
   for( my $row=$sheet->{minrow}; $row <= $sheet->{maxrow}; $row++ ){
      my @row;
      for( my $col=$sheet->{mincol}; $col <= $sheet->{maxcol}; $col++ ){
         push( @row, $sheet->{cell}[$col][$row]);
      }
      while( !defined $row[-1] ){
         dprint( CRAZY+2, pretty_print_aref_of_arefs( \@row ) );
         dprint( CRAZY+2, "Deleting last elem of row in CSV because it's 'undef'\n" );
         delete $row[-1];
         dprint( CRAZY+1, pretty_print_aref_of_arefs( \@row ) );
      }
      $aref->[$row_counter++] = \@row;
   }
   
   dprint(CRAZY, pretty_print_aref_of_arefs( $aref ) );

   print_function_footer();
   return( $aref );
}

#------------------------------------------------------------------------------
sub get_login_info(){
   print_function_header();
   my $login_file;
   my @info;
   my $id = "";
   my $pwd = "";
   if(!$id || !$pwd){
       $login_file = $ENV{'HOME'}.'/jiralogin.txt' if (!defined($login_file) || !$login_file);
       if (open(my $fh, '<:encoding(UTF-8)', $login_file)) {
           while (my $row = <$fh>) {
               chomp $row;
               push @info, $row;
           }
           my $pre = substr $info[0], 0, 5;
           if($pre eq "https"){
               printMessage("failed","400","The first line URL is no longer needed in jiralogin.txt file, only two lines (User ID/
Password) are required!");
               exit;
           }
           $id     = $info[0];
           $pwd    = $info[1];
       }
   }
   if(!$id){
       $id = $ENV{'USER'};
   }
   if (!$pwd) {
       #Get password
       print "Please enter your password:";
       system("stty -echo");
       $pwd = <STDIN>;
       chomp($pwd);
       system("stty echo");
       print "\n";
   }
    return($id, $pwd);
}

1;
