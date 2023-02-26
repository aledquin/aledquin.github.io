#!/depot/perl-5.14.2/bin/perl
use strict;
use warnings;
use Pod::Usage;
use Data::Dumper;
use File::Copy;
use Getopt::Std;
use Getopt::Long;
use Readonly;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Cwd     qw( abs_path );
use Carp    qw( cluck confess croak );
use FindBin qw( $RealBin $RealScript );
use Text::ParseWords;

use lib "$RealBin/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging    qw(iprint eprint);
use Readonly;
#--------------------------------------------------------------------#
#our $STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
our $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $PROGRAM_NAME = $RealScript;
our $VERSION      = '2022.11'; # Syntax: YYYYww##[.#] optional day 1-7
                                # The work week number can be found in
                                # your outlook calendar. The days are 1=sunday
                                # 2=monday ... 7=saturday
#--------------------------------------------------------------------#


use Capture::Tiny qw/capture/;
use File::Basename qw(dirname basename);
use FindBin qw($RealBin $RealScript);


utils__script_usage_statistics( $RealScript, $VERSION);


package SortArc_utils;


our @EXPORT = qw(readLib writeLib findAllGroups sortArcs setFilePath error_msg getName getPinlist sortArcType);
#use strict;

our $ELM_CLASS = 0;
our $ELM_TYPE = 1;
our $ELM_NAME = 2;
our $ELM_VALUE = 3;
our $ELM_MEMBERS = 4;
our $ELM_ROOTNAME = 5;
our $ELM_BIT = 6;
our $ELM_FLAGS = 7;
our $ELM_TEMP0 = 8;
our $ELM_PARENT = 9;
our $ELM_COMMENT = 10;
our $ELM_TEMP1 = 11;

our $CLS_FILE = "file";
our $CLS_GROUP = "group";
our $CLS_SIMPLEATTR = "simpleattr";
our $CLS_COMPLEXATTR = "complexattr";

our $FLG_VALQUOTED = 0x01;
our $FLG_NAMEQUOTED = 0x02;
our $FLG_VALTOUCHED = 0x04;
our $FLG_ISBUS = 0x08;
our $FLG_BUSSQUARE = 0x10;
our $FLG_BUSPOINTY = 0x20;


sub createObject {
  my ($class, $type, $name, $value, $parent) = @_;
  my $obj = [];
  $obj->[$ELM_CLASS] = $class;
  $obj->[$ELM_TYPE] = $type;
  
  my ($valueUnquoted, $nameUnquoted, $valIsQuoted, $nameIsQuoted);
  
  if ($class eq $CLS_COMPLEXATTR) {
    $valIsQuoted = 0; 
    $nameIsQuoted = 0;
  }
  elsif($class eq $CLS_GROUP) {
    ($name, $nameIsQuoted) = unquote($name);
    $valIsQuoted = 0;
  }
  elsif($class eq $CLS_SIMPLEATTR) {
    ($value, $valIsQuoted) = unquote($value);
    $nameIsQuoted = 0;
  }
 
  $obj->[$ELM_NAME] = $name;
  $obj->[$ELM_VALUE] = $value;
  $obj->[$ELM_MEMBERS] = [];
  $obj->[$ELM_ROOTNAME] = undef;
  $obj->[$ELM_BIT] = undef;
  $obj->[$ELM_FLAGS] = 0x00000000;
  $obj->[$ELM_TEMP0] = undef;
  $obj->[$ELM_PARENT] = $parent;
  $obj->[$ELM_TEMP1] = undef;
  defFlag($obj, $FLG_VALQUOTED, $valIsQuoted);
  defFlag($obj, $FLG_NAMEQUOTED, $nameIsQuoted);
  processBusNotation($obj);
  ##### NOT IMPLIMENTING BUSnotaion NOW
  return $obj;
}


