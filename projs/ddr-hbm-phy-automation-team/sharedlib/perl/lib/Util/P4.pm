###############################################################################
# P4 lib
# Useful P4 utilties
# Author: Harsimrat Singh Wadhawan
###############################################################################
package Util::P4;

use strict;
use warnings;

use Capture::Tiny qw/capture/;
use File::Path;
use Try::Tiny;

use FindBin qw($RealBin $RealScript);
use lib "$RealBin/../../lib/";
use Util::CommonHeader;
use Util::Messaging;
use Util::Misc;

use Exporter;

our @ISA   = qw(Exporter);

# Symbols (subs or vars) to export by default 
our @EXPORT    = qw( 
  da_p4_print_file da_p4_dirs da_p4_files
  da_p4_is_in_perforce da_p4_create_client da_p4_delete_client da_p4_add_edit
  da_p4_sync_root da_p4_submit
);

# Symbols to export by request 
our @EXPORT_OK = qw();

#-------------------------------------------------------------------------------
#  check if a file is in p4 (perforce)
#
#  Return Values:
#   0: Something went wrong, either the file passed in is empty, or the p4
#      command has failed.
#   1: Success
#-------------------------------------------------------------------------------
sub da_p4_is_in_perforce($) {
    print_function_header();
    my $file = shift;

    if ( ! $file ){
        return 0;
    }

    my ($stdout, $system_status) = run_system_cmd("p4 files -e $file", $main::VERBOSITY-1);            
    if( $system_status || $stdout =~ m/no such file/ ){
       return 0;
    }else{
       return 1;
    }
}

#--------------------------------------
# Print file specified via a P4 location.
# Inputs: 
#   location => p4 path of the file
# Output: 
#   Standard output returned on success, otherwise NULL_VAL returned
#--------------------------------------
sub da_p4_print_file($) {
    
    print_function_header();
    my $location = shift;     

    my $verbosity=NONE;
    my ($out, $err) = run_system_cmd("p4 print -q $location", $verbosity);        

    dprint(HIGH, "$err\n");    
    if ($out =~ /no such file/ig or $err > 0) {
      return NULL_VAL;
    }

    return $out;

}

#--------------------------------------
# Print files in a P4 directory.
# Inputs: 
#   location => p4 path of the directory
# Output: 
#   Array of files found at the depot location
#--------------------------------------
sub da_p4_files($) {
    
    print_function_header();
    my $location = shift;    

    my $verbosity=$main::VERBOSITY-2;
    my ($out, $err) = run_system_cmd("p4 files -e $location", $verbosity);            
    if ($out =~ /no such file/ig or $err > 0) {
      dprint(MEDIUM, "p4 files -e '$location' \$out='$out'\n\$err='$err'\n");
      return NULL_VAL;
    }

    # Split by newline to create a list of files
    my @return = split("\n", $out);
    
    # Remove the comments.
    for (my $i = 0; $i < @return; $i++){      
      $return[$i] =~ s/\#.*$//ig;
    }

    return @return;

}

#--------------------------------------
# Print directories in a P4 directory.
# Inputs: 
#   location => p4 path of the directory
# Output: 
#   Array of directories found at the depot location
#--------------------------------------
sub da_p4_dirs($) {
    
    print_function_header();
    my $location = shift;    

    my $verbosity=NONE;
    my ($out, $err) = run_system_cmd("p4 dirs $location", $verbosity);            
    if ($out =~ /no such file/ig or $err > 0) {
      return NULL_VAL;
    }

    # Split by newline to create a list of files
    my @return = split("\n", $out);
    
    # Remove the comments.
    for (my $i = 0; $i < @return; $i++){      
      $return[$i] =~ s/\#.*$//ig;
    }

    return @return;

}

#--------------------------------------
# Client object specification:
# A hash containing the client name, root, DEPOT2CLIENT and CLIENT2DEPOT maps
#
# $client->{'NAME'}         = $clientName;
# $client->{'ROOT'}         = $clientRoot;
# $client->{'DEPOT2CLIENT'} = {};  #  map depot file to client file
# $client->{'CLIENT2DEPOT'} = {};  #  map client file to depot file
#--------------------------------------

