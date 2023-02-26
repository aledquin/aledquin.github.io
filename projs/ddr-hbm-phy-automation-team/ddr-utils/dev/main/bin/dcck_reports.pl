#!/depot/perl-5.14.2/bin/perl
#!/depot/perl-5.8.0/bin/perl
# nolint [Variables::RequireLexicalLoopIterators]
###############################################################################
#
# Name    : dcck_reports.pl
# Author  : N/A
# Date    : N/A
# Purpose : N/A
#
# Modification History
#             2022-05-26 12:38:49 => Adding Perl template. HSW.
###############################################################################
use strict;
use Pod::Usage;
use Data::Dumper;
use File::Copy;
use Getopt::Std;
use Getopt::Long;
use Cwd qw( abs_path getcwd );
use Carp qw( cluck confess croak );
use FindBin qw( $RealBin $RealScript );

use lib "$RealBin/../lib/perl";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;

#--------------------------------------------------------------------#
our $STDOUT_LOG; # Initiailized in the BEGIN block
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $PROGRAM_NAME = $RealScript;
our $LOGFILENAME     = getcwd() . "/$PROGRAM_NAME.log";
our $VERSION         = get_release_version();
our $RUN_SYSTEM_CMDS = 1;

#--------------------------------------------------------------------#

BEGIN {
    our $AUTHOR = 'Multiple Authors';
    #$STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
    $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
    header();
}
&Main();

END {
    local $?;    ## adding this will pass the status of failure if the script
    ## does not compile; otherwise this will always return 0
    footer();
    write_stdout_log($LOGFILENAME);
}