sub readLib {
  my $lib = shift;
  
  $lib = Cwd::abs_path($lib);
  my $root = createObject($CLS_FILE, undef, $lib, undef, undef);
  my $arc_type;
  Util::Messaging::iprint("Reading $lib\n");
  if (!(-r $lib)) {Util::Messaging::eprint("Cannot open $lib for read\n"); return } 
  
  open(my $LIB, ,"$lib");    #nolint open <
  my $line;
  my @context;
  my $current = $root;
  while ($line = readLine(*$LIB)) {
   if ($line eq "}") {
    $current = pop @context;
   }
   elsif ($line =~ /^(\S+)\s*\(\s*(\S*)\s*\)\s*{$/) {
    my $rec = createObject($CLS_GROUP, $1, $2, undef, $current);
    push @{$current->[$ELM_MEMBERS]}, $rec;
    push @context, $current;
    $arc_type = $1;
    $current = $rec;
   }
   elsif ($line =~ /^(\S+)\s+:\s+(.*)\s*;$/) {
    my $attrName = $1;
    my $attrValue = $2;
    $attrValue =~ s/^\s+|\s+$//g;
    my $rec = createObject($CLS_SIMPLEATTR, undef, $attrName, $attrValue, $current);
 
    push @{$current->[$ELM_MEMBERS]}, $rec;
   }
   elsif ($line =~ /^(\S+)\s*\(\s*(.*)\s*\)\s*;$/s) {
   my $rec = createObject($CLS_COMPLEXATTR, undef, $1, $2, $current);

   parseComplexAttrValue($rec);
   push @{$current->[$ELM_MEMBERS]}, $rec;
   }
   ####elsif ($line =~ /(\/\*.*comment.*reference path.*\\*\/)/s) {
   ####/* comment : reference path 55, checked path 201, reference path 55, checked path 202; */
   #elsif ($line =~ /(\/.*;\n\/\*.*comment.*reference path.*\\*\/)/s) {
   #####my $rec = createObject($CLS_SIMPLEATTR, undef, $ELM_COMMENT, $1, $current);
   #####push @{$current->[$ELM_MEMBERS]}, $rec;
   #}
   elsif ($line =~ /(\/\*.*comment.*reference path.*\\*\/)/s) {
	  ##  Comment. Form:  name (value);
	my $rec = createObject($CLS_SIMPLEATTR, undef, $ELM_COMMENT, $1, $current);
	    
	  push @{$current->[$ELM_MEMBERS]}, $rec;
	}
   else {
    print STDERR "Unhandled line: \"$line\"\n";
   }
}  
  close $LIB;

#print Dumper($root);
#dumpGroup($root, "");

return $root;

} #### 

sub parseComplexAttrValue {

    my $obj = shift;
    
    if (validateObject($obj, "parseComplexAttrValue", $CLS_COMPLEXATTR)) {
      my $attrVal = $obj->[$ELM_VALUE];
      $attrVal =~ s/\\\n//g;
      my @toks = Text::ParseWords::quotewords('\S*,\S*', 0, $attrVal);
      @{$obj->[$ELM_MEMBERS]} = @toks;
    }
}

sub writeLib {
  my $obj = shift;
  my $fileName = shift;
  my @dumpGroups;
  if ($obj->[$ELM_CLASS] eq $CLS_FILE) {
   if (!(defined $fileName)) {$fileName = $obj->[$ELM_NAME]}
   $fileName = Cwd::abs_path($fileName);
   @dumpGroups = @{$obj->[$ELM_MEMBERS]};
   
  }
  elsif (($obj->[$ELM_CLASS] eq $CLS_GROUP) && ($obj->[$ELM_TYPE] == "library")) {
   push @dumpGroups, $obj;
  }
  else {
   Util::Messaging::eprint("Object is neither a file nor a library group");
   return;
  }
  if (!(defined $fileName)) {
   Util::Messaging::eprint("Undefined fileName\n");
   return ;
  }
  
  Util::Messaging::iprint("Writing $fileName\n");
  
  my $n = @dumpGroups;
  if (open(my $OUT, ">","$fileName")) {    #nolint open >
    foreach my $l (@dumpGroups) {
      if (($l->[$ELM_CLASS] eq $CLS_GROUP) && ($l->[$ELM_TYPE] eq "library")) {
        dumpGroup(*$OUT, $l, "");
      }
    }
    close $OUT;
  }
  
  else {
    Util::Messaging::eprint("cannot open $fileName for write");
    return ;
  } 
}


sub getFlag {
 
   my $obj = shift;
   my $mask = shift;
   
   return ($obj->[$ELM_FLAGS] & $mask);
}

sub dumpGroup {
   my $fh = shift;
   my $group = shift;
   my $indent = shift;
   my $q = getFlag($group, $FLG_NAMEQUOTED) ? "\"" : "";
   my $name = $group->[$ELM_NAME];
   if (getFlag($group, $FLG_BUSSQUARE)) {$name =~ tr/<>/[]/}
   print $fh "$indent$group->[$ELM_TYPE] ($q$name$q) {\n";
   my $newIndent = "  $indent";
   
   foreach my $mbr (@{$group->[$ELM_MEMBERS]}) {
     if ($mbr->[$ELM_CLASS] eq $CLS_GROUP) {
       dumpGroup($fh, $mbr, $newIndent);
     }
     elsif ($mbr->[$ELM_CLASS] eq $CLS_SIMPLEATTR) {
       my $offset = length($mbr->[$ELM_NAME]) + 1;
       my $q = getFlag($mbr, $FLG_VALQUOTED) ? "\"" : "";
       if($mbr->[$ELM_NAME] eq $ELM_COMMENT) {dumpItem($fh, "$mbr->[$ELM_VALUE]", $newIndent, $offset);}
       else {dumpItem($fh, "$mbr->[$ELM_NAME] : $q$mbr->[$ELM_VALUE]$q ;", $newIndent, $offset);}
     }
     elsif ($mbr->[$ELM_CLASS] eq $CLS_COMPLEXATTR) {
       my $offset = length($mbr->[$ELM_NAME]) + 1;
       my $q = getFlag($mbr, $FLG_VALQUOTED) ? "\""  : "";
       dumpItem($fh, "$mbr->[$ELM_NAME]($q$mbr->[$ELM_VALUE]$q) ;", $newIndent, $offset);
     }
   }
 
 print $fh "$indent}  /* End $group->[$ELM_TYPE]($name) */\n";
}


sub dumpItem {
    
    my ($fh, $line, $indent, $offset) = @_;
    my $mi = "                                                                                                        ";
    my $exIndent = substr($mi, 0 , $offset);
    my $newIndent = "$exIndent$indent";
    my @lines = split (/\n/, $line);
    foreach my $l (@lines) {
      print $fh  "$indent$l\n";
      $indent = $newIndent;
    }
}


sub readLine {
  my $fh = shift;
  
  my $line;
  my $bfr = "";
  while ($line = <$fh>) {
    if($line !~/\/\*.*comment.*reference path.*\\*\//) {$line =~ s/\/\*.*\\*\///g; }
    my $last = substr($line, -2, 1);
    if($last eq "\\") {
    
      $line =~ s/^\s+//;
      $bfr .= $line;
    }
    else {
      
        $line =~ s/^\s+|\s+$//g;
	$bfr .= $line;
	if ($bfr eq "") {next}
	return $bfr;
    }
  }
  return ;
  
}

sub getObjClass {my $obj = shift;return $obj->[$ELM_CLASS];}
sub getObjType {my $obj = shift;return $obj->[$ELM_TYPE];}
sub getObjName {my $obj = shift;return $obj->[$ELM_NAME];}

sub getAllSimpleAttrNames {

 my $obj = shift;
 
 my $names;
   if (validateObject($obj, "getAllSimpleAttrNames", $CLS_GROUP)) {
      foreach my $x (@{$obj->[$ELM_MEMBERS]})  {
      	#print "NAME $x->[$ELM_CLASS] $x->[$ELM_TYPE] $x->[$ELM_NAME] $x->[$ELM_VALUE]\n";
        if($x->[$ELM_CLASS] eq $CLS_SIMPLEATTR) {push @$names, $x->[$ELM_NAME]}
      }
   }
 return $names;
}


sub getSimpleAttrValue {
  my $obj = shift;
  my $attrName = shift;
  
   if (validateObject($obj, "getSimpleAttrValue $attrName", $CLS_GROUP)) {
     foreach my $x (@{$obj->[$ELM_MEMBERS]})  {
       if ($x->[$ELM_CLASS] eq $CLS_SIMPLEATTR) {
         if ($x->[$ELM_NAME] eq $attrName) {
	  return $x->[$ELM_VALUE]
	 }
       } elsif($x->[$ELM_CLASS] eq $CLS_GROUP) {
       	 if($x->[$ELM_TYPE] eq  $attrName) {

	   return $x->[$ELM_NAME];
	 }
       }
     }
   }
  return ;
}


sub getAllComplexAttrNames {

 my $obj = shift;
 
 my $names;
      foreach my $x (@{$obj->[$ELM_MEMBERS]})  {
	if($x->[$ELM_CLASS] eq $CLS_GROUP) {push @$names , $x->[$ELM_TYPE]}
      }
 return $names;
}


sub getComplexAttrValue {
  my $obj = shift;
  my $attrName = shift;
     foreach my $x (@{$obj->[$ELM_MEMBERS]})  {
	if($x->[$ELM_CLASS] eq $CLS_GROUP) {
       	 if($x->[$ELM_TYPE] eq  $attrName) {

	   return $x->[$ELM_NAME];
	 }
       }
     }
  return ;
}



sub SortArcType{

my $obj = shift;
 
my $names;
my @idx;
my $i = 0;
my $len = scalar(@{$obj});
      foreach my $x (@{$obj->[$ELM_MEMBERS]})  {
     if ($x->[$ELM_CLASS] eq $CLS_GROUP) {
       push @$names,$x;
       push @idx, $i;
     } 
     $i++;
}

if (( scalar(@idx) > 1 ) and ( scalar(@idx) < 3  )) {
if (($obj->[$ELM_MEMBERS]->[-2]->[$ELM_TYPE] cmp $obj->[$ELM_MEMBERS]->[-1]->[$ELM_TYPE]) eq 1) {
my $temp = $obj->[$ELM_MEMBERS]->[-2];
$obj->[$ELM_MEMBERS]->[-2] = $obj->[$ELM_MEMBERS]->[-1];
$obj->[$ELM_MEMBERS]->[-1] = $temp;
}
} elsif ( scalar(@idx) > 3 ) {
	my $len = scalar(@idx);
	for(my $i=0;$i<$len-1;$i++) {
			
			for(my $j=0 ; $j< $len-$i-1;$j++) {
			my $num1 = $idx[$j];
			my $num2 = $idx[$j+1];
			if(($obj->[$ELM_MEMBERS]->[$num1]->[$ELM_TYPE] cmp $obj->[$ELM_MEMBERS]->[$num2]->[$ELM_TYPE]) eq 1) {
				my $temp = $obj->[$ELM_MEMBERS]->[$num2];
				$obj->[$ELM_MEMBERS]->[$num2] = $obj->[$ELM_MEMBERS]->[$num1];
				$obj->[$ELM_MEMBERS]->[$num1] = $temp;

			}
			}
	}
}
}



 
sub validateObject {
  
    my ($obj, $id, $class, $type, $name) = @_;
    my $status = 1;
    if ((defined $class) && ($obj->[$ELM_CLASS] ne $class)) {
      error_msg("Expected class $class, got $obj->[$ELM_CLASS] in $id");
      $status = 0;
    }
    
    if ((defined $type) && ($obj->[$ELM_TYPE] ne $type)) {
      error_msg("Expected type $type, got $obj->[$ELM_TYPE] in $id");
      $status = 0;
    }

    if ((defined $name) && ($obj->[$ELM_NAME] ne $name)) {
      error_msg("Expected name $name, got $obj->[$ELM_NAME] in $id");
      $status = 0;
    }
 
   return $status;
}

sub unquote {
  my $x = shift;
  my $q;
  
  if (!(defined $x)) {return ""}
  $q = ($x =~ s/^\s*"(.*)"\s*$/$1/g);
  my $quoted = ($q) ? 1: 0;
  return ($x, $quoted);

}

sub findAllGroups {

  my $obj = shift;
  my $type = shift;
  my $name = shift;
  
  my $matches = [];
  if (($obj->[$ELM_CLASS] eq $CLS_FILE) || ($obj->[$ELM_CLASS] eq $CLS_GROUP)) {
      
      foreach my $x (@{$obj->[$ELM_MEMBERS]}) {
         if ($x->[$ELM_CLASS] ne $CLS_GROUP) {next}
	 if ((defined $type) && ($x->[$ELM_TYPE] ne $type)) {next}
	 if ((defined $name) && ($x->[$ELM_NAME] ne $name)) {next}
         
	 push @$matches, $x;
      }
  } else {
     error_msg("Not correct object class for finding groups \"$obj->[$ELM_CLASS]\"");
  }
  return $matches;
}


sub error_msg {
  my ($message)= (@_);
  $message= '' if (not defined($message));
  
  my $whatiam="Error";
  my $whomydad=(caller(1))[3];
  
  if (not defined($whomydad)) {
    $whomydad=(caller(0))[1];
  }
  else {
    $whomydad=~s/main\:\://;  
  }
 print "$whatiam:$whomydad: $message\n";
}


sub processBusNotation {

 my $grp = shift;
 
 my $value = $grp->[$ELM_NAME];
 if (!(defined $value)) {return}
 if ($value =~ /(\w+)([\[<])(\d+)([\]>])/) {
   
    $grp->[$ELM_ROOTNAME] = $1;
    $grp->[$ELM_BIT] = $3;
    defFlag($grp, $FLG_ISBUS, 1);
    if ($2 eq "<") {
      defFlag($grp, $FLG_BUSPOINTY, 1);
    }
    else {
      defFlag($grp, $FLG_BUSSQUARE, 1);
      $grp->[$ELM_NAME] =~ tr/[]/<>/;
    }
 }
 else {
   $grp->[$ELM_ROOTNAME] = $value;
   $grp->[$ELM_BIT] = undef;
 }
}


sub sortArcsExec {

   my $pin = shift;
   my @arcList;
   my @rarcList;
   my @idx;
   my @ridx;
   my $i = 0;;
   my $j = 0;
   my @temph;
   foreach my $obj (@{$pin->[$ELM_MEMBERS]}) {

     
     if (($obj->[$ELM_CLASS] eq $CLS_GROUP) && ($obj->[$ELM_TYPE] eq "timing")) {
       push @arcList, $obj;
       push @idx, $i;
     } 
     $i++;
   }
   if (@arcList == 0) {return}
   my %nh;
   my $arc;
   my %ncc;
   my @Cnames;
   my $nv;
   foreach my $arc (@arcList) {

     my $nl = getAllSimpleAttrNames($arc);
 
     foreach my $n (@$nl) {;$nh{$n} = 1;}
     
   }
   my @names = sort keys %nh;
   my $attrName;
   my $attrValue;
   foreach my $arc (sort @arcList) {
	$arc->[$ELM_TEMP0] = [];
	$arc->[$ELM_TEMP1] = [];
       foreach my $attrName (@names) {
         $attrValue = getSimpleAttrValue($arc, $attrName);
	 if (!(defined $attrValue)) {$attrValue = ""};
	 push @{$arc->[$ELM_TEMP0]}, $attrValue;
       }
       # Added to sort Arc type in alphabetical order
       SortArcType($arc); 
        my $nc = getAllComplexAttrNames($arc);
       foreach my $attrName (@$nc) {
         my $attrValue = getComplexAttrValue($arc, $attrName);
	 if (!(defined $attrValue)) {$attrValue = ""};
	 push @{$arc->[$ELM_TEMP1]}, $attrName;
       }  
   } 
   my @arcListSortedd = sort SortArc @arcList; # Added to sort the arc types
   my @arcListSorted = sort arcAttrSort @arcListSortedd ;
   foreach my $arc (@arcListSorted) {
      $i = shift @idx;
      $pin->[$ELM_MEMBERS]->[$i] = undef;
      $pin->[$ELM_MEMBERS]->[$i] = $arc;
   }

   $arc->[$ELM_TEMP0] = undef;
   $arc->[$ELM_TEMP1] = undef;
}




sub arcAttrSort {
  
   my $i = 0;
   my $n = @{$a->[$ELM_TEMP0]};
   for ($i=0; ($i<$n); $i++) {
     #print "** $a->[$ELM_TEMP0]->[$i] ne $b->[$ELM_TEMP0]->[$i]\n";
     if (($a->[$ELM_TEMP0]->[$i] =~ m/\/\*/) and  ($b->[$ELM_TEMP0]->[$i] =~ m/\/\*/)) { next;}
     if ($a->[$ELM_TEMP0]->[$i] ne $b->[$ELM_TEMP0]->[$i]) {return ($a->[$ELM_TEMP0]->[$i] cmp $b->[$ELM_TEMP0]->[$i])}
   }
   return 0;
}

sub SortArc {
  
   my $i = 0;
   my $n = @{$a->[$ELM_TEMP1]};
   #print "** $a->[$ELM_TEMP0]->[0] ne $b->[$ELM_TEMP0]->[0]\n";
     if ($a->[$ELM_TEMP1]->[0] ne $b->[$ELM_TEMP1]->[0]) {return ($a->[$ELM_TEMP1]->[0] cmp $b->[$ELM_TEMP1]->[0])}
   return 0;
}


sub sortArcs {
  my $obj = shift;
  #my $reflib = shift;
  my @pinList = getPinlist($obj);
  #my @refpins = getPinlist($reflib);
  my $i =0;
  foreach my $pin (@pinList) {
    sortArcsExec($pin);
  }
}


sub setFilePath($$) {


    my $obj = shift;
	my $path = shift;
    if (validateObject($obj, "setFilePath", $CLS_FILE)) {
       my $currentPath = $obj->[$ELM_NAME];
       my @t = split(/\//, $currentPath);
       my $rootName = pop @t;
       $path = Cwd::abs_path($path);
       if (!(-d $path)) {mkdir $path}
       my $newPath = "$path/$rootName";
       $obj->[$ELM_NAME] = $newPath;
    }
    else {
      error_msg("Expected class FILE, got $obj->[$ELM_CLASS]\n");
    }
}


sub getName {
  
  my $obj = shift;
  return $obj->[$ELM_NAME];
}

sub defFlag {
  my ($obj, $mask, $value) = @_;
  if ($value) {$obj->[$ELM_FLAGS] |= $mask} else {$obj->[$ELM_FLAGS] &= ~$mask}

}


sub getPinlist {
  my $obj = shift;
  my $noBusPins = shift;
  my @fileList;
  my @libList;
  my @cellList;
  my @busList;
  my @pinList;

  if ($obj->[$ELM_CLASS] eq $CLS_FILE) {
  
   push @fileList, $obj;
  }
  elsif (($obj->[$ELM_CLASS] eq $CLS_GROUP) && ($obj->[$ELM_TYPE] eq "library")) {
   
    push @libList, $obj;
  }
  elsif (($obj->[$ELM_CLASS] eq $CLS_GROUP) && ($obj->[$ELM_TYPE] eq "cell")) {
   
    push @cellList, $obj;
  }
  elsif (($obj->[$ELM_CLASS] eq $CLS_GROUP) && ($obj->[$ELM_TYPE] eq "pin")) {
   
    push @pinList, $obj;
  }
  elsif (($obj->[$ELM_CLASS] eq $CLS_GROUP) && ($obj->[$ELM_TYPE] eq "pg_pin")) {
   
    push @pinList, $obj;
  }
  elsif (($obj->[$ELM_CLASS] eq $CLS_GROUP) && ($obj->[$ELM_TYPE] eq "bus")) {
   
    push @busList, $obj;
  }
  else {
    error_msg("Expected FILE, GROUP/Library, Group/cell or Group/pin\n");
    return @pinList;
  }
  
  foreach my $file (@fileList) {
    my $fileLibList = findAllGroups($file, "library");
    push @libList, @$fileLibList;
  }
  foreach my $lib (@libList) {
    my $libCellList = findAllGroups($lib, "cell");
    push @cellList, @$libCellList;
  }
  foreach my $cell (@cellList) {
    my $cellPinList = findAllGroups($cell, "pin");
    #$cellPinList->[$ELM_PARENT] = $obj;
    push @pinList, @$cellPinList;
    
      if (!$noBusPins) {
        my $cellBusList = findAllGroups($cell, "bus");   
	push @busList, @$cellBusList; 
      }
  }
  foreach my $bus (@busList) {
    my $busPinList = findAllGroups($bus, "pin"); 
    push @pinList, @$busPinList;
  }

return @pinList;
}
sub sortPins {
    ## Sorts pins and buses.
    my $obj = shift;  ## Can be a FILE, library, cell or bus.

    my @cellList;
    if ($obj->[$ELM_CLASS] eq $CLS_FILE) {
	my $libList = findAllGroups($obj, "library");
	foreach my $lib (@$libList) {
	    my $libCellList = findAllGroups($lib, "cell");
	    push @cellList, @$libCellList;
	}
    }
    elsif (($obj->[$ELM_CLASS] eq $CLS_GROUP) && ($obj->[$ELM_TYPE] eq "library")) {
	my $libCellList = findAllGroups($obj, "cell");
	push @cellList, @$libCellList;
    }
    elsif (($obj->[$ELM_CLASS] eq $CLS_GROUP) && ($obj->[$ELM_TYPE] eq "cell")) {
	push @cellList, $obj
    }
    elsif (($obj->[$ELM_CLASS] eq $CLS_GROUP) && ($obj->[$ELM_TYPE] eq "bus")) {
	push @cellList, $obj; ## technically not a cell, but works out that way.
    }
    else {
	error_msg("Expected FILE, GROUP/library, GROUP/cell or GROUP/bus\n");
	return;
    }

    foreach my $cell (@cellList) {
	sortPinsExec($cell);
    }
}

sub sortPinsExec {
    ##  Sorts pins witnin a cell or bus group.
    my $obj = shift;

    my $isBus = ($obj->[$ELM_TYPE] eq "bus");

    my @pg_pins;
    my @pins;
    my @buses;
    my @idx;
    my $i = 0;
    ##  Build lists of pg_pins, buses and pins, and an array of indices for these so sorted lists can be put back in the same locations.
    foreach my $x (@{$obj->[$ELM_MEMBERS]}) {
	unless(defined $x->[$ELM_TYPE]) {$i++; next;}
	if ($x->[$ELM_TYPE] eq "pg_pin") {
	    push @pg_pins, $x;
	    push @idx, $i;
	}
	elsif ($x->[$ELM_TYPE] eq "bus") {
	    sortPinsExec($x);  ##  Sort the bus pins
	    push @buses, $x;
	    push @idx, $i;
	}
	elsif ($x->[$ELM_TYPE] eq "pin") {
	    push @pins, $x;
	    push @idx, $i;
	}
	$i++;
    }
    my $npg = @pg_pins;
    my $nb = @buses;
    my $np = @pins;

    my @pg_pins_sorted = sort {$a->[$ELM_NAME] cmp $b->[$ELM_NAME]} @pg_pins;
    my @buses_sorted = sort {$a->[$ELM_NAME] cmp $b->[$ELM_NAME]} @buses;
#    processBusPins(\@pins);   ##  Decompose pin names for simpler sorting
    my @pins_sorted = sort pinNameSort @pins;


    ##  Put back in members array in sorted order.
    my $j;
#    print "{@idx}\n";
    foreach my $pg_pin (@pg_pins_sorted) {
	$j = shift @idx;
	$obj->[$ELM_MEMBERS]->[$j] = $pg_pin;
    }
    foreach my $bus (@buses_sorted) {
	$j = shift @idx;
	$obj->[$ELM_MEMBERS]->[$j] = $bus;
    }
    foreach my $pin (@pins_sorted) {
	$j = shift @idx;
	$obj->[$ELM_MEMBERS]->[$j] = $pin;
#	print "!!! $pin->[$ELM_NAME] in $j\n";
    }
}
sub pinNameSort {
    ##  Sort function for pins.
    ##  Sort first alphabetically by root name.
    #   If rootname is the same, use bit indices numerically

    if ($a->[$ELM_ROOTNAME] ne $b->[$ELM_ROOTNAME]) {$a->[$ELM_ROOTNAME] cmp $b->[$ELM_ROOTNAME]} else {$b->[$ELM_BIT] <=> $a->[$ELM_BIT]}

}

##ME
1;