#--------------------------------------
# Create a new P4 client.
# Inputs: 
#   clientname    => Name of the client that needs to be created.
#   clientRoot    => Root
#   aref_viewList => ref to an array of views
#
# Output: 
#   Client object specification if success
#   NULL_VAL if failed
#--------------------------------------
sub da_p4_create_client($$$) {
  print_function_header();
    
  my $clientName    = shift;
  my $clientRoot    = shift;
  my $aref_viewList = shift;

  if( !defined $clientName || $clientName eq EMPTY_STR) {
    dprint(HIGH, "p4_create_client: invalid clientName\n");
    return NULL_VAL;
  }

  if( !defined $clientRoot || $clientRoot eq EMPTY_STR) {
    dprint(HIGH, "p4_create_client: invalid clientRoot\n");
    return NULL_VAL;
  }

  if(! defined $aref_viewList ) {
    dprint(HIGH, "p4_create_client: aref_viewList is not defined\n");
    return NULL_VAL;
  }
  
  my $thissub = get_subroutine_name();
  dprint(HIGH, "$thissub =>\n\t Client=$clientName\n\t Root=$clientRoot\n");

  #----------------------------------------------
  # Remove pre-existing files and directories.
  # returns 0 if no files etc
  # returns >0 if it removed files etc
  my $fail = rmtree $clientRoot;

  # Create a new worktree
  my $passed = mkdir $clientRoot; # mkdir returns TRUE if the dir got created
  if( ! $passed ){
      eprint( "$thissub => Couldn't make directory: '$clientRoot'\n" );
      return NULL_VAL;
  }else{
      dprint(HIGH, "Created p4 Root directory: '$clientRoot' \n" );
  }

  my ($stdout, $retval);
  #----------------------------------------------
  # Check to see if client already exists for
  #    this user. If the named client exists,
  #    delete it.
  #----------------------------------------------
  my $username = get_username() || 'bad_user';
  ($stdout, $retval) = run_system_cmd("p4 clients -u $username", $main::VERBOSITY );
  if( $stdout =~ m/Client $clientName / ){
      #----------------------------------------------
      # Delete the client if it exists, first.
      #    If it doesn't exist, that's ok.
      ($stdout, $retval) = run_system_cmd("p4 client -d $clientName", $main::VERBOSITY );
      # p4 client -d random          => RetVal = 1, STDOUT =>Client 'random' doesn't exist.
      # p4 client -d exists          => RetVal = 0, STDOUT =>Client 'exists' deleted.
      # p4 client -d msip_cd_juliano => RetVal = 1, STDOUT =>Client 'msip_cd_juliano' has files opened. To delete the client, revert any opened files and delete any pending changes first. An administrator may specify -f to force the delete of another user's client.
      # p4 client -d => RetVal = 1, STDOUT =>Usage: client -d [ -f [ -Fs ] ] clientname
                                            #Missing/wrong number of arguments.
      return( NULL_VAL ) if( $retval );
  }

  #----------------------------------------------
  # Create a  default client specification.
  #     Root: => $PWD
  #     View: => (none)
  ($stdout, $retval) = run_system_cmd("p4 -c $clientName client -o");
  chomp($stdout);
  if( $retval ){
      eprint( "$stdout\n" );
      return( NULL_VAL );
  }else{
      dprint(HIGH, "Created a default p4 client ...\n" );
  }

  #-----------------------------------------------
  # Replace default client root ($PWD) w/user specified client root.
  my $clientSpec = $stdout;
  $clientSpec =~ s/\n(Root:\s+)\S+/$1$clientRoot/;
  dprint(HIGH, "$clientSpec");

  # Append list of views to the new client specification.
  foreach my $view (@{$aref_viewList}) { 
    if( $view ne EMPTY_STR ){
        # $view must have a string, otherwise a TAB
        # (\t) is appended and causes p4 client parse error
        $clientSpec = "$clientSpec\t$view\n" 
    }
  }
  # Need to terminate file in a newline when no views exist
  $clientSpec .= "\n";
  dprint(INSANE, "$clientSpec.\n");

  #-----------------------------------------------
  # Write specification to a tempoarary file
  my $specFile = "$clientRoot/clientSpec.tmp";
  Util::Misc::write_file($clientSpec, $specFile);

  #-----------------------------------------------
  # Update client specification
  ($stdout, $retval) = run_system_cmd( "p4 -c $clientName client -i < $specFile", $main::VERBOSITY );
  if( $retval ){
      dprint(HIGH, "p4_create_client: p4 -c '$clientName' client -i < '$specFile' : err='$retval', out='$stdout'\n");
      eprint("$thissub=> Problem creating client using specFile='$specFile'\n\t$stdout \n");
      return( NULL_VAL );
  }
  dprint(CRAZY, "$stdout\n");
  unlink ($specFile);

  my $client = {};
  $client->{'NAME'}         = $clientName;
  $client->{'ROOT'}         = $clientRoot;
  $client->{'DEPOT2CLIENT'} = {};            #  map depot file to client file
  $client->{'CLIENT2DEPOT'} = {};            #  map client file to depot file
  
  return $client;

}

