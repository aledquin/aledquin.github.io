#!/depot/perl-5.14.2/bin/perl

use strict;
use Data::Dumper;
use Config::General;
use File::Copy;
use Getopt::Long;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Cwd qw( abs_path );
use Carp qw(cluck confess croak);
use Excel::Writer::XLSX;

use lib dirname(abs_path $0) . '/../lib/';
use Text::ASCIITable;
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
use SynopsysOrgData;

our $PROGRAM_NAME = $0; 
our $VERSION      = '1.0';
#----------------------------------#
our $DEBUG     = NONE;
our $VERBOSITY = NONE;
#----------------------------------#
our $href_org; # if you change this var name, change header added to CFG

BEGIN { my $AUTHOR = 'Patrick Juliano'; header(); } 
   Main();
END { footer(); }

########  YOUR CODE goes in Main  ##############
sub Main {
	 my( $opt_cfg, $opt_debug, $opt_verbosity, $opt_help,
           $opt_nousage_stats ) = process_cmd_line_args();

	 utils__script_usage_statistics( abs_path($PROGRAM_NAME), $VERSION ) unless( defined $opt_debug || $DEBUG || $opt_nousage_stats ); 

   #     data struct that can be loaded.
   load_href_cfg_file( $opt_cfg );
   my $max_num_mgrs = 0;
   foreach my $e ( keys %$href_org ){
      my(@mgr_titles);
      #print "Employee '$e'\n";
      my $aref = $href_org->{$e}{mgr_chain};
      foreach my $mgr ( @$aref ){
         unless( $href_org->{$mgr}{title} =~ m/\S+/ ){
            vwprint(LOW, "'$e' has mgr '$mgr' w/title '". $href_org->{$mgr}{title} ."'\n");
         }
         push(@mgr_titles, $href_org->{$mgr}{title} );
      }
      $href_org->{$e}{ordered_list_of_mgr_titles}= \@mgr_titles;
      $max_num_mgrs = get_max_val( $max_num_mgrs , scalar(@mgr_titles) );
   }

   iprint( "Found Max # Levels of Mgmt: '$max_num_mgrs'\n" );
   #------------------------------
   # OPEN xlsx workbook OBJ
   my $fname_XLS  = 'snps-org-structure.xlsx';
   my $workbook = Excel::Writer::XLSX->new($fname_XLS);
   fatal_error( "FAILED: Unable to create workbook.\n") unless( defined $workbook ); 
   viprint( MEDIUM, "Creating XLS '$fname_XLS'...\n" );

   iprint( "Creating Org Structure Data Tables now...\n");
   # Generate the tables in ASCII friendly formatting
   my $txt_table_assignee_vs_mgr_names = create_table_mgr_names( $max_num_mgrs, $href_org );
   my $head_of_table = join("\n", (split(/\n/, $txt_table_assignee_vs_mgr_names))[0..10]);
   dprint(LOW, "\n$head_of_table\n" );
   #---
   my ($txt_table_assignee_vs_mgrs , $txt_table_mgr_titles_per_lvl)
                    = create_table_uniq_mgr_titles( $max_num_mgrs, $href_org );
   $head_of_table = join("\n", (split(/\n/, $txt_table_assignee_vs_mgrs))[0..10]);
   dprint(LOW, "\n$head_of_table\n" );
   #---
   $head_of_table = join("\n", (split(/\n/, $txt_table_mgr_titles_per_lvl))[0..10]);
   dprint(LOW, "\n$head_of_table\n" );

   iprint( "Creating XLSX ...\n" );
   # Save the data tables to a single XLSX, 1 sheet per table
   write_table_to_xls( $workbook, 'User Map', $txt_table_assignee_vs_mgr_names );
   write_table_to_xls( $workbook, 'Mgr Map', $txt_table_assignee_vs_mgrs );
   write_table_to_xls( $workbook, 'LVLs', $txt_table_mgr_titles_per_lvl );

   $workbook->close() or confess "Error closing XLS file: '$fname_XLS'.\n";
   iprint("Wrote table to XLS: '$fname_XLS'\n" );
   exit(0);
}
############    END Main    ####################

