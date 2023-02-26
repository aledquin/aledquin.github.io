############################################################
# Utility subroutines for the Email Escalation Flow
#
#  Author : Patrick Juliano
############################################################
package SynopsysOrgData;

use strict;
use Carp;
use Data::Dumper;
use File::Spec::Functions qw( catfile );
use File::Basename;
use Cwd 'abs_path';
use Test2::Bundle::More;
use Config::General;

$Data::Dumper::Sortkeys = sub { [sort keys %{$_[0]}] };

use FindBin qw( $RealBin $RealScript );
use lib "$RealBin";
use Deep::Hash::Utils qw(reach slurp nest);
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;

print "-PERL- Loading Package: '", __PACKAGE__, ".pm'\n";

use Exporter;

our @ISA   = qw(Exporter);

# Symbols (subs or vars) to export by default 
our @EXPORT    = qw( 
   load_config_file
   interpolate_vars_in_CFG
   query_orgdata_by_manager
   get_index_of_each_field
   build_custom_field_mapping
   scrub_psql_org_data
   check_policy_rules
   run_TESTs_SynopsysOrgData
   get_user_list_From get_user_list_To get_user_list_CC
);

# Symbols to export by request 
our @EXPORT_OK = qw();

#$main::DEBUG = INSANE;
#$main::DEBUG = NONE;
#----------------------------------#
use constant PSQL_SrMgr    => qr/^Sr Mgr, /;
use constant PSQL_director => qr/^Dir, /;
use constant PSQL_MgrI     => qr/^Mgr I, /;
use constant PSQL_MgrII    => qr/^Mgr II, /;
use constant PSQL_VP       => qr/^VP, /;
use constant PSQL_SrVP     => qr/^SVP, /;
#----------------------------------#


sub run_TESTs_SynopsysOrgData($$){
   &print_function_header();
   my $cnt            = shift;
   my $fname_test_cfg = shift;

   $cnt = TEST__cfg_var_interpolation( $cnt );
   $cnt = TEST__check_policy_rules( $cnt, $fname_test_cfg );
   $cnt = TEST__get_email_lists( $cnt );
   $cnt = TEST__check_reqd_params_in_cfg( $cnt, $fname_test_cfg );

   #TEST__query_orgdata_by_manager1
   #TEST__query_orgdata_by_manager2
   print_function_footer();
   return( $cnt );
}

#-----------------------------------------------------------
#  Subroutine 'scrub_psql_org_data' :  
#-----------------------------------------------------------
sub scrub_psql_org_data($$$){
   &print_function_header();
   my $aref_psql_lines     = shift;
   my $href_psql_field_map = shift;
   my $href_cfg            = shift;

   # Retain those fields specified in CFG file only. 
   $href_psql_field_map = build_custom_field_mapping( 
          $aref_psql_lines, $href_psql_field_map, $href_cfg );

   # Grab the PSQL field names using CFG names.
   my @index_keys = values %{ $href_cfg->{psql_fields} };
   dprint(CRAZY+5, "index key names: ". scalar(Dumper \@index_keys) ."\n" );

   # entire data struct depends on 'employee' and 'mgmt_chain' variables defined in CFG file.
   my $index_employee   = $href_cfg->{psql_fields}{employee};
   my $index_mgmt_chain = $href_cfg->{psql_fields}{mgmt_chain};

   my $mgr = $main::MGR;
   my $highest_level_mgr = $href_cfg->{$mgr};
   my %org_data;
   foreach my $line ( @$aref_psql_lines ){
      # Parse row : 1 row represents data for 1 employee
      my @psql_row_tokens = split(/\|/, $line );
      # grab just those elements from full row of data that were 
      # requsted in the CFG file ... build a hash indexed by employee
      # name...add as many fields as the user requested.
      my $employee_name = $psql_row_tokens[ $href_psql_field_map->{$index_employee} ];
      foreach my $cfg_psql_field ( @index_keys ){
         # management chain : parse string, return list of mgr names
         if( $cfg_psql_field eq $index_mgmt_chain ){
            # Don't need any manager names higher than VP...assumes highest  level mgr is on RHS of str
            $psql_row_tokens[ $href_psql_field_map->{$cfg_psql_field} ] =~ s/$highest_level_mgr.*$/$highest_level_mgr/;
            $psql_row_tokens[ $href_psql_field_map->{$cfg_psql_field} ] = [ 
                  split(/\s+/, $psql_row_tokens[ $href_psql_field_map->{$cfg_psql_field} ] ) 
            ];
         }
         # store field values for this employee
         $org_data{$employee_name}{$cfg_psql_field} = $psql_row_tokens[ $href_psql_field_map->{$cfg_psql_field} ];
      }
      # Grab list of managers in the mgmt chain
      my @mgmt_chain =  @{$org_data{$employee_name}{$index_mgmt_chain}};

      dprint( CRAZY+20, "Mgmt Chain ". scalar(@mgmt_chain) .": ". scalar(Dumper \@mgmt_chain) . "\n" );
      dprint( CRAZY+20, "Employee Record ". scalar(Dumper \$org_data{$employee_name}) . "\n" );
   }
   my $href_mgr_mnemonics;
   foreach my $employee ( keys %org_data ){
      unless( $employee =~ m/\w+/ ){
         delete $org_data{$employee} unless( $employee =~ m/\w+/ );
         next;
      }
      $href_mgr_mnemonics = categorize_managers( $href_mgr_mnemonics, \%org_data, $employee, $highest_level_mgr );
   }
   dprint(CRAZY+20, "PSQL struct:\n". scalar(Dumper \%org_data) ."\n" );

   print_function_footer();
   return( \%org_data, $href_mgr_mnemonics );
}

#-----------------------------------------------------------
#  Subroutine 'add_manager_to_employee_record' :  
#     Assumptions
#     (1) list '@mgmt_chain' is a list of mgr
#         user names, where 0th element is the direct mgr of the
#         employee
#     (2) if more than one mgr has same title, the one that
#         is more senior over-writes the more junior mgr
#     employee will have a href like the following upon existing
#     this function:
#      $href->{$employee} = {
#         'GM' => 'kunkel',
#         'GM_firstname' => 'Joachim',
#         'GM_lastname' => 'Kunkel',
#         'Grpdirector' => 'kavanagh',
#         'Grpdirector_firstname' => 'Frank',
#         'Grpdirector_lastname' => 'Kavanagh',
#         'MgrII' => 'komalm',
#         'MgrII_firstname' => 'Komal',
#         'MgrII_lastname' => 'Hardas',
#         'SrMgr' => 'pcassidy',
#         'SrMgr_firstname' => 'Paul',
#         'SrMgr_lastname' => 'Cassidy',
#         'email' => 'mmurali',
#         'firstname' => 'Murali',
#         'lastname' => 'Makkena',
#         'manager' => 'komalm',
#         'manager_firstname' => 'Komal',
#         'manager_lastname' => 'Hardas',
#         'mgr_chain' => [
#                          'komalm',
#                          'pcassidy',
#                          'kavanagh',
#                          'pgillen',
#                          'kunkel'
#                        ],
#         'misc_mgrs' => [
#                          'pcassidy'
#                        ],
#         'title' => 'Mgr I, ASIC Digital Design',
#         'VP' => 'pgillen',
#         'VP_firstname' => 'Peter',
#         'VP_lastname' => 'Gillen'
#       };
#-----------------------------------------------------------
sub add_manager_to_employee_record($$$$$){
   #print_function_header();
   my $href   = shift;
   my $mgr    = shift;
   my $title  = shift;
   my $employee = shift;
   my $aref_misc_mgrs = shift;

   $href->{$employee}{$title} = $mgr; 
   $href->{$employee}{$title.'_firstname'} = $href->{$mgr}{firstname};
   $href->{$employee}{$title.'_lastname'}  = $href->{$mgr}{lastname};

   # Only possible to add a manager to the list of misc mgrs when 
   #    the manager is BELOW director level, and above direct manager
   #    level
   if( defined $aref_misc_mgrs ){
      push(@$aref_misc_mgrs, $mgr) if( $mgr ne $href->{$employee}{manager} );
   }else{
      #print "'$employee': NO arg to process for misc managers!\n" ;
   }
}

