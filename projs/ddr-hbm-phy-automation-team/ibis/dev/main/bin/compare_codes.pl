#!/depot/perl-5.14.2/bin/perl
###############################################################################
#
# Name    : compare_codes.pl
# Author  : Harsimrat Singh Wadhawan
# Date    : 8 Dec, 2021
# Purpose : Compare the number of calibration codes among HSPICE Model App Note, cal_code.txt and IBIS summary file.
#
# Modification History
#     XXX Harsimrat Singh Wadhawan, 2022-07-13 11:38:48
#         Adding Perl Standard Template header. 
#     
###############################################################################
use strict;
use warnings;
use Pod::Usage;
use Data::Dumper;
use File::Copy;
use Getopt::Std;
use Getopt::Long;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use List::MoreUtils qw(uniq);
use Cwd     qw( abs_path );
use Carp    qw( cluck confess croak );
use FindBin qw( $RealBin $RealScript );

# --INCLUDES ----------------------#
use lib "$FindBin::Bin/../lib/perl";
use Util::CommonHeader;
use Util::Misc;
use Util::DS;
use Util::Messaging;
use Util::P4;
# use utilities;
use parsers;
use QA;
use Cwd;
use ibis qw(remove_blanks);
#----------------------------------#

#---- GLOBAL VARs------------------#
our $STDOUT_LOG; # Initiailized in the BEGIN block
our $PROGRAM_NAME = $RealScript;
our $DEBUG     = NONE;
our $VERBOSITY = NONE;
our $THRESHOLD = 10;
our $RTT = 50;
our $VERSION = get_release_version();
our $LOGFILENAME = getcwd() . "/${PROGRAM_NAME}.log";
#----------------------------------#

# Set project parameters
# TODO: Remove global variables and move them to Main
my (  @file_arr );
my ( %vddq_hash_txt, %vddq_hash_pdf, %vddq_hash_summary );
my ( $family, $project, $macro, $release, $depotPath, $customDepotPath);
my ( $summary_filename, $cal_code_file, $appnote );

# =============================
# MAIN
# =============================