#--------------------------------------
# Delete a P4 client.
# Inputs: 
#   client => Client object
#--------------------------------------
sub da_p4_delete_client($) {
  print_function_header();
  my $client = shift;
    
  return( 1 ) unless( defined $client);

  # Verify the hash element exists, and is not empty string
  if( exists $client->{'NAME'} && defined $client->{'NAME'} && $client->{'NAME'} ne EMPTY_STR ){ 
    my $cname = $client->{'NAME'};
    my ($out, $err) = run_system_cmd("p4 client -d $cname");
  }else{  
    dprint(MEDIUM, "Tried to delete p4 client object, but key 'NAME' doesn't exist! Something went WRONG.\n" );
  }
    
  if (exists $client->{'ROOT'}) {
    rmtree $client->{'ROOT'} if -e $client->{'ROOT'};
  }

  return( 0 );
}

#--------------------------------------
# Add a file to the deafult P4 client's changelist
# Inputs: 
#   client => Client object
#   clientFile => Path of the file that is to be added.
# Output:
#   1 on success, 0 upon failure
#--------------------------------------
sub da_p4_add_edit($$) {
    print_function_header();
    my $client     = shift;
    my $clientFile = shift;

    if (! exists $client->{'NAME'} ) {
      return 0;
    }

    try {
        if ( -e $clientFile ) {
            my ($out, $err) = run_system_cmd( "p4 -c $client->{'NAME'} edit $clientFile", $main::VERBOSITY );
            dprint(CRAZY, $out);
        }
        else {
            my ($out, $err) = run_system_cmd( "p4 -c $client->{'NAME'} add -t text $clientFile", $main::VERBOSITY );
            dprint(CRAZY, $out);
        }
        return 1;
    }
    catch {
        eprint " $_\n";
        return 0;
    }
}

#--------------------------------------
# Sync all files in the client's P4 workspace
# Inputs: 
#   client => Client object
# Output:
#   Count of files added as a result of the sync.
#--------------------------------------
sub da_p4_sync_root($) {
    print_function_header();
    my $client = shift;
    my $count  = 0;

    if (! $client ) {
      return NULL_VAL;
    }

    if ( (! exists $client->{'NAME'}) || (! exists $client->{'ROOT'} )) {

      return $count;

    }
            
    my ($out, $err) = run_system_cmd("p4 -c $client->{'NAME'} sync $client->{'ROOT'}/...");
    my @lines = split("\n", $out);

    foreach my $line (@lines) {
        if ( $line =~ /(\S+) - added as (\S+)/ ) {
            $count++;
            $client->{'DEPOT2CLIENT'}->{$1} = $2;
            $client->{'CLIENT2DEPOT'}->{$2} = $1;
        }
    }

    return $count;

}

#--------------------------------------
# Sync all files in the client's P4 workspace
# Inputs: 
#   client => Client object
#   clientFile => File to be added 
#   desc => description of the submit 
# Output:
#   Count of files added as a result of the sync.
#--------------------------------------
sub da_p4_submit($$$) {

    print_function_header();
    my $client     = shift;
    my $clientFile = shift;
    my $desc       = shift;

    run_system_cmd( "p4 -c $client->{'NAME'} submit -d \"$desc\" $clientFile", $main::VERBOSITY );

}

################################
# A package must return "TRUE" #
################################

1;
__END__