#-------------------------------------------------------------------------------------
#  Subroutine 'categorize_managers' :  
#     Find the actual title of the managers & save them into appropriate generic
#     categories like (VP, Director, etc)
#     Regardless of title of the direct manager of employee, save that persons
#     info into the 'manager' category.
#-------------------------------------------------------------------------------------
sub categorize_managers($$$$){
   print_function_header();
   my $href_mgr_mnemonics = shift;
   my $href          = shift;
   my $employee_name = shift;
   my $vp_name       = shift;

   my %employee   = %{$href->{$employee_name}};
   my @mgmt_chain = @{$href->{$employee_name}{mgr_chain}};
   my @misc_mgrs;
   my %lower_org_titles = (
      'SupvI'      => qr/^Supv I, /,
      'SupvII'     => qr/^Supv II, /,
      'MgrI'       => qr/^Mgr I, | Sales Manager$/,
      'MgrII'      => qr/^Mgr[\s,]+II,|Manager II/,
      'SrMgr'      => qr/^Sr (Mgr,|Manager)|Manager, Sr I|Mktg Mgr, Sr/,
   );
   my %higher_org_titles = (
      'director'   => qr/^Dir,|Director|Program Dir/,
      'Srdirector' => qr/^Sr Dir, /,
      'Grpdirector'=> qr/^Group Dir, /,
      'VP'         => qr/^VP, /,
      'CorpVP'     => qr/^Corp VP, /,
      'RegVP'      => qr/^Regional VP/,
      'SrVP'       => qr/^SVP, /,
   );
   foreach my $title ( keys %higher_org_titles, keys %lower_org_titles ){
      $href_mgr_mnemonics->{$title}++;
   }

   #----------------------------------------------------------
   # Create variable references starting from lowedt mgr up
   # Mgr1, Mgr2, Mgr3 
   my @ordered_list_of_mgrs = @mgmt_chain;
   my $lvl=1;
   foreach my $name ( @ordered_list_of_mgrs ){
      my $mgr_mnemonic = 'Mgr'.$lvl;
      $href_mgr_mnemonics->{$mgr_mnemonic}++;
      add_manager_to_employee_record( $href, $name, $mgr_mnemonic, $employee_name, undef ); 
      $lvl++;
   }
   #----------------------------------------------------------
   # Create variable references starting from highest mgr down
   # Mgr_M-1, Mgr_M-2, Mgr_M-3  (where "M-1" reads minus 1)
   $lvl=0;
   foreach my $name ( reverse @ordered_list_of_mgrs ){
      my $mgr_mnemonic = 'Mgr_M'.$lvl;
      $href_mgr_mnemonics->{$mgr_mnemonic}++;
      add_manager_to_employee_record( $href, $name, $mgr_mnemonic, $employee_name, undef ); 
      $lvl--;
   }

   #----------------------------------------------------------
   # Create variable reference to the manager of employee
   my $mgr_mnemonic = 'manager';
   $href_mgr_mnemonics->{$mgr_mnemonic}++;
   my $manager = shift( @mgmt_chain );
   # Manager of the employee is the 1st person in the list, regardless of the
   #    title they hold.
   add_manager_to_employee_record( $href, $manager, 'manager', $employee_name, undef ); 
   # Add back the manager in case they are also a very sr mgr/director etc.
   unshift( @mgmt_chain, $manager );
   
   my $employee_title = $href->{$employee_name}{title};
   foreach my $mgr ( @mgmt_chain ){
      my $title = $href->{$mgr}{title};
      #----------------------------------
      foreach my $level ( keys %lower_org_titles ){
         my $regex = $lower_org_titles{$level};
         if( $title =~ m/$regex/ ){
            add_manager_to_employee_record( $href, $mgr, $level, $employee_name, \@misc_mgrs ); 
         }
         if( $employee_title =~ m/$regex/ ){
            add_manager_to_employee_record( $href, $employee_name, $level, $employee_name, undef ); 
         }
      }
      #----------------------------------
      foreach my $level ( keys %higher_org_titles ){
         my $regex = $higher_org_titles{$level};
         if( $title =~ m/$regex/ ){
            add_manager_to_employee_record( $href, $mgr, $level, $employee_name, undef ); 
         }
         if( $employee_title =~ m/$regex/ ){
            add_manager_to_employee_record( $href, $employee_name, $level, $employee_name, undef ); 
         }
      }
   }

   # Make sure there's 1 or more managers in the list 'misc_mgrs' before
   #    assigning.  If there isn't, then mark it using the NULL_VAL
   #    constant, typically just 'N/A'
   if( scalar(@misc_mgrs) ){
      $href->{$employee_name}{misc_mgrs} = \@misc_mgrs;
   }else{
      $href->{$employee_name}{misc_mgrs} = NULL_VAL;
   }

   print_function_footer();
   return( $href_mgr_mnemonics );
}

#-------------------------------------------------------------------------------------
#  Subroutine 'get_index_of_each_field' :  
#-------------------------------------------------------------------------------------
sub get_index_of_each_field($){
   print_function_header();
   my $str_field_headers    = shift;

   my $expected_psql_fields = 'id\|firstname\|lastname\|email\|uid\|badge\|title\|job_function\|is_layout_engineer\|is_a_manager\|manager_email\|mgr_chain\|empcode\|photo_link\|site\|pager\|b_unit\|b_group\|b_group_a\|hire_date\|user_notes\|last_date\|emp_type\|support_type\|b_group_m\|updated_at';

   # Check for fields req'd to run flow
   eprint( "The SNPS organization database 'psql' did not have required fields... contact flow/script authors.\n" )
              unless( $str_field_headers =~ m/email/     &&
                      $str_field_headers =~ m/mgr_chain/ &&
                      $str_field_headers =~ m/firstname/ &&
                      $str_field_headers =~ m/lastname/  &&
                      $str_field_headers =~ m/title/        );
   
   # Check for fields present at time of development.
   wprint( "The SNPS organization database content changed ... contact SW owner if unexpected results occur.\n" )
              unless( $str_field_headers =~ m/^$expected_psql_fields$/ );

   my @field_names = split(/\|/, $str_field_headers );

   my $cnt=0;
   my $href_psql_fields;
   foreach my $field ( @field_names ){
      $href_psql_fields->{$field} = $cnt++;
   }
   dprint(SUPER, "PSQL field map:\n". scalar(Dumper $href_psql_fields) ."\n" );

   print_function_footer();
   return( $href_psql_fields );
}