sub Main {

  iprint("Version: $VERSION\n\n");
  
  my ( $depotPath, $summary_filename, $appnote, $cal_code_file, $family, $project, $macro, $release, $severities ) = initialise_script();
  my ( @cal_codes_txt, @cal_codes_pdf, @ibis_summary );

  # ===================================================================================================================== #
	# PARSE SEVERITIES FILE
	# ===================================================================================================================== #

	parse_severities($severities);

  # ===================================================================================================================== #
	# LOAD DATA
	# ===================================================================================================================== #

  # This branch is taken when the appnote, summary and calcode options exist;
  if ( $depotPath eq NULL_VAL ){
    
    my @pdf_contents      = get_local_pdf_file_contents($appnote);    
    my @cal_code_contents = read_file($cal_code_file);

    @ibis_summary  = read_file($summary_filename);
    @cal_codes_txt = get_cal_codes_txt(\@cal_code_contents);
    @cal_codes_pdf = get_pdf_cal_codes(\@pdf_contents, $family);    
    
  }

  else {

    # Read CAL_CODE.TXT
    my $cal_code_path = "//depot/products/$family/project/$project/ckt/rel/HSPICE_model_app_note/$release/cal_code.txt";
    dprint(LOW, "Reading cal_code file: $cal_code_path\n");    
    my @larray = split("\n", da_p4_print_file($cal_code_path));
    
    if ($larray[0] eq NULL_VAL)  {    
      wprint("Could not find TXT file.\n");      
    }
    else {
      @cal_codes_txt = get_cal_codes_txt(\@larray);
    }
    
    # Read PDF File
    my $pdf_path = "//depot/products/$family/project/$project/ckt/rel/HSPICE_model_app_note/$release";   
    dprint(LOW, "Reading PDF: $pdf_path\n");    
    my @pdf_contents = get_p4_pdf_file_contents($pdf_path);

    if ($pdf_contents[0] eq NULL_VAL)  {    
      wprint("Could not find PDF file.\n");      
    }

    @cal_codes_pdf  = get_pdf_cal_codes(\@pdf_contents, $family);    
    @ibis_summary   = get_ibis_summary_file($depotPath);

  }
  
  # Print variables for debugging purposes.
  dprint(HIGH, "\@cal_codes_txt\n");
  dprint(HIGH, Dumper(\@cal_codes_txt)."\n");
  dprint(CRAZY, "\@summary\n");
  dprint(CRAZY, Dumper(\@ibis_summary)."\n");
  dprint(HIGH, "\@cal_codes_pdf\n");
  dprint(HIGH, Dumper(\@cal_codes_pdf)."\n");

  # ===================================================================================================================== #
	# DO THE CHECKS
	# ===================================================================================================================== #

  my @codes_common_pdf_txt = compare_cal_codes_with_pdf(\@cal_codes_txt, \@cal_codes_pdf);           
  
  # This block is executed when a NULL_VAL is returned
  if (@codes_common_pdf_txt and $codes_common_pdf_txt[0] eq NULL_VAL)  {        
    eprint("Could not compare cal_codes with PDF.\n");      
  }

  # This block is executed when a NULL_VAL is not returned
  else {    

    my $number = @codes_common_pdf_txt; 
    hprint "$number CalCodes common between HSPICE App Note and cal_code.txt.\n";    
    
    if ($number > 0){
      
      iprint "CalCodes common between HSPICE App Note and cal_code.txt.\n";
    
      my $r = sprintf "%-10s %-10s %-10s %-10s %-10s %-10s\n", "VDDQ",  "VDD", "PVT", "PCODE", "NCODE", "TEMP";
      iprint "$r";
      
      foreach my $string (@codes_common_pdf_txt) {      
        iprint $string;
      }

    }

  }

  my $codes_common_summary_txt = compare_cal_codes_with_summary(\@cal_codes_txt, \@ibis_summary);         
  
  # This block is executed when a NULL_VAL is returned
  if ($codes_common_summary_txt eq NULL_VAL) {
    eprint ("Could not compare cal codes with summary.\n");
  }

  # This block is executed when a NULL_VAL is not returned
  else{

    my %codes_common_summary_txt = %{$codes_common_summary_txt};
    my $number_keys = keys(%codes_common_summary_txt);
    if ($number_keys) {
          
      my $number = keys(%codes_common_summary_txt);
      hprint "$number CalCodes common between summary file and cal_code.txt.\n";
      iprint "CalCodes common between Summary File and cal_code.txt.\n";    
      foreach my $key ( keys %codes_common_summary_txt ) {
        my $r = sprintf "%-10s %-10s\n", "PCODE", "NCODE";
        iprint "$r";
        iprint "$key";           
      } 

      # Summarise data in the log file
      my @file_log;
      foreach my $key ( keys %codes_common_summary_txt ) {
        
        my $r = sprintf "%-10s %-10s\n", "PCODE", "NCODE";
        push @file_log, "$r";
        push @file_log, "$key"; 

        if ( @{$codes_common_summary_txt{"$key"}} ){
          foreach my $model ( uniq @{$codes_common_summary_txt{"$key"}} ) {
            push @file_log, "\t$model\n";
          }
        }
        else {
          push @file_log, "\tNo matching model.\n";
        }

      } 

      write_file(\@file_log, "model-names-and-calcodes.log")

    }

  }

}

# =============================
# UTILITIES
# =============================

