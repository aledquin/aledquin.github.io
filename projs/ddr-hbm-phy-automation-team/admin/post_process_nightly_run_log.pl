#!/depot/perl-5.14.2/bin/perl
#!/bin/perl
# Modify index.html by copying any temp files to nightly_run/ and change
# See /tmp/ljames_* for details to a URL link to the file that was copied to
# nightly_run/ folder
# nolint utils__script_usage_statistics
# nolint system
# nolint open>
# nolint open<
#
use strict;
use warnings;
use File::Basename;

sub Main(){
    my $username = getlogin() || getpwuid($<) || $ENV{'USER'};
    my $htmldir  = "/u/ljames/public_html/nightly_run";
    my $log_file = shift @ARGV;
    if ( $log_file eq "-help" ){
        exit(0);
    }

    open(my $fh, "<", $log_file) || die "Can't open '$log_file': $!";
    my @input_text = <$fh>;
    close($fh);

    print("Running: post_process_nightly_run_log.pl $log_file\n");

    my @output_text;
    foreach my $line ( @input_text) {
       $line =~ s/.\[0m//g;    # remove the ending escape sequence of colors
       $line =~ s/.\[31m//g;   # remove color escape beginnings
       $line =~ s/.\[32m//g;
       $line =~ s/.\[37;4.m//g;
       $line =~ s/.\[33m//g;

       # Highlight FAILED or PASSED text
       if ( $line =~ m/^(\s*)FAILED LINT(.*$)/i) {
           $line = "$1<b class=\"failed\">FAILED LINT</b>$2 \n";
       } elsif ( $line =~ m/^(\s*)FAILED\s+COMPILE(.*$)/i) {
           $line = "$1<b class=\"failed\">FAILED COMPILE</b> $2 \n";
       } elsif ( $line =~ m/^(\s*)FAILED(.*$)/i) {
           $line = "$1<b class=\"failed\">FAILED</b>$2 \n";
       } elsif ( $line =~ m/^(\s*)PASSED\s+COMPILE(.*$)/i) {
           $line = "$1<b class=\"passed\">PASSED COMPILE</b>$2 \n";
       } elsif ( $line =~ m/^(\s*)PASSED(.*$)/i) {
           $line = "$1<b class=\"passed\">PASSED</b>$2 \n";
       } elsif ( $line =~ m/^(-[EF]-)(.*$)/i ) {
           $line = "<b class=\"failed\">$1</b>$2 \n";
       } elsif ( $line =~ m/^(-W-)(.*$)/i ) {
           $line = "<b class=\"warning\">$1</b>$2 \n";
       }

       if ($line =~ m/^(.*)See\s+(.*)\s+for details(.*)$/) {
            my $file_path = $2;
            #print("file_path is '$file_path'\n");
            my $filename = basename($file_path);
            system("cp -f $file_path $htmldir/$filename.html");
            $line = "$1 See <a href=\"./$filename.html\">$file_path</a> for details $3 \n";
            process_copied_file( "$htmldir/$filename.html", $htmldir );
        }        push( @output_text, $line);
    }

    unlink( $log_file ) if ( -e $log_file );
    open(my $ofh , ">", "${log_file}") || die "Can't open '$log_file': $!";
    foreach my $line ( @output_text) {
        print $ofh $line;
    }
    close($ofh);

}

#
# This puts the html bold color styles in place
#
sub push_styles($){

    my $aref_output_text = shift;

    push(@$aref_output_text, "<style>\n");
    push(@$aref_output_text, "b.failed  {\n color:hsl(  0, 100%, 50%);\n }\n");
    push(@$aref_output_text, "b.passed  {\n color:hsl(120, 100%, 39%);\n }\n");
    push(@$aref_output_text, "b.warning {\n color:hsl( 16,  88%, 54%);\n }\n");
    push(@$aref_output_text, "</style>\n");
    push(@$aref_output_text, "<pre>");

}

#
# This looks in $thefile for any lines that requires a HREF_LINK; such
# as 'See details in FILEPATH'; if it sees this then it will copy the
# FILEPATH to HTMLDIR/filename ; and it will modify the 
# 'See details in FILEPATH' string with an HTML <a href=""></a><br> line.
#
# It will also then move the actual $thefile to $thefile.old and create a new
# $thefile with the lines read including the modified lines.
# 
sub process_copied_file($$){
    my $thefile = shift;
    my $htmldir = shift;

    print("\tprocess_copied_file( $thefile )\n");

    open(my $fh, "<", $thefile) || die "Can't open '$thefile': $!";
    my @input_text = <$fh>;
    close($fh);

    my @output_text;
    push_styles(\@output_text);

    my $nfail = 0;
    my $npass = 0;
    my $nwarn = 0;
    my $running_admin = 0; 

    foreach my $line ( @input_text) {
        $line =~ s/.\[0m//g;    # remove the ending escape sequence of colors
        $line =~ s/.\[31m//g;   # remove color escape beginnings
        $line =~ s/.\[32m//g;
        $line =~ s/.\[37;4.m//g;
        $line =~ s/.\[33m//g;

        if ( $line =~ m/Running admin\/check_code\.csh/){
            # If we already processed a Running admin section, then this most 
            # likely belongs at the end of that section. 
            if ( $running_admin ) {
                my $ntests = $nfail + $npass + $nwarn;
                my $append_line = "\n+-------------------------------------------------------------------------------\n"; 
                $append_line .= "| nFailed: $nfail   nPassed: $npass  nWarnings: $nwarn nTests: $ntests\n";
                $append_line .= "+-------------------------------------------------------------------------------\n"; 
                my $last_line = pop @output_text;  # remove previous last line
                push( @output_text, $append_line); # insert error counts info
                push( @output_text, $last_line);   # re-add the previous last line
            }
            $running_admin = 1;
            $nfail = 0;
            $npass = 0;
            $nwarn = 0;
        } elsif ( $line =~ m/End Functional Tests/) {
            my $ntests = $nfail + $npass + $nwarn;
            my $append_line = "\n+-------------------------------------------------------------------------------\n"; 
            $append_line .= "| nFailed: $nfail   nPassed: $npass  nWarnings: $nwarn nTests: $ntests\n";
            $append_line .= "+-------------------------------------------------------------------------------\n"; 
            my $last_line = pop @output_text;  # remove previous last line
            push( @output_text, $append_line); # insert error counts info
            push( @output_text, $last_line);   # re-add the previous last line
        } elsif ( $line =~ m/Functional Tests/ ) {
             if ( $running_admin ) {
                my $ntests = $nfail + $npass + $nwarn;
                my $append_line = "\n+-------------------------------------------------------------------------------\n"; 
                $append_line .= "| nFailed: $nfail   nPassed: $npass  nWarnings: $nwarn nTests: $ntests\n";
                $append_line .= "+-------------------------------------------------------------------------------\n"; 
                my $last_line = pop @output_text;  # remove previous last line
                push( @output_text, $append_line); # insert error counts info
                push( @output_text, $last_line);   # re-add the previous last line
            }
            $running_admin = 0;           
        }

        # Highlight FAILED or PASSED text
        if ( $line =~ m/^(\s*)FAILED LINT(.*$)/i) {
            $line = "$1<b class=\"failed\">FAILED LINT</b>$2 \n";
            $nfail++;
        } elsif ( $line =~ m/^(\s*)FAILED COMPILE(.*$)/i) {
            $line = "$1<b class=\"failed\">FAILED COMPILE</b>$2 \n";
            $nfail++;
        } elsif ( $line =~ m/^(\s*)FAILED(.*$)/i) {
            $line = "$1<b class=\"failed\">FAILED</b>$2 \n";
            $nfail++;
        } elsif ( $line =~ m/^(\s*)PASSED COMPILE(.*$)/i) {
            $line = "$1<b class=\"passed\">PASSED COMPILE</b>$2 \n";
            $npass++;
        } elsif ( $line =~ m/^(\s*)PASSED(.*$)/i) {
            $line = "$1<b class=\"passed\">PASSED</b>$2 \n";
            $npass++;
        } elsif ( $line =~ m/^(-[EF]-)(.*$)/i ) {
            $line = "<b class=\"failed\">$1</b>$2 \n";
            $nfail++;
        } elsif ( $line =~ m/^(-W-)(.*$)/i ) {
            $line = "<b class=\"warning\">$1</b>$2 \n";
            $nwarn++;
        }

        if ($line =~ m/^(.*)See details in\s+(.*)\s+(.*)$/) {
            my $file_path = $2;                   # ./t/run-tests_alphafoo.log 
            my $filename = basename($file_path);  # run-tests_alphafoo.log
            if ( ! -e $file_path ) {
                print("ERROR: Unable to see '$file_path' !\n");
            }else{
                system("cp -f $file_path $htmldir/");
                $line = "$1;See details in <a href=\"./$filename\">$file_path</a>$3\n";
            }
        } elsif ($line =~ m/^(.*)See\s+(\/tmp.*log)\s+(.*)$/) {
            my $file_path = $2;                   # /tmp/ddr_da_lint_44017.log
            my $filename = basename($file_path);  # ddr_da_lint_44017.log
            if ( ! -e $file_path ) {
                print("ERROR: Unable to see '$file_path' !\n");
            }else{
                system("cp -f $file_path $htmldir/");
                $line = "$1 See <a href=\"./$filename\">$file_path</a>$3\n";
            }
        }
        push( @output_text, $line);
    }
    push(@output_text, "</pre>");

    print("\tmove '$thefile' to '$thefile.old'\n");
    system("mv -f $thefile $thefile.old");
    print("\tCreate new file '$thefile'\n");
    open(my $ofh , ">", "${thefile}") || die "Can't open '$thefile': $!";
    foreach my $line ( @output_text) {
        print $ofh $line;
    }
    close($ofh);

}

Main();