#-------------------------------------------------------------------------------------
#  Subroutine 'build_custom_field_mapping' : psql returns many fields we 
#     don't need today. Retain those specified in CFG file only. 
#-------------------------------------------------------------------------------------
sub build_custom_field_mapping($$$){
   print_function_header();
   my $aref_psql_lines     = shift;
   my $href_psql_field_map = shift;
   my $href_cfg            = shift;

   my $href_tmp;

   # Rather than retain entire field mapping, we just need the 
   #   fields user requested in the CFG file.
   foreach my $field_name ( values %{$href_cfg->{psql_fields}} ){
      if( defined $href_psql_field_map->{$field_name} ){
         $href_tmp->{$field_name} = $href_psql_field_map->{$field_name};
      }
   }
   # overwrite entire field mapping available with just
   # those we want to retain
   dprint(CRAZY+10, "Final PSQL fields:\n".
                 scalar(Dumper $href_tmp) ."\n" );

   print_function_footer();
   return( $href_tmp );
}

#---------------------------------------------------------------------------
#  Subroutine 'query_orgdata_by_manager' :  
#---------------------------------------------------------------------------
sub query_orgdata_by_manager($$){
   print_function_header();

   my $manager_username = shift;
   my $cmd              = shift;

   iprint("Loading org data for manager: '$manager_username'!\n");

   my ($output, $retval) = run_system_cmd( $cmd, $main::VERBOSITY-2 );
   croak "System cmd failed: '$cmd'\n" if( $retval );
   my @psql_lines  = split(/\n/, $output );
   dprint(INSANE, "PSQL Raw Data:\n". scalar(Dumper \@psql_lines) ."\n" );

   print_function_footer();
   return( \@psql_lines );
}

#---------------------------------------------------------------------------
#  Subroutine 'TEST__cfg_var_interpolation' :  
#     
#---------------------------------------------------------------------------
sub TEST__cfg_var_interpolation($){
   print_function_header();
   my $cnt=shift;
my $op='->';
my $PA_status_prefix_test =  <<'EOT';
Hi <jira${op}assignee_firstname>,

During ... by <jira${op}reporter_firstname> ago, on <jira${op}created>.  <msg__published_tat_D1-D5> <TAT_for_steps_PA>.  
EOT

my $PA_status_prefix_expect =  <<'EOT';
Hi <jira${op}assignee_firstname>,

During ... by <jira${op}reporter_firstname> ago, on <jira${op}created>.  blah blah blah <TAT_for_steps_PA>.  
EOT
$PA_status_prefix_test =~ s/\${op}/$op/g;
$PA_status_prefix_expect =~ s/\${op}/$op/g;
   my $href_raw = {
       # setup simple vars
       'simple_var1'   => 'scooby doo',
       'simple_var2'   => 'scrappy doo',
       'simple-_-var3' => 'patty doo',
       '9th_plane_of_hell'  => 'deep doo doo',
       # setup complex vars
       'random' => {
          'nested' => {
             'lval' => 'random_nested_rval',
          },
          'nested2' => {
             'lval' => 'second_random_nested_rval',
          },
          'nested3' => {
             'lval' => '<deep_nesting->n1->n2->n3->n4->n5->n6->n7->n8->n9->n10->n11->n12->deep_lval>'
          },
          'nested4' => {
             'lval' => '<deep_nesting->n1->n2->n3->n4->n5->n6->n7->n8->n9->n10->n11->n12->deep_ref>'
          },
       },
       'deep_nesting' => {
          'n1' => { 'n2' => { 'n3' => { 'n4' => { 'n5' => { 'n6' => {
                      'n7' => { 'n8' => { 'n9' => { 'n10' => { 'n11' => { 'n12' => {
                                  'deep_lval' => 'deep_rval',
                                  'deep_ref'  => '<9th_plane_of_hell>',
       }, }, }, }, }, }, }, }, }, }, }, }, },
       # simple variable testing
       'test_simple1'       => 'simple_var1 is=<simple_var1>',
       'test_simple2'       => 'simple_var2 is=<simple_var2>',
       'test_simple3'       => 'simple_var3 is=<simple-_-var3>',
       'test_multi_simple'  => 'simple_vars1,2 are=<simple_var1>,<simple_var2>',
       'test_multiline'     => "simple_multiline =\n <simple-_-var3>",

       # complex variable testing
       'test_complex1'       => '<random->nested->lval>',
       'test_complex2'       => '<random->nested2->lval>',
       'test_multi_complex'  => '<random->nested->lval>,<random->nested2->lval>',
       'test_deep_complex'   => '<deep_nesting->n1->n2->n3->n4->n5->n6->n7->n8->n9->n10->n11->n12->deep_lval>',
       'test_invalid_complex'=> '<does->not->exist>',
       'test_deep_nested_complex' => '<random->nested3->lval>',
       
       # combinations of simple n complex variable testing
       'test_simple_n_complex1' => '<simple_var1>,<random->nested->lval>',
       'test_simple_n_complex2' => '<random->nested->lval>,<simple_var2>',
       'test_simple_n_complex3' => '<random->nested->lval>,<simple_var1>,<simple_var2>',
       'test_simple_n_complex4' => '<simple_var1>,<simple_var2>,<random->nested->lval>',
       'test_simple_n_complex5' => '<simple_var2>,<simple_var1>,<random->nested->lval>,<simple_var1>,<simple_var2>',
       'test_simple_n_complex6' => '<simple_var1>,<random->nested->lval>,<simple_var2>',
       'test_simple_n_complex7' => '<simple_var1>,<random->nested2->lval>,<simple_var2>',
       'test_simple_n_complex8' => '<simple_var1>,<random->nested->lval>,<simple_var1>,<random->nested2->lval>,<simple_var2>',
       'test_simple_n_complex9' => '<random->nested->lval>,<simple_var1>,<random->nested2->lval>,<simple_var2>',

       'msg__published_tat_D1-D5' => 'blah blah blah',
       'PA_status_prefix'         => $PA_status_prefix_test, 
   };
   #----------------------------------------------
   my $href_interpolated__expected = {
       'simple_var1'   => 'scooby doo',
       'simple_var2'   => 'scrappy doo',
       'simple-_-var3' => 'patty doo',
       '9th_plane_of_hell'  => 'deep doo doo',
       'random' => {
          'nested' => {
             'lval' => 'random_nested_rval',
          },
          'nested2' => {
             'lval' => 'second_random_nested_rval',
          },
          'nested3' => {
             'lval' => 'deep_rval',
          },
          'nested4' => {
             'lval' => 'deep doo doo',
          },
       },
       'deep_nesting' => {
          'n1' => { 'n2' => { 'n3' => { 'n4' => { 'n5' => { 'n6' => {
                      'n7' => { 'n8' => { 'n9' => { 'n10' => { 'n11' => { 'n12' => {
                                  'deep_lval' => 'deep_rval',
                                  'deep_ref'  => 'deep doo doo',
       }, }, }, }, }, }, }, }, }, }, }, }, },
       # simple variable testing
       'test_simple1'      => 'simple_var1 is=scooby doo',
       'test_simple2'      => 'simple_var2 is=scrappy doo',
       'test_simple3'      => 'simple_var3 is=patty doo',
       'test_multi_simple' => 'simple_vars1,2 are=scooby doo,scrappy doo',
       'test_multiline'    => "simple_multiline =\n patty doo",

       # complex variable testing
       'test_complex1'       => 'random_nested_rval',
       'test_complex2'       => 'second_random_nested_rval',
       'test_multi_complex'  => 'random_nested_rval,second_random_nested_rval',
       'test_deep_complex'   => 'deep_rval',
       'test_invalid_complex'=> '<does->not->exist>',
       'test_deep_nested_complex'   => 'deep_rval',

       'test_simple_n_complex1' => 'scooby doo,random_nested_rval',
       'test_simple_n_complex2' => 'random_nested_rval,scrappy doo',
       'test_simple_n_complex3' => 'random_nested_rval,scooby doo,scrappy doo',
       'test_simple_n_complex4' => 'scooby doo,scrappy doo,random_nested_rval',
       'test_simple_n_complex5' => 'scrappy doo,scooby doo,random_nested_rval,scooby doo,scrappy doo',
       'test_simple_n_complex6' => 'scooby doo,random_nested_rval,scrappy doo',
       'test_simple_n_complex7' => 'scooby doo,second_random_nested_rval,scrappy doo',
       'test_simple_n_complex8' => 'scooby doo,random_nested_rval,scooby doo,second_random_nested_rval,scrappy doo',
       'test_simple_n_complex9' => 'random_nested_rval,scooby doo,second_random_nested_rval,scrappy doo',
       'msg__published_tat_D1-D5' => 'blah blah blah',
       'PA_status_prefix'         => $PA_status_prefix_expect, 
   };
if(0){
   $href_raw = {
       #'msg__published_tat_D1-D5' => 'blah blah blah',
       #'PA_status_prefix'         => $PA_status_prefix_test, 
       'random' => {
          'nested' => {
             'lval' => 'random_nested_rval',
          },
          'nested2' => {
             'lval' => 'second_random_nested_rval',
          },
          'nested3' => {
             'lval' => '<deep_nesting->n1->n2->n3->n4->n5->n6->n7->n8->n9->n10->n11->n12->deep_lval>',
          },
       },
       'deep_nesting' => {
          'n1' => { 'n2' => { 'n3' => { 'n4' => { 'n5' => { 'n6' => {
                      'n7' => { 'n8' => { 'n9' => { 'n10' => { 'n11' => { 'n12' => {
                                  'deep_lval' => 'deep_rval',
       }, }, }, }, }, }, }, }, }, }, }, }, },
       'test_complex1'       => '<random->nested->lval>',
       'test_multi_complex'  => '<random->nested->lval>,<random->nested2->lval>',
       'test_deep_nested_complex' => '<random->nested3->lval>',
   };
   $href_interpolated__expected = {
       #'msg__published_tat_D1-D5' => 'blah blah blah',
       #'PA_status_prefix'         => $PA_status_prefix_expect, 
       'random' => {
          'nested' => {
             'lval' => 'random_nested_rval',
          },
          'nested2' => {
             'lval' => 'second_random_nested_rval',
          },
          'nested3' => {
             'lval' => 'deep_rval',
          },
       },
       'deep_nesting' => {
             'n1' => { 'n2' => { 'n3' => { 'n4' => { 'n5' => { 'n6' => {
                         'n7' => { 'n8' => { 'n9' => { 'n10' => { 'n11' => { 'n12' => {
                                     'deep_lval' => 'deep_rval',
       }, }, }, }, }, }, }, }, }, }, }, }, },
       'test_complex1'       => 'random_nested_rval',
       'test_multi_complex'  => 'random_nested_rval,second_random_nested_rval',
   };
}
   #----------------------------------------------
   # Run interpolation
   #----------------------------------------------
   my %raw_copy = %$href_raw;
   my $href_interpolated__code_returned = interpolate_vars_in_CFG( \%raw_copy ); # interpolate simple VARs only
   #----------------------------------------------
   foreach my $test_name ( sort keys %$href_interpolated__expected ){
      my_is_deeply( $href_interpolated__code_returned->{$test_name}, $href_interpolated__expected->{$test_name}, 
               "TEST($cnt): CFG Variable Interpolation unit test ..." );
      $cnt++;
   }
   my_is_deeply( $href_interpolated__code_returned, $href_interpolated__expected,  "TEST($cnt): CFG Variable Interpolation unit test ..." );

   #----------------------------------------------

   $Data::Dumper::Varname = "RAW";
   dprint(SUPER, scalar Dumper $href_raw );
   $Data::Dumper::Varname = "EXPECT";
   dprint(SUPER, scalar Dumper $href_interpolated__expected );
   $Data::Dumper::Varname = "GOT";
   dprint(SUPER, scalar Dumper $href_interpolated__code_returned );

   print_function_footer();
   return( $cnt );
}