# Get options and initalise neessary variables for locating files.
sub initialise_script {

  my ( $family, $project, $macro, $release, $depotPath, $customDepotPath);
  my ( $summary_filename, $cal_code_file, $appnote );
  my ( $success, $help, $macro_arg, $project_string);
  my $severities = NULL_VAL;

  # get specified args
  $success = GetOptions(
      "help!"     => \$help,
      "macro=s"   => \$macro_arg,
      "d=s"       => \$DEBUG,
      "p=s"       => \$project_string,            
      "summary=s" => \$summary_filename,
      "appnote=s" => \$appnote,
      "calcodes=s"=> \$cal_code_file,
      "severity=s" => \$severities
  );
  
  dprint LOW, "Debugger setting: $DEBUG\n";

  if ($project_string and $macro_arg){

    $macro = $macro_arg;

    ($family, $project, $release) = parse_project_spec($project_string, \&usage); 

    if ($family eq 'lpddr5x') {
      $family = "lpddr5x_ddr5_phy/lp5x";
    } elsif ($family eq 'ddr5') {
      $family = "lpddr5x_ddr5_phy/$family";
    }
    
    #Set the depot path for the ibis folder
    if ($macro_arg) {
      $depotPath = "//depot/products/$family/project/$project/ckt/rel/$macro/$release/macro/ibis";  
    }
    if ($customDepotPath) {
      $depotPath = "$customDepotPath/ckt/rel/$macro/$release/macro/ibis";	
    }
    
    dprint MEDIUM, "$family $project $release $macro\n";
    dprint LOW, "The depot path is: $depotPath.\n";	

  }
  elsif ( $summary_filename and $cal_code_file and $appnote){
    $depotPath = NULL_VAL;    
  }
  else { usage(1); }

  &usage if $help;  
  return ( $depotPath, $summary_filename, $appnote, $cal_code_file, $family, $project, $macro, $release, $severities );

}