#----------------------------------------------------------
sub Main() {
    my @orig_argv = @ARGV;    # keep this here cause GetOpts modifies ARGV
    my ( $opt_inc, $opt_dir, $opt_nousage ) = process_cmd_line_args();
    utils__script_usage_statistics( $PROGRAM_NAME, $VERSION, \@orig_argv );

    iprint("Cleaning-up old CSV files... \n");
    my ( $output, $retval ) = run_system_cmd( "rm -rf *.csv", $VERBOSITY );

    iprint("Searching for testbench reports in directory: '$opt_dir'\n");

    my @chkd1  = get_input_files( $opt_dir , 'tb[\w\d_]+\.chkdevop_\d*$'  );
    my @sp1    = get_input_files( $opt_dir , 'tb[\w\d_]+\.sp\d*$'         );
    my @chkz1  = get_input_files( $opt_dir , 'tb[\w\d_]+\.chkznode_\d*$'  );
    my @chkdc1 = get_input_files( $opt_dir , 'tb[\w\d_]+\.chkdcpath_\d*$' );

    my $num_files =
      scalar(@chkd1) + scalar(@sp1) + scalar(@chkz1) + scalar(@chkdc1);
    unless ( $num_files > 0 ) {
        fatal_error(
            "Didn't find any testbench CSV files to read...aborting! \n");
    }

    viprint( LOW,
            "Found testbench CSV files to read:\n"
          . "tb_*chkdevop*.csv  -> \n\t"
          . join( ",\n\t", @chkd1 ) . "\n"
          . "tb_*sp**.csv       -> \n\t"
          . join( ",\n\t", @sp1 ) . "\n"
          . "tb_*chkznode*.csv  -> \n\t"
          . join( ",\n\t", @chkz1 ) . "\n"
          . "tb_*chkdcpath*.csv -> \n\t"
          . join( ",\n\t", @chkdc1 )
          . "\n" );
    prompt_before_continue(SUPER);    # VERIFIED
    foreach my $file (@chkdc1) {
        create_csv_from_dcpaths_report($file);
    }

    #**********************************For chkdevop files**********************************************
    my $a = 0;
    foreach my $chkd2 (@chkd1) {
        my $fname_csv = "$chkd2.csv";
        prompt_before_continue(SUPER);    # VERIFIED
        open( DATA2, '>', $fname_csv ) or eprint("Can't write to file: '$fname_csv' \n");    # nolint
        wprint("Concerned sp file for it: '$sp1[$a]'\n");
        $a = $a + 1;

        my $flag = 0;
        my $flag1;
        my $flag2;
        my @value  = ();
        my @value1 = ();
        my @words  = ();
        my @wordss = ();
        my @words1 = ();
        my $value1_abs;

        # For deleting the violations with same devices having
        # percentage violation within +_1%
        #my @data  = grep { !/^\s*$/ } read_file( $chkd2 );
        my @data = read_file($chkd2);

        #my @lines = @data;
        my @lines;
        foreach my $line (@data) {
            last if ( $line =~ m/Number of Error/ );

            if ( $flag == 1 && $line ne "" ) {
                @words = ();
                @words = split /( )+/, $line;
                @value = ();
                @value = split /=/, $words[10];
                $flag1 = 0;
                $flag2 = 0;

                #dprint(SUPER, "chkdevop: \n\t'$line' \n\t-> " . pretty_print_aref(\@words) ."\n\t-> " . pretty_print_aref(\@value) . "\n" );
                #dprint(SUPER, "chkdevop: \n\t'$line' \n\t-> " . pretty_print_aref(\@words) ."\n\t-> " . pretty_print_aref(\@value) . "\n" );
                #prompt_before_continue( SUPER );
                foreach my $line1 (@lines) {
                    if ( $flag2 == 1 && $line ne "" ) {
                        @words1 = ();
                        @words1 = split /( )+/, $line1;
                        if ( $words1[0] eq $words[0] ) {
                            if ( $words[2] eq $words1[2] ) {
                                my @value1 = ();
                                my $value1_abs;
                                my $value_abs;
                                my $val;
                                @value1 = split /=/, $words1[10];
                                if ( $value[1] != 0 ) {
                                    $value1_abs = abs( $value1[1] );
                                    $value_abs  = abs( $value[1] );
                                    $val = ( ( $value_abs - $value1_abs ) /
                                          $value_abs ) * 100;
                                }

                             #$val=(($value[1]-$value1_abs[1])/$value[1])*100; }
                                else {
                                    $val = ( $value_abs - $value1_abs ) * 100;
                                }

                                #else { $val=$value[1]-$value1_abs[1] *100; }
                                if ( $val < 0 ) { $val = -$val; }
                                if ( $val <= 1 && $flag1 == 1 ) {
                                    $line1 = "";
                                }
                                if ( $val <= 1 && $flag1 == 0 ) {
                                    $flag1 = 1;
                                }
                            }
                        }
                    }
                    $flag2 = 1 if ( $line1 =~ m/device-name/ );
                }
            }
            $flag = 1 if ( $line =~ m/device-name/ );
        }    # END foreach @data
             #*********************************************************#

        my ( $noLayout, $noDummy, @voltage ) = read_opts_file($opt_inc);
        my $aref = filter_chkdevop( \@lines, $noLayout, $noDummy );
        @lines = @$aref;

        #********** Removing similar devices with same voltage tag/type and violations
        $flag = 0;
        my @sorted = sort @lines;
        @lines = ();
        @lines = @sorted;
        foreach my $line (@lines) {

            #if ( $line =~ m/Number of Error/ ) { last; }
            if ( $flag == 1 && $line ne "" ) {
                @words = ();
                @words = split /( )+/, $line;
                $flag1 = 0;
                $flag2 = 0;

                #print "--------------------------Group : $words[0] $words[2]---------------------------------\n";
                foreach my $line1 (@lines) {
                    if ( $flag2 == 1 && $line1 ne "" ) {
                        @wordss = ();
                        @wordss = split /( )+/, $line1;
                        if ( $wordss[0] ne "*" ) {
                            if ( $wordss[0] =~ m/$words[0]/ ) {

                                #print "In this $line1";
                                if ( $words[2] eq $wordss[2] && $flag1 == 1 ) {

                              #print "Related Device : $wordss[0] $wordss[2]\n";
                                    $line1 = "";
                                }
                                if (   $words[2] eq $wordss[2]
                                    && $words[4] eq $wordss[4]
                                    && $words[6] eq $wordss[6]
                                    && $words[8] eq $wordss[8]
                                    && $words[10] eq $wordss[10]
                                    && $words[12] eq $wordss[12]
                                    && $flag1 == 0 )
                                {
                                    $flag1 = 1;
                                }
                            }
                        }
                    }
                    if ( $line1 =~ m/device-name/ ) {
                        $flag2 = 1;
                    }
                }
            }
            if ( $line =~ m/device-name/ ) {
                $flag = 1;
            }
        }    # END foreach @lines
        prompt_before_continue(SUPER);

        #  Marking the devices with their voltages after post evaluation
        #       from opt_inc.inc file

        my @volt_value = read_file( $sp1[$a] );
        my @volt;

        foreach my $vol (@voltage) {
            chomp($vol);
            next if ( $vol eq "" || $vol eq " " || $vol =~ m/^#.*/ );
            @volt = ();
            @volt = split / /, $vol;

            #$i=1;
            my $value;
            foreach my $volv (@volt_value) {
                if ( $volt[3] eq "vdd" || $volt[1] eq "VDD" ) {
                    if ( $volv =~ m/$volt[3]/ ) {
                        my @volv1 = ();
                        @volv1 = split /=/, $volv;
                        if ( $volv1[1] =~ m/[0-9]+/ ) {
                            $value = $volv1[1];
                            last;
                        }
                        else { $volt[3] = $volv1[1]; }
                    }
                }
                if ( $volv =~ m/$volt[3]/ ) {
                    my @volv1 = ();
                    @volv1 = split /=/, $volv;
                    if ( $volv1[1] =~ m/[0-9]+/ ) {
                        $value = $volv1[1];
                        last;
                    }
                    else { next; }
                }
            }    # END foreach @volt_value
            $value =~ s/ //;
            $volt[3] = $value;
            $vol = join( " ", @volt );
        }    # END foreach @voltage

        my $default;
        foreach my $vol (@voltage) {
            if ( $vol eq "" || $vol eq " " || $vol =~ m/^#.*/ ) {
            }
            else {
                @volt = ();
                @volt = split / /, $vol;
                if ( $volt[2] eq "Default" ) {
                    $default = $volt[3];
                }
                if ( $volt[2] ne "Default" ) {
                    foreach my $line (@lines) {
                        if ( $line =~ m/$volt[2]/ ) {
                            chop($line);
                            $line = "$line $volt[3]";
                        }
                    }
                }
            }
        }
        $flag = 0;
        foreach my $line (@lines) {
            if ( $flag == 1 && $line ne "" ) {
                my @lv = split /( )+/, $line;
                my $length = @lv;
                if ( $length == 13 ) {
                    chop($line);
                    $line = "$line $default";
                }
            }
            if ( $line =~ m/device-name/ ) {
                $flag = 1;
            }
        }

        #********************************************************************************************************************************************#
        prompt_before_continue(SUPER);

        my @arr5  = (); #Used for overvolatge violation less than or equal to 5%
        my @arr10 = ()
          ; #Used for overvoltage violation greater than 5 and less than equal to 5%
        my @arr101 = ();    #Used for overvoltage violation greater than 10%
        my @arr20  = ();
        $flag = 0;
        my ( $separate, $flag_separatewithdot, $flag_separatewithoutdot );
        my ( $g, $j, $k, $t );
        $g = 0;
        $j = 0;
        $k = 0;
        $t = 0;
        my $head;

        foreach my $line (@lines) {

            #if ( $line =~ m/Number of Error/ ) { last; }
            if ( $flag == 1 && $line ne "" ) {
                @words     = ();
                @words     = split /( )+/, $line;
                @value     = ();
                @value     = split /=/, $words[10];
                $words[10] = $value[1];
                $value[1]  = abs( $value[1] );
                my $vdd = $words[14];
                chop($vdd);
                chomp( $words[14] );

                #pop @words;
                $line = join( " ", @words ) . "\n";
                my $val1;
                if ( $vdd != 0 ) {
                    $val1 = ( ( $value[1] - $vdd ) / $vdd ) * 100;
                }
                else {
                    $val1 = ( $value[1] - $vdd ) * 100;
                }
                if ( $val1 <= 5 ) {
                    $j = $j + 1;
                    chomp($line);
                    push @arr5, "$line $val1\n";
                }
                if ( $val1 > 5 && $val1 <= 10 ) {
                    $k = $k + 1;
                    chomp($line);
                    push @arr10, "$line $val1\n";
                }
                if ( $val1 > 10 && $val1 < 20 ) {
                    $g = $g + 1;
                    chomp($line);
                    push @arr101, "$line $val1\n";
                }
                if ( $val1 >= 20 ) {
                    $t = $t + 1;
                    chomp($line);
                    push @arr20, "$line $val1\n";
                }
            }
            if ( $line =~ m/device-name/ ) {
                $head = $line;
                $head =~ s/ +/\t/g;

                #***To add a extra column in heading after device name ***#
                my @head1 = split /\t/, $head;
                $head1[0] = "[device-hierarchy]\t[device-name]";
                $head = join( "\t", @head1 );
                $flag = 1;
            }
        }

        my ( @sep, @l22_temp, @l22_temp1 );
        my ( $field1, $field2 );
        print "Violations <5% $j\n";
        print "Violations >5% & <10% $k\n";
        print "Violations  >10% && <20% $g\n";
        print "Violations  >=20% $t\n";
        print DATA2
        "\n***************************************************************Violation<=5% || Number of Violation = $j**************************************\n";

        if ( scalar @arr5 == 0 ) {
            print DATA2
            "***************************************************************Empty_Category**************************************\n";
        }
        else {
            my @sorted5 = ();
            @sorted5 =
              sort { ( split( /\s+/, $b ) )[5] <=> ( split( /\s+/, $a ) )[5] }
              @arr5;
            foreach my $l1 (@sorted5) {
                my $pattern;
                @words = ();
                @words = split /( )+/, $l1;
                @value = ();
                @value = split /\./, $words[0];
                $flag_separatewithdot =
                  0;    #When heirachy have both dot and a slash
                $flag_separatewithoutdot = 0;    #When heirachy have only slash
                if ( $words[0] =~ m/\// ) {
                    $separate             = pop @value;
                    $flag_separatewithdot = 1;
                    if ( $separate =~ m/^$/ ) {
                        $separate                = $words[0];
                        $flag_separatewithoutdot = 1;
                    }
                }
                if ( $flag_separatewithoutdot == 1 ) {
                    @sep = ();
                    @sep = split /\//, $separate;
                    pop @sep;
                    pop @sep;
                    $separate = join( "/", @sep );
                    $pattern = $separate;
                }
                elsif ( $flag_separatewithdot == 1 ) {
                    $pattern = join( ".", @value );
                    @sep     = ();
                    @sep     = split /\//, $separate;
                    pop @sep;
                    pop @sep;
                    $separate = join( "/", @sep );
                    $pattern = $pattern . '.' . $separate;
                }
                else {
                    pop @value;
                    pop @value;
                    $pattern = join( ".", @value );
                    @value = ();
                }
                unless ( $pattern =~ m/^$/ ) {
                    print DATA2
                    "\n****************Device_Group:$pattern****************\n\n";
                    chomp($head);
                    $head = "$head reference_voltage_value delta_voltage\n";
                    $head =~ s/ +/\t/g;
                    print DATA2 "$head";
                    foreach my $l2 (@sorted5) {
                        if ( $l2 =~ $pattern ) {
                            $l2 =~ s/ +/\t/g;
                            @l22_temp  = ();
                            @l22_temp1 = ();
                            @l22_temp  = split /\t/, $l2;
                            @l22_temp1 = split /\./, $l22_temp[0];
                            if ( $#l22_temp1 >= 2 ) {
                                $field1 =
                                  shift @l22_temp1;    #Take out first field
                                $field2 =
                                  shift @l22_temp1;    #Take out second field
                                my $merge1 = join( ".", $field1, $field2 )
                                  ;                    #Merge first and second
                                my $merge2 =
                                  join( ".", @l22_temp1 ); #Merge the rest array
                                my $final_merge =
                                  join( "\t", $merge1, $merge2 );
                                $l22_temp[0] = $final_merge;
                            }
                            else {
                                $l22_temp[0] = "NA\t$l22_temp[0]";
                            }
                            $l2 = join( "\t", @l22_temp );
                            print DATA2 "$l2";
                            $l2 = "";
                        }
                    }    # END foreach
                }    # END unless
            }    # END foreach $l1 (@sorted5)
        }    #END else

        print DATA2
        "\n***************************************************************Violation>5%&&<=10% || Number of Violation = $k**************************************\n";
        if ( scalar @arr10 == 0 ) {
            print DATA2
            "***************************************************************Empty_Category**************************************\n";
        }
        else {
            my @sorted10 = ();
            @sorted10 =
              sort { ( split( /\s+/, $b ) )[5] <=> ( split( /\s+/, $a ) )[5] }
              @arr10;
            foreach my $l11 (@sorted10) {
                my $pattern;
                @words = ();
                @words = split /( )+/, $l11;
                @value = ();
                @value = split /\./, $words[0];
                $flag_separatewithdot =
                  0;    #When heirachy have both dot and a slash
                $flag_separatewithoutdot = 0;    #When heirachy have only slash
                if ( $words[0] =~ m/\// ) {
                    $separate             = pop @value;
                    $flag_separatewithdot = 1;
                    if ( $separate =~ m/^$/ ) {
                        $separate                = $words[0];
                        $flag_separatewithoutdot = 1;
                    }
                }
                if ( $flag_separatewithoutdot == 1 ) {
                    @sep = ();
                    @sep = split /\//, $separate;
                    pop @sep;
                    pop @sep;
                    $separate = join( "/", @sep );
                    $pattern = $separate;
                }
                elsif ( $flag_separatewithdot == 1 ) {
                    $pattern = join( ".", @value );
                    @sep     = ();
                    @sep     = split /\//, $separate;
                    pop @sep;
                    pop @sep;
                    $separate = join( "/", @sep );
                    $pattern = $pattern . '.' . $separate;
                }
                else {
                    pop @value;
                    pop @value;
                    $pattern = join( ".", @value );
                    @value = ();
                }
                unless ( $pattern =~ m/^$/ ) {
                    print DATA2
                    "\n****************Device_Group:$pattern****************\n\n";
                    chomp($head);
                    $head = "$head reference_voltage_value delta_voltage\n";
                    $head =~ s/ +/\t/g;
                    print DATA2 "$head";
                    foreach my $l22 (@sorted10) {
                        if ( $l22 =~ $pattern ) {
                            $l22 =~ s/ +/\t/g;
                            @l22_temp  = ();
                            @l22_temp1 = ();
                            @l22_temp  = split /\t/, $l22;
                            @l22_temp1 = split /\./, $l22_temp[0];
                            if ( $#l22_temp1 >= 2 ) {
                                $field1 =
                                  shift @l22_temp1;    #Take out first field
                                $field2 =
                                  shift @l22_temp1;    #Take out second field
                                my $merge1 = join( ".", $field1, $field2 )
                                  ;                    #Merge first and second
                                my $merge2 =
                                  join( ".", @l22_temp1 ); #Merge the rest array
                                my $final_merge =
                                  join( "\t", $merge1, $merge2 );
                                $l22_temp[0] = $final_merge;
                            }
                            else {
                                $l22_temp[0] = "NA\t$l22_temp[0]";
                            }
                            $l22 = join( "\t", @l22_temp );
                            print DATA2 "$l22";
                            $l22 = "";
                        }
                    }
                }
            }
        }

        print DATA2
        "\n***************************************************************Violation>10% && Violation < 20% || Number of Violation = $g**************************************\n";
        if ( scalar @arr101 == 0 ) {
            print DATA2
            "***************************************************************Empty_Category**************************************\n";
        }
        else {
            my @sorted101 = ();
            @sorted101 =
              sort { ( split( /\s+/, $b ) )[5] <=> ( split( /\s+/, $a ) )[5] }
              @arr101;
            foreach my $l111 (@sorted101) {
                my $pattern;
                @words = ();
                @words = split /( )+/, $l111;
                @value = ();
                @value = split /\./, $words[0];
                $flag_separatewithdot =
                  0;    #When heirachy have both dot and a slash
                $flag_separatewithoutdot = 0;    #When heirachy have only slash
                if ( $words[0] =~ m/\// ) {
                    $separate             = pop @value;
                    $flag_separatewithdot = 1;
                    if ( $separate =~ m/^$/ ) {
                        $separate                = $words[0];
                        $flag_separatewithoutdot = 1;
                    }
                }
                if ( $flag_separatewithoutdot == 1 ) {
                    @sep = ();
                    @sep = split /\//, $separate;
                    pop @sep;
                    pop @sep;
                    $separate = join( "/", @sep );
                    $pattern = $separate;
                }
                elsif ( $flag_separatewithdot == 1 ) {
                    $pattern = join( ".", @value );
                    @sep     = ();
                    @sep     = split /\//, $separate;
                    pop @sep;
                    pop @sep;
                    $separate = join( "/", @sep );
                    $pattern = $pattern . '.' . $separate;
                }
                else {
                    pop @value;
                    pop @value;
                    $pattern = join( ".", @value );
                    @value = ();
                }
                unless ( $pattern =~ m/^$/ ) {
                    print DATA2
                    "\n****************Device_Group:$pattern****************\n\n";
                    chomp($head);
                    $head = "$head reference_voltage_value delta_voltage\n";
                    $head =~ s/ +/\t/g;
                    print DATA2 "$head";
                    foreach my $l222 (@sorted101) {
                        if ( $l222 =~ $pattern ) {
                            $l222 =~ s/ +/\t/g;
                            @l22_temp  = ();
                            @l22_temp1 = ();
                            @l22_temp  = split /\t/, $l222;
                            @l22_temp1 = split /\./, $l22_temp[0];
                            if ( $#l22_temp1 >= 2 ) {
                                $field1 =
                                  shift @l22_temp1;    #Take out first field
                                $field2 =
                                  shift @l22_temp1;    #Take out second field
                                my $merge1 = join( ".", $field1, $field2 )
                                  ;                    #Merge first and second
                                my $merge2 =
                                  join( ".", @l22_temp1 ); #Merge the rest array
                                my $final_merge =
                                  join( "\t", $merge1, $merge2 );
                                $l22_temp[0] = $final_merge;
                            }
                            else {
                                $l22_temp[0] = "NA\t$l22_temp[0]";
                            }
                            $l222 = join( "\t", @l22_temp );
                            print DATA2 "$l222";
                            $l222 = "";
                        }
                    }
                }
            }
        }

        print DATA2
        "\n***************************************************************Violation >= 20% || Number of Violation = $t**************************************\n";
        if ( scalar @arr20 == 0 ) {
            print DATA2
            "***************************************************************Empty_Category**************************************\n";
        }
        else {
            my @sorted20 = ();
            @sorted20 =
              sort { ( split( /\s+/, $b ) )[5] <=> ( split( /\s+/, $a ) )[5] }
              @arr20;
            foreach my $l2221 (@sorted20) {
                my $pattern;
                @words = ();
                @words = split /( )+/, $l2221;
                @value = ();
                @value = split /\./, $words[0];
                $flag_separatewithdot =
                  0;    #When heirachy have both dot and a slash
                $flag_separatewithoutdot = 0;    #When heirachy have only slash
                if ( $words[0] =~ m/\// ) {
                    $separate             = pop @value;
                    $flag_separatewithdot = 1;
                    if ( $separate =~ m/^$/ ) {
                        $separate                = $words[0];
                        $flag_separatewithoutdot = 1;
                    }
                }
                if ( $flag_separatewithoutdot == 1 ) {
                    @sep = ();
                    @sep = split /\//, $separate;
                    pop @sep;
                    pop @sep;
                    $separate = join( "/", @sep );
                    $pattern = $separate;
                }
                elsif ( $flag_separatewithdot == 1 ) {
                    $pattern = join( ".", @value );
                    @sep     = ();
                    @sep     = split /\//, $separate;
                    pop @sep;
                    pop @sep;
                    $separate = join( "/", @sep );
                    $pattern = $pattern . '.' . $separate;
                }
                else {
                    pop @value;
                    pop @value;
                    $pattern = join( ".", @value );
                    @value = ();
                }
                if ( $pattern =~ m/^$/ ) { }
                else {
                    print DATA2
                    "\n****************Device_Group:$pattern****************\n\n";
                    chomp($head);
                    $head = "$head reference_voltage_value delta_voltage\n";
                    $head =~ s/ +/\t/g;
                    print DATA2 "$head";
                    foreach my $l22211 (@sorted20) {
                        if ( $l22211 =~ $pattern ) {
                            $l22211 =~ s/ +/\t/g;
                            @l22_temp  = ();
                            @l22_temp1 = ();
                            @l22_temp  = split /\t/, $l22211;
                            @l22_temp1 = split /\./, $l22_temp[0];
                            if ( $#l22_temp1 >= 2 ) {
                                $field1 =
                                  shift @l22_temp1;    #Take out first field
                                $field2 =
                                  shift @l22_temp1;    #Take out second field
                                my $merge1 = join( ".", $field1, $field2 )
                                  ;                    #Merge first and second
                                my $merge2 =
                                  join( ".", @l22_temp1 ); #Merge the rest array
                                my $final_merge =
                                  join( "\t", $merge1, $merge2 );
                                $l22_temp[0] = $final_merge;
                            }
                            else {
                                $l22_temp[0] = "NA\t$l22_temp[0]";
                            }
                            $l22211 = join( "\t", @l22_temp );
                            print DATA2 "$l22211";
                            $l22211 = "";
                        }
                    }
                }
            }
        }
        @arr5   = ();
        @arr10  = ();
        @arr101 = ();
        @arr20  = ();

        #*******************************For Chkznode files ******************************************************************

        foreach my $chkz2 (@chkz1) {
            open( DATA2, '>', "$chkz2.csv" ) or die "$chkz2.csv Couldn't be created: $! ";    # nolint open>
            $flag = 0;

            my @lines = read_file($chkz2);
            foreach my $line (@lines) {
                $line .= "\n";
                if ( $line =~ m/Number of Error/ ) { last; }
                if ( $flag == 1 ) {
                    @words = ();
                    @words = split /( )+/, $line;
                    shift @words;
                    shift @words;
                    $line = join( "  ", @words );
                }
                if ( $line =~ m/hi-zstate-node/ ) {
                    $flag = 1;
                }
            }

            #By default for grouping devices heirachy is taken as slash itself.
            foreach my $line (@lines) {
                last if ( $line =~ m/Number of Error/ );
                if ( $flag == 1 ) {
                    my $pattern;
                    @words = ();
                    @words = split /( )+/, $line;
                    @value = ();
                    @value = split /\./, $words[0];
                    $flag_separatewithdot =
                      0;    #When heirachy have both dot and a slash
                    $flag_separatewithoutdot = 0; #When heirachy have only slash
                    if ( $words[0] =~ m/\// ) {
                        $separate             = pop @value;
                        $flag_separatewithdot = 1;
                        if ( $separate =~ m/^$/ ) {
                            $separate                = $words[0];
                            $flag_separatewithoutdot = 1;
                        }
                    }
                    if ( $flag_separatewithoutdot == 1 ) {
                        @sep = ();
                        @sep = split /\//, $separate;
                        pop @sep;
                        $separate = join( "/", @sep );
                        $pattern = $separate;
                    }
                    elsif ( $flag_separatewithdot == 1 ) {
                        $pattern = join( ".", @value );
                        @sep     = ();
                        @sep     = split /\//, $separate;
                        pop @sep;
                        $separate = join( "/", @sep );
                        $pattern = $pattern . '.' . $separate;
                    }
                    else {
                        pop @value;
                        $pattern = join( ".", @value );
                        @value = ();
                    }
                    if ( $pattern =~ m/^$/ ) { }
                    else {
                        print DATA2
                        "\n****************Device_Group:$pattern****************\n\n";
                        print DATA2 "$head";
                        foreach my $line2 (@lines) {
                            my $final_merge;
                            my $merge1;
                            my $merge2;
                            if ( $line2 =~ $pattern ) {
                                $line2 =~ s/ +/\t/g;
                                @l22_temp  = ();
                                @l22_temp1 = ();
                                @l22_temp  = split /\t/, $line2;
                                @l22_temp1 = split /\./, $l22_temp[0];
                                if ( $#l22_temp1 >= 2 ) {
                                    $field1 =
                                      shift @l22_temp1;    #Take out first field
                                    $field2 =
                                      shift @l22_temp1;   #Take out second field
                                    $merge1 = join( ".", $field1, $field2 )
                                      ;    #Merge first and second
                                    $merge2 = join( ".", @l22_temp1 )
                                      ;    #Merge the rest array
                                    $final_merge =
                                      join( "\t", $merge1, $merge2 );
                                    $l22_temp[0] = $final_merge;
                                }
                                elsif ($#l22_temp1 == 1
                                    && $l22_temp[0] =~ m/\// )
                                {
                                    $field1 =
                                      shift @l22_temp1;    #Take out first field
                                    my @slash_temp = split /\//, $l22_temp1[0];
                                    $field2 = shift @slash_temp;
                                    $merge1 = join( ".", $field1, $field2 )
                                      ;    #Merge first and second
                                    $merge2 = join( "/", @slash_temp )
                                      ;    #Merge the rest array
                                    $final_merge =
                                      join( "\t", $merge1, $merge2 );
                                    $l22_temp[0] = $final_merge;
                                }

                                #elsif ( $#l22_temp1 == 0 && $l22_temp[0] =~ m/\// ) {
                                #    @slash_temp= split /\//,$l22_temp1[0];
                                #    $field1= shift @slash_temp;
                                #    $field2= shift @slash_temp;
                                #    $merge1=join("/",$field1,$field2); #Merge first and second
                                #    $merge2=join("/",@slash_temp); #Merge the rest array
                                #    $final_merge=join("\t",$merge1,$merge2);
                                #    $l22_temp[0]=$final_merge;
                                #}
                                #else {
                                #    $l22_temp[0] = "NA\t$l22_temp[0]";
                                #}
                                #$line2=join("\t",@l22_temp);
                                print DATA2 "$line2";
                                $line2 = "";
                            }
                        }    # END foreach $line2 @lines
                    }
                }    # END if( $flag==1 )
                if ( $line =~ m/hi-zstate-node/ ) {
                    $head = $line;

                    #***To add a extra column in heading after device name ***#
                    $head =~ s/\*//;
                    $head =~ s/tag//;
                    $head =~ s/^\s+//;
                    $head =~ s/ +/\t/g;
                    $flag = 1;
                }
            }    # END foreach $line (@lines)
        }    # END foreach $chkz2 (@chkz1)


    }    ##  END Main
    iprint("Exiting 0...\n");
    exit 0;
}    #

#----------------------------------------------------------
sub filter_chkdevop($$$) {
    my $aref     = shift;
    my $noLayout = shift;
    my $noDummy  = shift;

    foreach my $line (@$aref) {
        if ( $noLayout == 1 && $noDummy == 0 ) {
            $line = "" if ( $line =~ m/xld/ );
        }
        if ( $noLayout == 0 && $noDummy == 1 ) {
            $line = "" if ( $line =~ m/dummy/ );
        }
        if ( $noLayout == 1 && $noDummy == 1 ) {
            $line = "" if ( $line =~ m/dummy/ );
            $line = "" if ( $line =~ m/xld/ );
        }
    }
    return ($aref);
}

#----------------------------------------------------------
sub read_opts_file($) {
    my $opt_inc = shift;

    #*******Reading ddck_options.inc
    my @voltage = read_file($opt_inc);

    #********Options for layout & Dummy device removal
    my $nolayout = 0;
    my $noDummy  = 0;
    foreach my $vol (@voltage) {
        next if ( $vol =~ m/^#/ );    # skip comments
        $nolayout = 1 if ( $vol =~ m/nolayoutDevice/ );
        $noDummy  = 1 if ( $vol =~ m/noDummyDevice/ );
    }
    return ( $nolayout, $noDummy, @voltage );
}

#----------------------------------------------------------
sub get_input_files($$) {
    my $search_directory = shift;
    my $regex            = shift;

    my @files;
    opendir( my $DIR, $search_directory )
      || fatal_error( "Couldn't open directory '$search_directory': '$!'\n",
        1 );
    while ( my $file = readdir $DIR ) {
        if ( $file =~ m/$regex/ ) {
            push( @files, "$search_directory/$file" );
        }
    }
    closedir($DIR);

    return ( sort by_number @files );
}

#-----------------------------------------------------------
sub by_number {
    my ($anum) = $a =~ /(\d+)$/;
    my ($bnum) = $b =~ /(\d+)$/;
    ( $anum || 0 ) <=> ( $bnum || 0 );
}

#-----------------------------------------------------------
sub create_csv_from_dcpaths_report($) {
    print_function_header();
    my $fname_dcpaths = shift;

    my $path;
    my $short_path;
    my $device;
    my $current;
    my $r_network;
    my $error;
    my $temp;
    my $pathFound = "FALSE";

    open( my $fh, '<', $fname_dcpaths ) || die "Couldn't open file '$fname_dcpaths': $!\n";    # nolint open<
    my @csv_lines;

    while ( my $line = <$fh> ) {
        if ( $line =~ /Number of Error/ ) {
            $error = substr( $line, 20 );
            chomp($error);
            next;
        }

        if ( $line =~ /^(\s)+\-+R Network-+/ ) {
            next;
        }

        if ( $line =~ /^\* Path/ ) {
            $path = $line;
            chomp($path);
            my @fields = split / /, $path;
            my $j = index( $path, "at " );
            $short_path = substr( $path, 13, $j ) . "at \n";
            $short_path =~ s/^ *//g;
            chomp($short_path);

            $temp = <$fh>;
            my $i = index( $temp, "MOS)" );
            $device = substr( $temp, 0, $i - 3 ) . "MOS)\n";
            $device =~ s/^ *//g;

            $current = substr( $temp, $i + 4 );
            $current =~ s/^ *//g;
            chomp($current);

            $temp = <$fh> . <$fh> . <$fh>;
            $temp =~ s/\n//g;
            $temp =~ s/  *//g;
            $r_network = $temp;

            push( @csv_lines,
                "\n@fields[4..8],$device,$current,$r_network,----R Network----,"
            );

            $pathFound = "TRUE";

            next;
        }

        if ( $pathFound eq "TRUE" ) {
            $temp = $line;
            chomp($temp);
            push( @csv_lines, $temp );
        }

    }

    close($fh);

    foreach my $line (@csv_lines) {
        $line .= ",Err:$error\n";
    }

    unshift( @csv_lines, "Path,Device,Current,R Network" );
    dprint( HIGH, pretty_print_aref( \@csv_lines ) . "\n" );
    write_file( \@csv_lines, "$fname_dcpaths.csv" );

    return ();
}

#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
sub process_cmd_line_args() {
    ## get specified args
    my ( $opt_inc, $opt_dir, $opt_nousage, $opt_help, $opt_debug,
        $opt_verbosity );

    my $success = GetOptions(
        "help!"       => \$opt_help,
        "inc=s"       => \$opt_inc,
        "dir=s"       => \$opt_dir,
        "nousage"     => \$opt_nousage,
        "debug=i"     => \$opt_debug,
        "verbosity=i" => \$opt_verbosity,
    );

    $main::VERBOSITY = $opt_verbosity if ( defined $opt_verbosity );
    $main::DEBUG     = $opt_debug     if ( defined $opt_debug );

    ## quit with usage message if GetOptions failed, or -help
    &usage(1) unless ($success);
    &usage(0) if ( defined $opt_help );

    ## quit with usage message unless user specified $opt_inc
    &usage(0) unless ( defined $opt_inc );
    if ( -d $opt_inc ) {
        wprint("dcck options file (.inc) is a directory; '$opt_inc' \n");
        fatal_error("Fix error and restart...\n");
        usage(1);
    }

    #------------------------------------------------------
    #  Always provide a default path to search for input files
    #      if '-dir' not specified.
    if ( defined $opt_dir ) {
        iprint("Searching directory for input files:  '$opt_dir'\n");
    }
    else {
        $opt_dir = getcwd() unless ( defined $opt_dir );
        iprint( "No directory path specified, searching current working"
              . " directory for input files: '$opt_dir' \n" );
    }

    #------------------------------------------------------
    #  Now that path to search is defined, check for INC file
    #  Check to make sure $opt_inc is a readable FILE ....
    if ( -e $opt_inc && -r $opt_inc && !( -d $opt_inc ) ) {
        iprint("Found INC file to use ... \n\t '$opt_inc'.\n");
    }
    else {
        iprint("Specified options file (.inc) not readable: \n\t '$opt_inc'\n");
        iprint(
"Searching the directory path for options file ($opt_inc): \n\t '$opt_dir'\n"
        );
        $opt_inc = "$opt_dir/$opt_inc";
        if ( -e $opt_inc && -r $opt_inc && !( -d $opt_inc ) ) {
            iprint("Found INC file to use ... \n\t '$opt_inc'.\n");
        }
        else {
            eprint("DCCK options file _NOT_ readale: \n\t '$opt_inc' \n");
            fatal_error("Fix error and restart...\n");
            usage(1);
        }
    }
    return ( $opt_inc, $opt_dir, $opt_nousage );
}

#------------------------------------------------------------------------------
#  script usage message
#------------------------------------------------------------------------------
sub usage($) {
    my $exit_status = shift;

    print << "EOP" ;
Description
    Please look at the updated slides of the script.  The layout and dummy filter
         option is to be given in dcck_options.inc file and not as an argument to
         script. User must to provide complete path of dcck_options.inc as an
         argument to '-inc' at cmd line invocation of the script.
    ****************Sample dcck_options.inc file can be like***************************
        .options filter noLayoutDevice
        .options filter noDummyDevice
        .options voltage Default vddq
        .options voltage xp.xxtxfe vdd

USAGE : $PROGRAM_NAME [options] -inc <filename>

------------------------------------
Required Args:
------------------------------------
-inc  include file ... record options here


------------------------------------
Optional Args:
------------------------------------
-help           Print this screen
-dir       <path>  path to the directory with the testbench results
-verbosity  <#>    print additional messages ... includes details of system calls etc. 
                   Must provide integer argument -> higher values increases verbosity.
-debug      <#>    print additional diagnostic messagess to debug script
                   Must provide integer argument -> higher values increases messages.
EOP

    exit $exit_status;
}    # usage()

1;