#---------------------------------------------------------------------
# 'interpolate_vars_in_CFG' : provides new functionality in the CFG
#      files, which allows user to specify a reference to a variable
#      in the CFG file. When the reference is found, this code
#      interpolates (replaces) the variable with the value.
#
#      Note: there are two classes of references
#         (1) SIMPLE ... REF looks like => <var_name> 
#             simple case where user has following in CFG file
#              var_name = ...
#         (2) COMPLEX ... REF looks like => <hash_name->sub_hash_name->leaf> 
#             complex case where user has hash in CFG file
#             note: any depth of hash can be specified
#              <hash_name>
#                 <sub_hash_name>
#                     leaf = ...
#                 </sub_hash_name>
#              </hash_name>
#---------------------------------------------------------------------
sub interpolate_vars_in_CFG($) {
   print_function_header();
   my $href = shift;

   while( my @list = reach($href) ){
        dprint(HIGH, "The key/val pairs to interpolate:\n\t".join(", ", @list) ."\n" );
        my $leaf = pop(@list);  # trime leaf since we're processing it
        dprint(HIGH, "interpolating ===>@list\t=>$leaf\n" );
        my $value = interpolate_values($href, $leaf);
        dprint(HIGH, "       value=$value\n" );

        my $ref = \$href;
        for (@list) {
           $ref = \$$ref->{$_};
        }
        $$ref = $value;
   }
   return ($href);
}

#-----------------------------------------------------------------------------
#  sub 'interpolate_values' : 
#-----------------------------------------------------------------------------
sub interpolate_values($$){
   print_function_header();
   my ($href, $leaf) = (shift,shift);
   my $value = &process_simple_variables($href,$leaf);

   $value =~ s/\VAR_STRT_KEY/</g;
   $value =~ s/\VAR_ENDG_KEY/>/g;
      $value = process_complex_variable_references($href,$value);
   $value =~ s/\VAR_STRT_KEY/</g;
   $value =~ s/\VAR_ENDG_KEY/>/g;

   print_function_footer();
   return($value);
}