# Other functions
sub extract_code {

    my $line = shift;
    my $line2 = shift;
    my $line3 = shift;

    my %hash;

    my @array = split (/\//, $line);
    my @array2 = split (/=/, $line2);
    my @array3 = split (/=/, $line3);

    if (@array != 4 && @array2 != 4 && @array3 != 4){

      eprint("Could not parse cal_code.txt file.\n");
      dprint(SUPER, Dumper("$line\n$line2\n$line3.")."\n");
      return %hash;

    }

    my $PVT = $array[0];
    $PVT =~ s/\*|\s+//ig;

    my $TEMP = $array[1];
    $TEMP =~ s/[^0-9.-]//g;

    my $VDDQ = $array[2];
    $VDDQ =~ s/[^0-9.-]//g;

    my $VDD = $array[3];
    $VDD =~ s/[^0-9.-]//g;

    my $PCODE = trim $array2[@array2-1];
    my $NCODE = trim $array3[@array3-1];

    $hash{"PVT"} = $PVT;
    $hash{"TEMP"} = $TEMP;
    $hash{"VDDQ"} = $VDDQ;
    $hash{"VDD"} = $VDD;
    $hash{"PCODE"} = $PCODE;
    $hash{"NCODE"} = $NCODE;

    return %hash;

}

sub get_unique_codes {

  my $ref = shift;  
  my @summary_codes = @{$ref};
  my @summary_unique_codes; 
  my %pair_hash;

  # Filter out unique pcodes and ncodes
  foreach my $code (@summary_codes) {

    my $pcode = @{$code}[0];
    my $ncode = @{$code}[1];

    if ( ! exists $pair_hash{"$pcode$ncode"} ) {
      $pair_hash{"$pcode$ncode"} = "";
      push @summary_unique_codes, [$pcode, $ncode];
    }   

  }

  return @summary_unique_codes;

}

sub get_pdf_cal_codes($$) {    
    
    my $ref = shift;
    my $family = shift;
    my @file_contents = @{$ref};
    my @cal_code_array;

    # Remove blank lines from the array for easier parsing.
    @file_contents = remove_blanks (\@file_contents);
    my $answer = -1;

    # Extract calibration codes based upon the type of App Note used in the project.
    if ($family =~ /lpddr5x/) {
      $answer = parse_lpddr5xm_app_note \@file_contents, \@cal_code_array, \%vddq_hash_pdf;
    }

    elsif ($family =~ /ddr54/) {
      $answer = parse_lpddr5xm_app_note \@file_contents, \@cal_code_array, \%vddq_hash_pdf;
    }
    
    else {
      fatal_error "Could not parse App Note for this project. Specify the product family with the -family option. Exiting.\n";      
    }

    return @cal_code_array;
    
}

# =============================
# DATA COLLECTION FUNCTIONS
# =============================

# Obtain PDF file from Perforce
sub get_p4_pdf_file_contents($) {

    my $pdf_path = shift;   
    my @files = da_p4_files("$pdf_path/*");
    
    if ($files[0] eq NULL_VAL)	{	    
	    return NULL_VAL;
    }

    my $pdf = NULL_VAL;    
    foreach my $file (@files){
      
      if ($file =~ /\.pdf/i) {
        $pdf =$file;
        last;
      }
      
    }    
    
    if ($pdf eq NULL_VAL){
      eprint("Could not find PDF file.\n");
      return NULL_VAL;
    }

    my $path = $pdf;    
    my $name = trim "HSPICE_CURRENT.pdf";
    
    dprint(LOW,"App Note: $path\n");
    
    run_system_cmd("p4 print $path > $name\n");        

    my @hspice_current_pdf_content = read_file('HSPICE_CURRENT.pdf');           
    
    # convert pdf to text file to get the calibration codes.
    run_system_cmd("pdftotext -layout HSPICE_CURRENT.pdf");
    
    my @file_contents = read_file('HSPICE_CURRENT.txt');           

    run_system_cmd("rm -rf HSPICE_CURRENT.pdf");
    run_system_cmd("rm -rf HSPICE_CURRENT.txt");

    return @file_contents;

}

# Obtain PDF file from the file system
sub get_local_pdf_file_contents($) {

    my $path = shift;        
    dprint(LOW,"App Note: $path\n");
    
    # convert pdf to text file to get the calibration codes.
    run_system_cmd("pdftotext -layout $path HSPICE_CURRENT.txt");
    
    my @file_contents = read_file('HSPICE_CURRENT.txt');           

    run_system_cmd("rm -rf HSPICE_CURRENT.pdf");
    run_system_cmd("rm -rf HSPICE_CURRENT.txt");

    return @file_contents;

}

# Obtain the IBIS summary file from Perforce and store it in an array called @ibis_summary.
sub get_ibis_summary_file($) {
	
  my $depotPath = shift;
  my @ibis_summary = ();

	#Finding the IBIS summary file
	my $filename;
	my $not_found = 0;
	my @file_arr  = da_p4_files("$depotPath/*");

  if ($file_arr[0] eq NULL_VAL){
    wprint("Could not find summary file.\n");
    return NULL_VAL;
  }

  my $summary_file_location = NULL_VAL;
  foreach my $file (@file_arr){
    if ($file =~ /ibis.*summary.*txt/ig){
      $summary_file_location = $file;
      last;
    }
  }
  
  dprint(LOW, "Reading summary file: $summary_file_location\n");
  @ibis_summary = split("\n", da_p4_print_file($summary_file_location));	  	
  return @ibis_summary;

}

# Get calibration codes from the cal_code.txt file. Store them in a variable called @cal_codes_txt
sub get_cal_codes_txt {
    
    my $ref= shift;
    my @larray = @{$ref};
    my @cal_codes_txt;

    my @array = remove_blanks(\@larray);
    if (! @array) {    
      return -1;    
    }        
    
    for (my $i = 0 ; $i < @array; $i++) {

        my $line = $array[$i];            
        my $next_line = $array[$i+1];          
        my $next_2_line = $array[$i+2];          

        if ($line =~ /^\*\*\*/ and $line =~ /\//) {                                            
            
            my $number = $i+1;            
            my @array_lines = [ trim($line),  trim($next_line),  trim($next_2_line)];
    
            my %hash_new = extract_code (trim($line), trim($next_line), trim($next_2_line));
    
            if ( keys(%hash_new) ) {
              push (@cal_codes_txt, \%hash_new) ; 
              insert_at_key \%vddq_hash_txt, $hash_new{'VDDQ'}, \%hash_new;                         
            }            
            
            $i += 2;

        }
        
    }   

    return @cal_codes_txt;

}

# =============================
# QUALITY ASSURANCE FUNCTIONS
# =============================

sub compare_cal_codes_with_pdf($$) {

  my $txt_ref = shift;
  my $pdf_ref = shift;
  my @cal_codes_txt = @{$txt_ref};
  my @cal_codes_array = @{$pdf_ref};

  if (! @cal_codes_array) {      
    return NULL_VAL;
  }
  if (! @cal_codes_txt ) {    
    return NULL_VAL;
  }  

  my $num_cal_codes_txt = @cal_codes_txt;
  my $num_cal_codes_pdf = @cal_codes_array;
   
  my @txt_pcodes = ();
  my @txt_ncodes = ();  
  my @pdf_pcodes = ();
  my @pdf_ncodes = ();
        
  foreach my $item (@cal_codes_txt){                
    my %hash_txt = %$item;
    push @txt_pcodes, $hash_txt{"PCODE"};
    push @txt_ncodes, $hash_txt{"NCODE"};      
  }
  
  foreach my $item (@cal_codes_array){                
    my %hash_txt = %$item;
    push @pdf_pcodes, $hash_txt{"PCODE"};
    push @pdf_ncodes, $hash_txt{"NCODE"};      
  }       
  
  iprint "Number of calcodes in cal_code.txt = $num_cal_codes_txt.\n";
  iprint "Number of calcodes in HSPICE Model App Note = $num_cal_codes_pdf.\n";    

  if ($num_cal_codes_txt != $num_cal_codes_pdf){
    alert(0, "Calibration codes not equal in text and pdf.\n", map_check_severity());
  }
  else {
    alert(1, "Calibration codes equal in text and pdf.\n", map_check_severity());
  }

  my @common_pcodes = intersection (\@pdf_pcodes, \@txt_pcodes);
  my $size_pcodes = scalar @common_pcodes;
  
  my @common_ncodes = intersection (\@pdf_ncodes, \@txt_ncodes);
  my $size_ncodes = scalar @common_ncodes;        
  
  # how many cal codes are common between the PDF and the cal_code.txt
  my $common_codes = 0;
  my @common_codes_array;

  if (@cal_codes_txt and @cal_codes_array) {
  
    #find cal codes common between HSPICE App Note and cal_code.txt      
    foreach my $item (@cal_codes_array){                
        
      my %hash_pdf = %$item;
      my $pcode =  $hash_pdf{"PCODE"};
      my $ncode =  $hash_pdf{"NCODE"};                 	  		                                             
        
      foreach my $item_txt (@cal_codes_txt) {
                
        my %hash_txt = %$item_txt;
        my $pcode2 =  $hash_txt{"PCODE"};
        my $ncode2 =  $hash_txt{"NCODE"};          
        
        if ($pcode == $pcode2 and $ncode == $ncode2) {	

          my $vddq2 =  $hash_txt{"VDDQ"};
          my $vdd2 =  $hash_txt{"VDD"};
          my $pvt2 =  $hash_txt{"PVT"};
          my $temp2 =  $hash_txt{"TEMP"};
          my $vddq =  $hash_pdf{"VDDQ"};
          my $vdd =  $hash_pdf{"VDD"};
          my $pvt =  $hash_pdf{"PVT"};
          my $temp =  $hash_pdf{"TEMP"}; 

          if ($vddq == $vddq2 and $pcode == $pcode2 and $vdd == $vdd2 and $pvt =~ /$pvt2/i and $ncode == $ncode2 and $temp =~ /$temp2/i) {				 
            $common_codes++;
            my $string = sprintf "%-10s %-10s %-10s %-10s %-10s %-10s\n", $vddq, $vdd, $pvt,  $pcode, $ncode, $temp;
            push @common_codes_array, $string;
          }

        }

      } 

    }	

  }                 
  
  return @common_codes_array;            
              
}

sub compare_cal_codes_with_summary($$) {

  my $txt_ref = shift;
  my $summary_ref = shift;
  my @cal_codes_txt = @{$txt_ref};
  my @ibis_summary = @{$summary_ref};
  
  if (! @ibis_summary) {         
    return (NULL_VAL => NULL_VAL);
  }
  if (@cal_codes_txt == 0) {    
    return (NULL_VAL => NULL_VAL);
  }  
    
  # extract calibration codes from IBIS summary files
  my ($summary_codes_ref, @summary_codes);
  $summary_codes_ref = get_ibis_summary_cal_codes(\@ibis_summary);
  
  @summary_codes = @{$summary_codes_ref};  
  dprint(CRAZY, "\@summary_codes\n");
  dprint(CRAZY, Dumper(@summary_codes)."\n");  

  my @summary_unique_codes = get_unique_codes(\@summary_codes);
  dprint(HIGH, "Summary unique codes.\n");
  dprint(HIGH, Dumper(@summary_unique_codes)."\n");  
              
  my $total_cal_codes_in_summary_file = @summary_unique_codes;
  my $cal_codes_in_txt_file           = @cal_codes_txt;

  if (! $total_cal_codes_in_summary_file) {
    wprint "Could not find cal_codes inside the summary file.\n";
    return NULL_VAL;
  }            
  iprint "Number of calcodes in cal_code.txt = $cal_codes_in_txt_file.\n";
  iprint "Number of unique pcodes and ncodes in IBIS Summary file = $total_cal_codes_in_summary_file.\n";    

  if ($cal_codes_in_txt_file != $total_cal_codes_in_summary_file){
    alert(0, "Calibration codes do not equal in text and summary file.\n", map_check_severity());
  }
  else {
    alert(1, "Calibration codes equal in text and summary file.\n", map_check_severity());
  }

  my $common_codes = 0;   # stores how many cal codes are common between the summary file and the cal_code.txt
  my %codes_common;
   
  foreach my $code_from_txt (@cal_codes_txt) {
  
    my %hash_txt = %$code_from_txt;
    my $pcode =  $hash_txt{"PCODE"};
    my $ncode =  $hash_txt{"NCODE"};
    my $vddq =  $hash_txt{"VDDQ"};
    my $vdd =  $hash_txt{"VDD"};
    my $pvt =  $hash_txt{"PVT"};
    my $temp =  $hash_txt{"TEMP"};

    my $string = sprintf "%-10s %-10s\n", $pcode, $ncode;

    for ( my $i =0; $i < @summary_codes; $i++) {        

      if ($pcode == @{$summary_codes[$i]}[0] and $ncode == @{$summary_codes[$i]}[1] ) {         
        $common_codes++;                     
        insert_at_key \%codes_common, "$string", @{$summary_codes[$i]}[2];                  
      }

    }      
  
  }

  return \%codes_common;
        
}

# =============================
# TEMPLATE ROUTINES
# =============================

BEGIN {
    #$STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
    $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
    header();
}
  Main();
END   {     
  footer();
  write_stdout_log( $LOGFILENAME );
  utils__script_usage_statistics("compare_codes.pl", $VERSION);
}

# =============================
# USAGE
# =============================

sub usage($) {
    my $exit_status = shift;

    print << "EOP" ;
    USAGE : $0 [options]

    command line options:

    Automatically find the required appnote, ibis summary file and calcode file.
    -p     :   project string (required)
    -macro    :   circuit macro to be analysed (required) 
    
    Manually specify the Appnote, the calcodes and the summary
    -summary  :   IBIS summary file
    -appnote  :   HSPICE App note PDF
    -calcodes :   cal_code.txt file  

    -debug    :   show debugging information
    -help     :   print this screen
    -severity :   specify the sverity configuration file

    EXAMPLE: $0 -p ddr43/d528-ddr43-ss11lpp18/rel1.00 -macro dwc_ddrphy_txrxac_ew

EOP
    exit($exit_status);
}
