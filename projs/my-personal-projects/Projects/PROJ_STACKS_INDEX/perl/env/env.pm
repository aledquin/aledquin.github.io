use strict;
use warnings;

package env::env;



our $LOC_DIR = "/slowfs/dcopt105/alvaro/GitLab/PROJ_STACKS_INDEX";

our $PRJ_DIR = "$LOC_DIR/projects";
check_and_make($PRJ_DIR,"d");
our $LOG_DIR = "$LOC_DIR/log_info";
check_and_make($LOG_DIR,"d");

our $MSIP_PROJ_ROOT = "/remote/cad-rep/projects";
our $CAD_PROJ_ENV_NAME = "project.env";

our $PCS_PROJ_ROOT 	 = "/remote/cad-rep/proj";
our $METAL_SLACK_ENV_NAME = "env.tcl";

our $DECK_VAR_NAME = "IcvRunDRC";

our $INFO_LOG_FILE;


















sub check_and_make {
    my ($file_name) = shift;
    my ($type) = shift;

    given ($type){
        when ( $_ == "d") {
            rmdir($file_name);
            unless(mkdir $directory) {
                die "Unable to create $directory\n";
            };
        }
        when ( $_ == "f") {
            unlink($file_name);
            open my $fileHandle, "<", "$file_name";
            close $fileHandle;
        }
    }

}

sub get_value_by_location_from_file {
    my ($file_path) = shift;
    my ($line_number) = shift;
    my ($element) = shift;
    my ($marker) = shift;

    return `cat $file_path | head -$line_number | tail -1 | cut -d'$marker' -f$element`;
}

sub get_value_from_another {
    my ($variable) = shift;
    my ($marker) = shift;
    my ($element) = shift;

    return `echo $variable | cut -d'$marker' -f$element`;
}

sub write_in_file {
    my ($file_name) = shift;
    my ($line_to_add) = shift;

    open my $file_handle, '<', $file_name;
    print $file_handle "$line_to_add\n";
}

sub check_and_make {
    my ($file_name) = shift;
    my ($type) = shift;

    given ($type){
        when ( $_ == "d") {
            rmdir($file_name);
            unless(mkdir $directory) {
                die "Unable to create $directory\n";
            };
        }
        when ( $_ == "f") {
            unlink($file_name);
            open my $fileHandle, "<", "$file_name";
            close $fileHandle;
        }
    }

}