#-----------------------------------------------------------------------------
#  sub 'process_simple_variables':
#-----------------------------------------------------------------------------
sub process_simple_variables($$){
   print_function_header();
   my $href_config = shift;
   my $leaf        = shift;

   # Make copy of '$leaf' to avoid corrupting ...
   my $value=$leaf; 
   # *IF* leaf (RHS val) contains hash dereference operator ('->'), need diff
   #    subroutine to process it; process only simple variable references here
   if( $value =~ m/<(\S+?[^-])>/ ){
      #-------------------------------
      # Extract var name, which must start w/'<' and end with '>'.
      #    The expression between the markers can be simple (i.e. alpha-numeric variable name)
      #    or complex varables. Complex vars have sone or de-reference operators, '->', and
      #    skipped in this sub.
      #    Loop over variable in $value until all are interpolated
      while( $value =~ m/<(\S+?[^-])>/g ){
        my $tag = $1;
        next if( $tag =~ m/\\<(\w+?)>/ || $tag =~ m/<\S+?->\S+>/g );
        dprint(SUPER, "Leaf            => $leaf\n" );
        dprint(SUPER, "... TAG in leaf => '$tag'\n"  );
        dprint(SUPER, "--------------------------------\n" );
        my $hashed_leaf = $href_config->{$1};
        dprint(SUPER, "Hashing TAG yields => '$hashed_leaf'\n" );
        if( isa_aref($hashed_leaf) ){
           eprint( "In '$tag': Expected string where array was found!\n\t" .pretty_print_aref($hashed_leaf). "\n" );
           halt( LOW );
           $hashed_leaf = pretty_print_aref($hashed_leaf);
        }
        if( defined $hashed_leaf ){
           $leaf =~ s/(<$tag>)/$hashed_leaf/g;
           dprint(SUPER, "Completed Interpolation on Leaf = '$leaf'\n" );
        }else{
           # remove this TAG so we don't re-process it
           $leaf =~ s/<${tag}>/VAR_STRT_KEY${tag}VAR_ENDG_KEY/g;
        }
        dprint(HIGH, "Done interpolating leaf: '$value' => '$leaf' \n" );
        dprint(HIGH, "-------------------------------------------\n" );
        $value = $leaf;
      }
      # Recursive call ... until there's no more variables to interpolate.
      $value = &process_simple_variables($href_config, $value);
   }else{
      # If there's no simple variables in the RHS val, do nothing!
      dprint(CRAZY, "No s-i-m-p-l-e variables to interpolate for '$leaf'\n" );
   }
   
   print_function_footer();
   return( $value );
}

#-----------------------------------------------------------------------------
#  sub 'process_complex_variable_references':
#-----------------------------------------------------------------------------
sub process_complex_variable_references($$){
   print_function_header();
   my $href_config = shift;
   my $leaf        = shift;

   dprint(SUPER, "--------------------------------\n" );
   # Make copy of '$leaf' to avoid corrupting ...
   my $value=$leaf; 
   # *IF* the leaf (a RHS val) contains hash dereference operator ... '->', need
   #    process it here. Assumption is that all simple variable references
   #    with the '->' operator are handles elsewhere
   if( $value =~ m/<\S+?->\S+?\w>/ ){
     my $skip_varnames;
     my $skip_cnt=0;
     #while( $value =~ m/<([_\w]+(->[_\w]+?)+\w)>/g ){
     while( $value =~ m/(<\S+?->\S+?\w>)/g ){
        my $tag = $1;
        dprint(SUPER, "Complex Leaf    => $leaf\n" );
        dprint(SUPER, "... TAG in Leaf => '$tag'\n"  );
        dprint(SUPER, "--------------------------------\n" );
        next if( $tag =~ m/\\<\w+[->\w+]+>/ );
        # 1 by 1, capture each complex variable name (i.e. <blah_1->blah_2->....->blah_n>)
        my $complex_var_name = $tag;

        # When CFG has a reference to a variable that doesn't exist, can
        #    cause an infinite loop. Use a counter to break-out of the loop.
        if( $skip_varnames=~ m/$complex_var_name/ ){
           $skip_cnt++;
           if( $skip_cnt <= 3 ){
              next;
           }else{
              print_function_footer();
              return($value);
           }
        }
        dprint(CRAZY, "my complex var = '$complex_var_name'\n" );
        #$value = resolving_hierarchy($href_config, $leaf);
        #$value = find_my_value($href_config, $value);
        my $interpolated_value = resolving_hierarchy($href_config, $complex_var_name);
        if( defined $interpolated_value && $interpolated_value =~ m/.+/ ){
           $value =~ s/$complex_var_name/$interpolated_value/g;
           $value = process_complex_variable_references($href_config, $value);
        # PJ : 8/2021 : Yes, this next line is horrible hard-code, but don't want to
        #     invest more time given fires burning that demand my attention.
        }else{ 
           if( $complex_var_name !~ m/thispolicy|jira|name|manager|director/ ){
              dprint(LOW, "\$interpolated_value=$interpolated_value\n" );
              eprint("Reference to variable '$complex_var_name' not in CFG! ...\n" );
              wprint( "<WARNING>, above error may cause unintended results!!!\n =====> Continue? (*/N)" );
                 # Halt execution, prompt user to continue ... especially important for avoiding
              #   tons of bad emails during batch calls.
              my $response=<STDIN>;
              if( $response eq "N\n" || $response eq "n\n"){
                 iprint( "Quitting ... fix errors before running again!\n" );
                 exit(-1);
              }
           }
           # Add this var to the skip list since it wasn't found in CFG
           $skip_varnames.= $complex_var_name;
        }
        dprint(HIGH, "Almost done interpolating leaf: '$leaf' => '$value'\n" );
        # Recursive call ... until there's no more variables to interpolate.
        $value = &process_simple_variables($href_config, $value);
        dprint(HIGH, "Done interpolating leaf: '$leaf' => '$value'\n" );
     }
   }else{
      # If there's no complex variable in the RHS val, do nothing!
      dprint(CRAZY, "No c-o-m-p-l-e-x variables to interpolate for '$leaf'\n" );
   }
   print_function_footer();
   return( $value );
}