#------------------------------------------------------------------------------
# 
#------------------------------------------------------------------------------
sub load_href_cfg_file($){
   my $opt_cfg = shift;
   iprint( "Read config file: '$opt_cfg'\n" );
   my $header  = "package CFG;\n";
      $header .= "use Exporter;\n";
      $header .= "use strict;\n";
      $header .= 'our @ISA = qw(Exporter);'."\n";
   # Must already have 'href_org' declared using "our $href_org"
   my $footer  = '$main::href_org = $href;'."\n";
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

#------------------------------------------------------------------------------
   # Add header/footer to cfg file to turn it into a 
#  Write a sheet to an existing Excel workbook (i.e. XLSX)
#------------------------------------------------------------------------------
sub write_table_to_xls($$$){
   print_function_header();
   my $workbook   = shift;
   my $sheet_name = shift;
   my $table_txt  = shift;

   
   my $format;
   my $worksheet = $workbook->add_worksheet($sheet_name);
   $format = $workbook->add_format();
   $format->set_bold(); 
   #$format->set_bg_color( 'yellow' );

   # breakup the table, a single string, into individual lines
   my @table_lines = split(/\n/, $table_txt);

   my $col = 1;   
   my %col_width;
   foreach my $line ( @table_lines ){
      if( $line =~ m/Assignee/ ){
         foreach my $cell_val ( split(/\|/, $line) ){
	          $col_width{$col} = length( $cell_val );
	          $col++;
	       }
	       next; # should break loop after just a few lines
	    }
   }

   my $row = 1;
   foreach my $line ( @table_lines ){
      $col = 1;   
      foreach my $cell_val ( split(/\|/, $line) ){
         # set_column( $first_col, $last_col, $width, $format, $hidden, $level, $collapsed )
	       $worksheet->set_column( $col, $col, $col_width{$col});
	       $worksheet->write($row, $col, $cell_val, $format);
	       $col++;
      }
	    $row++;
   }

   return( );
}

#------------------------------------------------------------------------------
#   Generate Table => 
#   Assignee   Mgr1   Mgr2  Mgr3    Mgr4     Mgr5    etc
#   juliano    -       -    warrena toffolon kunkel  etc
#------------------------------------------------------------------------------
sub create_table_mgr_names($$){
   my $max_num_mgrs = shift;
   my $href_org     = shift;


   my $t = Text::ASCIITable->new({ headingText => "SNPS Org Data" });
   $t->setOptions( {undef_as=>"-", alignHeadRow=>'center'} );
   
   # Build table based on manager names
   my (@col_hdrs) = build_col_headers("Mgr", $max_num_mgrs);
   $t->setCols(@col_hdrs);

   foreach my $e ( sort keys %$href_org ){
      my $aref = $href_org->{$e}{mgr_chain};
      if( !defined $aref ){  
         wprint( "Mgr Chain not defined for employee '$e'! \n" );
      }else{
         my @mgr_names = pad_cols( $max_num_mgrs, $aref );
         $t->addRow( $e, @mgr_names );
      }
   }
   $t->addRowLine();

   return( $t );
}

#------------------------------------------------------------------------------
#   Generate 1st Table => 
#   Assignee   Mgr1   Mgr2  Mgr3    Mgr4  Mgr5   etc
#   juliano    -       -    GrpDir  SrVP  GM     etc
#
#   Generate 2nd Table => 
#   Assignee   Mgr1       Mgr2         Mgr3    etc
#   Mangers    SupI       AE, SrI      etc
#              SupII      MgrI         etc
#              MgrI       MgrII        etc
#              MgrII      R&D Eng      etc
#              Sr Mgr     Sr Mgr       etc
#                         Dir, R&D     etc
#                         R&D, Staff   etc
#------------------------------------------------------------------------------
sub create_table_uniq_mgr_titles($$){
   print_function_header();
   my $max_num_mgrs = shift;
   my $href_org     = shift;

   my $col_label_prefix = "Mgr";

   my $table1 = Text::ASCIITable->new({ headingText => "SNPS Org Data" });
   $table1->setOptions( {undef_as=>"-", alignHeadRow=>'center'} );

   my $table2 = Text::ASCIITable->new({ headingText => "SNPS Org Data" });
   $table2->setOptions( {undef_as=>"-", alignHeadRow=>'center'} );

   # Build table based on manager titles
   my (@col_hdrs) = build_col_headers( $col_label_prefix , $max_num_mgrs);
   $table1->setCols(@col_hdrs);
   $table2->setCols(@col_hdrs);

   my $href_lvl;
   foreach my $e ( sort keys %$href_org ){
      dprint(CRAZY, "Employee='$e'\n" );
      my $aref = $href_org->{$e}{ordered_list_of_mgr_titles};
      unless( defined $aref && grep(/[^-]+/, @$aref) ){
         dprint(MEDIUM, "Dropping '$e' from Mgr map table\n" );
         dprint(MEDIUM, pretty_print_aref( $aref ) . "\n" );
         next;
      }
      dprint(CRAZY, join("->", @$aref) ."\n" );
      my @mgr_titles = pad_cols( $max_num_mgrs, $aref );
      my $lvl = 1;
      $table1->addRow( $e, @mgr_titles );
      foreach my $title ( @mgr_titles ){
         $href_lvl->{$lvl}{$title}++;
         $lvl++;
      }
   }
   $table1->addRowLine();
   #---------------------------------------------------------
   my @unique_mgrs_per_level;
   foreach my $lvl ( sort keys %$href_lvl ){
      my (@mgr_titles) = keys %{$href_lvl->{$lvl}};
      dprint(CRAZY, join("->", @mgr_titles) ."\n" );
      my $col_val =  join("\n", sort @mgr_titles);
      push( @unique_mgrs_per_level, $col_val );
   }
   $table2->addRow( 'Managers', @unique_mgrs_per_level );
   $table2->addRowLine();

   return( $table1 , $table2 );
}

#------------------------------------------------------------------------------
#  Generate list of labels for columns. List can be arbitrary length.
#------------------------------------------------------------------------------
sub build_col_headers{
   my $label = shift;
   my $max_cols = shift;
   #-------------------------------------
   # Build the column header labels
   my (@column_headings) = qw(Assignee);
   my $cnt = 1;
   while( $cnt <= $max_cols ){
      push(@column_headings, "$label$cnt");
      $cnt++;
   }
   return( @column_headings );
}

#------------------------------------------------------------------------------
# Addd spacer char '-' to front of mgr list so that the highest level mgr
#      always is the same
#------------------------------------------------------------------------------
sub pad_cols{
   my $max_cols = shift;
   my $aref     = shift;

   my $spacer_character = '-';
   my $padding = $max_cols - scalar(@$aref);

   while( $padding ){
      unshift(@$aref, $spacer_character);
      $padding--;
   }

   return( @$aref );
}

#------------------------------------------------------------------------------
#   my $table_txt = text_table_maker();
#   Original code ... slupring psql output
#------------------------------------------------------------------------------
sub text_table_maker(){
   my $t = Text::ASCIITable->new({ headingText => "SNPS Org Data" });
   $t->setOptions( {undef_as=>"-", alignHeadRow=>'center'} );
 

	 #my $cmd = 'head -n 100 psql.orgdata.txt';
	 my $cmd = 'cat psql.orgdata.txt';
	 my ($stdout, $retval) = run_system_cmd( $cmd, $VERBOSITY );
   my @col1; 
   my @col2; 
   my @lines = split(/\n/, $stdout);
   my $max_num_mgrs=0;
   foreach my $line ( @lines ){
      if( $line =~ m/email/ ){
         next;
      }
      dprint(LOW, "line=$line\n" );
      my @tokens = split(/\|/, $line);
      push(@col1, $tokens[3]);
      push(@col2, $tokens[11]);
      my $num_mgrs = split(/\s+/, $tokens[11]);
      $max_num_mgrs = et_max_val( $max_num_mgrs , $num_mgrs );
   }

   my (@col_hdrs) = build_col_headers("Mgr", $max_num_mgrs);
   $t->setCols(@col_hdrs);
   my $elem=0;
   while( defined $col1[$elem] ){
      my @mgrs = split(/\s+/, $col2[$elem]);
      @mgrs = pad_cols( $max_num_mgrs, \@mgrs );
      $t->addRow($col1[$elem],@mgrs);
      $elem++;
   }

   $t->addRowLine();
   return( $t );
}

   my $fname = 'org-parser.cfg';

#------------------------------------------------------------------------------
sub process_cmd_line_args(){
	 my ( $opt_config, $opt_debug, $opt_verbosity, $opt_help, $opt_nousage_stats );
	 GetOptions( 
		    "cfg=s"       => \$opt_config,     # config files for check
		    "debug=s"	    => \$opt_debug,      # multi purposed->(1) debug level (2) will trigger re-using JIRA xml file so query can be skipped.
		    "verbosity=s" => \$opt_verbosity,
		    "nousage"	    => \$opt_nousage_stats,    # when enabled, skip logging usage data
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

   if( defined $opt_help ){ print_help_msg(); exit(0);}

   unless( defined $opt_config ){
       my $msg = "Must specify CFG filename using '-cfg' at cmd line!\n";
       print_help_msg( $msg );
   }
   unless( -e $opt_config ){
       my $msg = "CFG file missing: '$opt_config' \n";
       fatal_error( $msg );
   }
	 return( $opt_config, $opt_debug, $opt_verbosity, $opt_help,
           $opt_nousage_stats );
};

#------------------------------------------------------------------------------
sub print_help_msg{
   print "Usage :  $PROGRAM_NAME -cfg <filename> \n";
   print "optional params ... \n";
   print "         -cfg <filename>  output file from NOTIFY flow ... 'href_org.txt' or equivalent\n";
   print "         -d <#>  debug messaging level -> larger integers result in more messages \n";
   print "         -v <#>  verbosity of user messaging -> larger integers result in more messages \n";
   print "         -nousage \n";
   print "         -help \n";
}