#-----------------------------------------------------------------------------
#  sub 'resolving_hierarchy' : process variable names that contain
#     the de-reference operator
#-----------------------------------------------------------------------------
sub resolving_hierarchy($$){
   print_function_header();
   my $href_config = shift;
   my $placeholder_title = shift;

   my @split_placeholders; 
   while ($placeholder_title =~ /<(.*)>/g){
     my $placeholder_without_tags = $1;
     @split_placeholders = split('->', $placeholder_without_tags);
      dprint(HIGH, "Hierarchical TAG split :". join(',', @split_placeholders) ."\n" );
   }
   foreach my $individual_placeholder (@split_placeholders){
      dprint(HIGH, "Assigning hierarchical values:". scalar(Dumper $href_config->{$individual_placeholder}) ."\n" );
     $href_config = $href_config->{$individual_placeholder};
    # my $value = resolving_hierarchy($href_interpolation, $placeholder_title);
   }

   my $leaf_value = $href_config;
   return( $leaf_value );
}
#---------------------------------------------------------------------------
#  Subroutine 'TEST__get_email_lists' :  
#     Setup data structure to test escalation scheme and extraction of
#     special fields works, such as 'manager', 'misc_mgr', 'director' etc
#---------------------------------------------------------------------------
sub TEST__get_email_lists($){
   print_function_header();
   my $cnt = shift;
   my $href = {
      'escalations' => {
         'lvl1' => {
                     'from' => 'juliano',
                     'to' => 'fields/assignee/name',
                     'cc' => 'manager fields/reporter/name',
                   },
         'lvl2' => {
                     'to' => 'fields/assignee/name',
                     'cc' => 'manager misc_mgr fields/reporter/name',
                   },
         'lvl3' => {
                     'to' => 'director',
                     'cc' => 'manager misc_mgr fields/assignee/name fields/reporter/name',
                   },
         'lvl4' => {
                     'to' => 'vp',
                     'cc' => 'director misc_mgr manager fields/assignee/name fields/reporter/name',
                   }
      },
   };
    
   my @expected;
   my @levels;

      $cnt++;
      @expected = qw( juliano );
      @levels = get_user_list_From( 'lvl1', $href->{escalations}{lvl1} );
      my_is_deeply( \@levels, \@expected, "TEST($cnt); CFG params present..." );

      $cnt++;
      @expected = qw( manager fields/reporter/name );
      @levels = get_user_list_CC( 'lvl1', $href->{escalations}{lvl1} );
      my_is_deeply( \@levels, \@expected, "TEST($cnt); CFG params present..." );

      $cnt++;
      @expected = qw( manager misc_mgr fields/reporter/name );
      @levels = get_user_list_CC( 'lvl2', $href->{escalations}{lvl2} );
      my_is_deeply( \@levels, \@expected, "TEST($cnt); CFG params present..." );

      $cnt++;
      @expected = qw( manager misc_mgr fields/assignee/name fields/reporter/name );
      @levels = get_user_list_CC( 'lvl3', $href->{escalations}{lvl3} );
      my_is_deeply( \@levels, \@expected, "TEST($cnt); CFG params present..." );

      $cnt++;
      @levels = get_user_list_CC( 'lvl4', $href->{escalations}{lvl4} );
      @expected = qw( director misc_mgr manager fields/assignee/name fields/reporter/name );
      my_is_deeply( \@levels, \@expected, "TEST($cnt); CFG params present..." );

      $cnt++;
      @expected = qw( fields/assignee/name);
      @levels = get_user_list_To( 'lvl1', $href->{escalations}{lvl1} );
      my_is_deeply( \@levels, \@expected, "TEST($cnt); CFG params present..." );

      $cnt++;
      @expected = qw( fields/assignee/name );
      @levels = get_user_list_To( 'lvl2', $href->{escalations}{lvl2} );
      my_is_deeply( \@levels, \@expected, "TEST($cnt); CFG params present..." );

      $cnt++;
      @expected = qw( director );
      @levels = get_user_list_To( 'lvl3', $href->{escalations}{lvl3} );
      my_is_deeply( \@levels, \@expected, "TEST($cnt); CFG params present..." );

      $cnt++;
      @expected = qw( vp );
      @levels = get_user_list_To( 'lvl4', $href->{escalations}{lvl4} );
      my_is_deeply( \@levels, \@expected, "TEST($cnt); CFG params present..." );
   return( $cnt );
}

#------------------------------------------------------------------------------
# sub 'get_user_list_From' :
#------------------------------------------------------------------------------
sub get_user_list_From($$){
   print_function_header();
   return( get_user_list( shift, shift, 'from' ) );
}

#------------------------------------------------------------------------------
# sub 'get_user_list_To' :
#------------------------------------------------------------------------------
sub get_user_list_To($$){
   print_function_header();
   return( get_user_list( shift, shift, 'to' ) );
}

#------------------------------------------------------------------------------
# sub 'get_user_list_CC' :
#------------------------------------------------------------------------------
sub get_user_list_CC($$){
   print_function_header();
   return( get_user_list( shift, shift, 'cc' ) );
}

#------------------------------------------------------------------------------
# sub 'get_user_list' :
#------------------------------------------------------------------------------
sub get_user_list($$){
   print_function_header();
   my $policy_name     = shift;
   my $href_escalation = shift;
   my $key             = shift;

   my @levels;
   if( defined $href_escalation ){
      @levels = split(/\s+/, $href_escalation->{$key});
      @levels = unique_scalars( \@levels );
      unless( scalar(@levels) > 0){
         eprint( "The escalation chain specified no one in the '$key' field!!\n" );
      }
   }else{
      eprint( "The named escalation field does not exist!" );
   }
   dprint( CRAZY, "People listed in Email field '$key' for policy '$policy_name':\n\t". pretty_print_aref(\@levels). "\n" );
   print_function_footer();
   return( @levels );
}


#-------------------------------------------------------------------------------------
#  subroutine 'TEST__query_orgdata_by_manager' : there are 4 unique cases to 
#     consider, so this sub includes the data for each, as well as the header
#     (column title) row.
#-------------------------------------------------------------------------------------
sub TEST__query_orgdata_by_manager1(){
   print_function_header();
   my $aref_psql_data   = [
          'id|firstname|lastname|email|uid|badge|title|job_function|is_layout_engineer|is_a_manager|manager_email|mgr_chain|empcode|photo_link|site|pager|b_unit|b_group|b_group_a|hire_date|user_notes|last_date|emp_type|support_type|b_group_m|updated_at',
'4165|Warren|Anderson|warrena|23331|23257|Group Dir, R&D|CktDesign;coSimVerif,SystemArch,ComputeGRID,ESD,bbSimSAE,EngrMangr|f|Y|toffolon|toffolon kunkel sassineg aart|Active|https://lookup.synopsys.com/images/badge-photos/23257.jpg|146||Solutions Group|Solutions Group|SG|2014-09-18||0001-01-01|Employee|SG-MSIP|SG|2021-04-28 13:20:29.740426',
];
   print_function_footer();
   return( $aref_psql_data );
}


sub TEST__query_orgdata_by_manager2(){
   print_function_header();
   my $aref_psql_data   = [
          'id|firstname|lastname|email|uid|badge|title|job_function|is_layout_engineer|is_a_manager|manager_email|mgr_chain|empcode|photo_link|site|pager|b_unit|b_group|b_group_a|hire_date|user_notes|last_date|emp_type|support_type|b_group_m|updated_at',

'4165|Warren|Anderson|warrena|23331|23257|Group Dir, R&D|CktDesign;coSimVerif,SystemArch,ComputeGRID,ESD,bbSimSAE,EngrMangr|f|Y|toffolon|toffolon kunkel sassineg aart|Active|https://lookup.synopsys.com/images/badge-photos/23257.jpg|146||Solutions Group|Solutions Group|SG|2014-09-18||0001-01-01|Employee|SG-MSIP|SG|2021-04-28 13:20:29.740426',

'9107|Patrick|Juliano|juliano|38371|34039|ASIC Digital Design Engr, Sr Staff|SystemArch;ComputeGRID,DigFuncVerif,DigDesign|f|Y|warrena|warrena toffolon kunkel sassineg aart|Active|https://lookup.synopsys.com/images/badge-photos/34039.jpg|2104||Solutions Group|Solutions Group|SG|2017-07-31|USA|0001-01-01|Employee|SG-MSIP|SG|2021-04-28 13:20:29.740426 ',

'5670|Bhuvan|Challa|bhuvanc|37779|33162|A&MS Circuit Design Engr, Sr I|CktDesign;DigDesign,Layout,DigImplement,CAD,Release/QA,ComputeGRID,UDE,EM/IR,bbSimSAE,PNR,Falcon,Foundry,ESD|t|N|juliano|juliano warrena toffolon kunkel sassineg aart|Active|https://lookup.synopsys.com/images/badge-photos/33162.jpg|146||Solutions Group|Solutions Group|SG|2017-10-09||0001-01-01|Employee|SG-MSIP|SG|2021-04-28 13:20:29.740426',

'13551|Zhihao|Lv|zhihaolv|10039590|39590|ASIC Digital Design Engr, Sr I|DigDesign;ComputeGRID,DigFuncVerif|f|N|liyuan|liyuan zeshi rbwang jeffy ashfaq toffolon kunkel sassineg aart|Active|https://lookup.synopsys.com/images/badge-photos/39590.jpg|2032||Solutions Group|Solutions Group|SG|2018-12-19||0001-01-01|Employee|SG-MSIP|SG|2021-04-28 13:20:29.740426'
   ];
   print_function_footer();
   return( $aref_psql_data );
}

#------------------------------------------------------------------------------
# Check if the parameters req'd in the CFG are present.
#-------------------------------------------------------------------------------
sub TEST__check_reqd_params_in_cfg($$){
   print_function_header();
   my $cnt       = shift;
   my $fname_cfg = shift;

   my ($href_cfg, $aref) = load_config_file( $fname_cfg );
   my @warning_msgs = @$aref;

   my @expected_msgs;
   push(@expected_msgs, "CFG file missing param 'psql_filename' => using default 'psql_filename=psql.orgdata.txt'!" ); 
   push(@expected_msgs, "CFG file missing param 'maxResults' => using default 'maxResults=40'!" );
   push(@expected_msgs, "CFG file missing param 'outputFormat' => using default 'outputFormat=xml'!" );
   push(@expected_msgs, "CFG file missing param 'filename__jql_output' => using default 'filename__jql_output=jira'!" );
   push(@expected_msgs, "CFG file missing param 'filename__xls_output' => using default 'filename__xls_output=jira.xlsx'!" );
   my $tmp=++$cnt;
   $cnt+=5;
   my $msg = "TEST($tmp-$cnt): req'd CFG params present...";

   dprint(CRAZY, "TEST (): req'd CFG params present ... expected warning messages: \n\t" .join("\n\t", @expected_msgs). "\n" );
   dprint(CRAZY, "TEST (): req'd CFG params present ... got warning messages: \n\t" .join("\n\t", @warning_msgs). "\n" );
   # check each message expected vs received
   my_is_deeply( \@warning_msgs, \@expected_msgs, $msg);

   print_function_footer();
   return( $cnt );
}

#-------------------------------------------------------------------------------
# Check if the values specified by params in the CFG are valid.
#-------------------------------------------------------------------------------
sub TEST__check_policy_rules($$){
   print_function_header();
   my $cnt = shift;
   my $fname_cfg = shift;

   my ($href_cfg, undef)  = load_config_file( $fname_cfg );
   my @warning_msgs = check_policy_rules($href_cfg);

   my @expected_msgs;
      push(@expected_msgs, "Policy 'policy3' ... 'jql_suffix' not defined." );
      push(@expected_msgs, "Policy 'policy3' ... invalid JQL 'invalid' specified." );
      push(@expected_msgs, "Policy 'policy4' ... 'active' not defined." );
      push(@expected_msgs, "Policy 'policy4' ... 'jql_suffix' not defined." );
      push(@expected_msgs, "Policy 'policy4' ... invalid ESCALATION 'invalid' specified." );
      push(@expected_msgs, "Policy 'policy5' ... 'active' not defined." );
      push(@expected_msgs, "Policy 'policy5' ... 'jql_suffix' not defined." );
      push(@expected_msgs, "Policy 'policy5' ... invalid TEMPLATE 'invalid' specified." );
      push(@expected_msgs, "Policy 'policy6' ... 'jql_suffix' not defined." );
      push(@expected_msgs, "Policy 'policy6' ... 'active' field value '1' invalid. Must assign 'TRUE' or 'FALSE'." );
      push(@expected_msgs, "Policy 'policy6' ... invalid JQL 'invalid' specified." );
      push(@expected_msgs, "Policy 'policy6' ... invalid ESCALATION 'invalid' specified." );
      push(@expected_msgs, "Policy 'policy7' ... 'jql_suffix' not defined." );
      push(@expected_msgs, "Policy 'policy7' ... 'active' field value 'YES' invalid. Must assign 'TRUE' or 'FALSE'." );
      push(@expected_msgs, "Policy 'policy7' ... invalid ESCALATION 'invalid' specified." );
      push(@expected_msgs, "Policy 'policy7' ... invalid TEMPLATE 'invalid' specified." );
   dprint(CRAZY, "TEST (): policy rules ... expected warning messages: \n\t" .join("\n\t", @expected_msgs). "\n" );
   dprint(CRAZY, "Expect array: \n\t" .join("\n\t", @expected_msgs). "\n" );
   dprint(CRAZY, "Got array   : \n\t" .join("\n\t", @warning_msgs ). "\n" );

   # check each message expected vs received
   for( my $i=1; $i < scalar(@expected_msgs); $i++){
      $cnt++;
      dprint(CRAZY, "Got array   : \n\t". $warning_msgs[$i]  ."\n" );
      dprint(CRAZY, "Expect array: \n\t". $expected_msgs[$i] ."\n" );
      my_is_deeply( $warning_msgs[$i], $expected_msgs[$i], "TEST($cnt): policy rules ..." );
   }

   my (@valid_got, @valid_expected);
   @valid_expected = ( TRUE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE );
   $valid_got[0] = $href_cfg->{policies}{policy0}{valid};
   $valid_got[1] = $href_cfg->{policies}{policy1}{valid};
   $valid_got[2] = $href_cfg->{policies}{policy2}{valid};
   $valid_got[3] = $href_cfg->{policies}{policy3}{valid};
   $valid_got[4] = $href_cfg->{policies}{policy4}{valid};
   $valid_got[5] = $href_cfg->{policies}{policy5}{valid};
   $valid_got[6] = $href_cfg->{policies}{policy6}{valid};
   $valid_got[7] = $href_cfg->{policies}{policy7}{valid};
   $valid_got[8] = $href_cfg->{policies}{policy8}{valid};
   dprint(CRAZY, "valid got    = ". pretty_print_aref( \@valid_got)      ."\n" );
   dprint(CRAZY, "valid expect = ". pretty_print_aref( \@valid_expected) ."\n" );
   # check each message expected vs received
   for( my $i=0; $i < scalar(@valid_expected); $i++){
      $cnt++;
      dprint(CRAZY, "Valid Got array   : ". $valid_got[$i]  ."\n" );
      dprint(CRAZY, "Valid Expect array: ". $valid_expected[$i] ."\n" );
      my_is_deeply( $valid_got[$i], $valid_expected[$i], "TEST($cnt): CFG params values are present ..." );
   }
   print_function_footer();
   return( $cnt );
}

#-------------------------------------------------------------------------------
sub my_is_deeply($$$){
   my $retval = is_deeply( shift, shift, shift); 
   unless($retval){
     fatal_error( "Error: '" .get_call_stack(). "\n" );
   }
}
  
#-------------------------------------------------------------------------------
# Check if the 3 required fields are defined in policy.
#       Check that the named parameter exists in CFG
#-------------------------------------------------------------------------------
sub check_policy_rules($){
   print_function_header();
   my $href_cfg = shift;

   my @msgs; 
   my $href = $href_cfg->{policies};

   foreach my $policy ( sort keys %$href ){
      my $policy_is_valid = TRUE;
      my $jql        = $href->{$policy}{jql}        ;
      my $escalation = $href->{$policy}{escalation} ;
      my $template   = $href->{$policy}{template}   ;
      my $active;
      if( defined $href->{$policy}{active} ){
         $href->{$policy}{active} = uc($href->{$policy}{active}) ;
         $active     = $href->{$policy}{active}     ;
      }

      my @legal_policy_fields = qw( jql escalation template active jql_suffix);
      my @this_policy_fields  = keys %{$href->{$policy}};

      #---------------------------------------------------------------
      # Check this policy to (1) ensure expected fields are present
      #                      (2) flag unexpected/invalid fields
      my $msg_prefix = "Policy '$policy' ...";
      {
         my ($aref_common, $aref_LegalOnly, $aref_ThisPolicyOnly, $bool__lists_equiv) =
                     compare_lists( \@legal_policy_fields, \@this_policy_fields );

         # (1) ensure expected fields are present
         foreach my $field ( @$aref_LegalOnly ){
            my $msg = "$msg_prefix '$field' not defined.";
            eprint( "$msg\n" );
            push(@msgs, $msg);
            $policy_is_valid = FALSE;
         }
         # (2) flag unexpected/invalid fields
         foreach my $field ( @$aref_ThisPolicyOnly ){
            my $msg = "$msg_prefix has unrecognized field: '$field'";
            if( $main::VERBOSE >= LOW ){
               push(@msgs, $msg);
            }
         }
      }
      #---------------------------------------------------------------
      
      if( defined $active && $active =~ m/\w+/ ){
         unless( $active eq 'TRUE' || $active eq 'FALSE' ){
            my $msg = "$msg_prefix 'active' field value '$active' invalid. Must assign 'TRUE' or 'FALSE'.";
            push(@msgs, $msg);
            $policy_is_valid = FALSE;
            dprint(LOW, "$msg\n" );
         }
      }
      # Check that the named parameter exists in CFG
      unless( defined $href_cfg->{jira_queries}{$jql} ){
         my $msg = "$msg_prefix invalid JQL '$jql' specified.";
         push(@msgs, $msg);
         $policy_is_valid = FALSE;
         dprint(LOW, "$msg\n" );
      }
      if( defined $href_cfg->{escalations}{$escalation} ){
         unless( defined $href_cfg->{escalations}{$escalation}{from} ){
            my $msg = "$msg_prefix has invalid escalation TEMPLATE '$escalation' because the 'from' field is not defined.";
            push(@msgs, $msg);
            $policy_is_valid = FALSE;
            dprint(LOW, "$msg\n" );
         }
         unless( defined $href_cfg->{escalations}{$escalation}{to} ){
            my $msg = "$msg_prefix has invalid escalation TEMPLATE '$escalation' because the 'to' field is not defined.";
            push(@msgs, $msg);
            $policy_is_valid = FALSE;
            dprint(LOW, "$msg\n" );
         }
      }else{
         my $msg = "$msg_prefix invalid ESCALATION '$escalation' specified.";
         push(@msgs, $msg);
         $policy_is_valid = FALSE;
         dprint(LOW, "$msg\n" );
      }
      if( defined $href_cfg->{email_templates}{$template} ){
         unless( defined $href_cfg->{email_templates}{$template}{subject} ){
            my $msg = "$msg_prefix has invalid email TEMPLATE '$template' because the 'subject' field is not defined.";
            push(@msgs, $msg);
            $policy_is_valid = FALSE;
            dprint(LOW, "$msg\n" );
         }
         unless( defined $href_cfg->{email_templates}{$template}{body} ){
            my $msg = "$msg_prefix has invalid email TEMPLATE '$template' because the 'body' field is not defined.";
            push(@msgs, $msg);
            $policy_is_valid = FALSE;
            dprint(LOW, "$msg\n" );
         }
      }else{
         my $msg = "$msg_prefix invalid TEMPLATE '$template' specified.";
         push(@msgs, $msg);
         $policy_is_valid = FALSE;
         dprint(LOW, "$msg\n" );
      }
      # if *ANY* cfg param is invalid, the policy is invalid
      $href->{$policy}{valid} = $policy_is_valid; 
   }
   print_function_footer();
   return( @msgs );
}

#-----------------------------------------------------------
#  Subroutine 'load_config_file' :  
#-----------------------------------------------------------
sub load_config_file ($) {
   print_function_header();
   my $fname = shift;

   unless( -e abs_path($fname) ){
      fatal_error( "Config file doesn't exist: '$fname'\n" ); 
   }
   my $conf = Config::General->new(
       -ConfigFile => $fname,
       -MergeDuplicateBlocks  => TRUE,
   );
   my %config = $conf->getall;

   my @warnings = check_config_file( \%config );
   if( scalar(@warnings) > 0 ){
      wprint( join("\n-W- ", @warnings) );
      print "\n";
   }

   dprint(CRAZY, "Policy CFG file loaded in HREF...\n".
                              scalar(Dumper \%config)."\n" );

   print_function_footer();
   return( \%config, \@warnings );
}

#-----------------------------------------------------------
#  Subroutine 'check_config_file' : run some basic
#     checks that captures decisions made during dev. For
#     example, check if the parameters req'd in the CFG
#     are present.
#-----------------------------------------------------------
sub check_config_file($) {
   print_function_header();
   my $href_cfg = shift;

   my @msgs;
   my @cfg_reqd = qw(
              highest_level_mgr       psql_filename
              maxResults              outputFormat
              filename__jql_output    filename__xls_output
              jira_env                jira_fields
              escalations             email_templates
              jira_queries            policies
   );
   my $href_defaults = {
      'maxResults'    => 40,
      'psql_filename' => 'psql.orgdata.txt',
      'jira_env'      => 'prod',
      'outputFormat'  => 'xml',
      'filename__jql_output' => 'jira',
      'filename__xls_output' => 'jira.xlsx',
      'highest_level_mgr' => "$ENV{USER}",
   };
   foreach my $param ( @cfg_reqd ){
      unless( defined $href_cfg->{$param} ){
         my $default =  $href_defaults->{$param} || NULL_VAL;
         push(@msgs, "CFG file missing param '$param' => using default '$param=$default'!");
         $href_cfg->{$param} = $default;
      }
   }
   dprint(CRAZY, "CFG file problems identified:\n\t" .join("\t\n",@msgs). "\n" );
   print_function_footer();
   return( @msgs );
}

################################
# A package must return "TRUE" #
################################

1;
 
__END__
