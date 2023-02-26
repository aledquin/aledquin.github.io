#!/depot/perl-5.14.2/bin/perl
use strict;
use warnings;
use Pod::Usage;
use Data::Dumper;
use File::Copy;
use Getopt::Std;
use Getopt::Long;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Cwd     qw( abs_path );
use Carp    qw( cluck confess croak );
use FindBin qw( $RealBin $RealScript );

use  Exporter qw(import);
use Text::ParseWords;



use lib "$RealBin/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging    qw(iprint eprint);

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


utils__script_usage_statistics( $PROGRAM_NAME, $VERSION);
#nolint open <
#nolint open >

package alphaLibParser;
 
our @EXPORT_OK = qw(readLib writeLib getAllSimpleAttrNames getSimpleAttrValue validateObject getGroup findAllGroups sortPins sortArcs setFilePath error_msg getName getPinList getCellList deleteGroup setSimpleAttr delSimpleAttr copyGroup);

##  Note:  Using lists w/ symbolic field names rather than hashes for speed.

##  Element record field definitions
our $ELM_CLASS = 0;   ##  Classes are FILE, GROUP, or ATTR
our $ELM_TYPE = 1;    ##  Group or attribute type
our $ELM_NAME = 2;
our $ELM_VALUE = 3;
our $ELM_MEMBERS = 4;
our $ELM_ROOTNAME = 5;  ##  Root name
our $ELM_BIT = 6;       ##  ... and bit.  Used for sorting by name and bit number
our $ELM_FLAGS = 7;    ## General purpose flags
our $ELM_TEMP0 = 8;   ##  A spot used for whatever temporary use
our $ELM_PARENT = 9;   ##  Parent object
our $ELM_COMMENT = 10;   ##  commented lines

##  CLASS definitions
our $CLS_FILE = "file";  ##  File class is for a given liberty file.  Should contain one (or more?) library group
our $CLS_GROUP = "group";  ##  General group object
our $CLS_SIMPLEATTR = "simpleattr";   ##  Simple attribute "attrName : attrValue ;"
our $CLS_COMPLEXATTR = "complexattr";   ##  Complex attribute:  "attrName(val1,val2,...) ;


##  Flag masks
our $FLG_VALQUOTED = 0x01;   ##  Value was originally quoted, so quote when writing libs. 
our $FLG_NAMEQUOTED = 0x02;   ##  Name was originally quoted, so quote when writing libs. 
our $FLG_VALTOUCHED = 0x04;   ##  Value has been touched.
our $FLG_ISBUS = 0x08;   ##  Value has a bus format.
our $FLG_BUSSQUARE = 0x10;   ##  Bus notation uses [] brackets
our $FLG_BUSPOINTY = 0x20;   ##  Bus notation uses <> brackets

sub objIsBus {
    my $obj = shift;
    return ($obj->[$ELM_FLAGS] & $FLG_ISBUS);
}


sub copyObject {
    ##  Creates a new object, copying all fields from the one provided.

    my $srcObj = shift;
    my $srcRef = ref $srcObj;

    if ($srcRef eq "") {return $srcObj}  ##  A simple scalar.

    ## The presence of the parent field prevents simple-minded copies; have to be object-aware.
    my $dstObj = createObject($srcObj->[$ELM_CLASS], $srcObj->[$ELM_TYPE], $srcObj->[$ELM_NAME], $srcObj->[$ELM_VALUE], undef);
    ##  Copy the other scalar fields.
    foreach my $scalarField ($ELM_ROOTNAME, $ELM_BIT, $ELM_FLAGS, $ELM_TEMP0) {
	$dstObj->[$scalarField] = $srcObj->[$scalarField];
    }
    foreach my $mbr (@{$srcObj->[$ELM_MEMBERS]}) { push @{$dstObj->[$ELM_MEMBERS]}, copyObject($mbr) }
    return $dstObj;
}

sub copyObjectOld {
    ##  Creates a new object, copying all fields from the one provided.
    ##  Generic, built to handle scalars, arrays and hashes.

    my $srcObj = shift;
    
    my $srcType = ref $srcObj;

    if ($srcType eq "") {
	return $srcObj;  ## Scalar
    }

    if ($srcType eq "ARRAY") {
	my $dstObj = [];
	foreach my $x (@$srcObj) {push @$dstObj, copyObject($x)}
	return $dstObj;
    }

    if ($srcType eq "HASH") {
	my $dstObj = {};
	foreach my $x (keys %$srcObj) {$dstObj->{$x} = copyObject($srcObj->{$x})}
	return $dstObj;
    }

    error_msg("Unhandled reference type \"$srcType\" in copyObject\n");
    return;
}

sub createGroup {
    my ($type, $name, $parent) = @_;

    my $grp = createObject($CLS_GROUP, $type, $name, undef, $parent);
    return $grp;

}

sub createObject {
    ##  Generic object creation

    my ($class, $type, $name, $value, $parent) = @_;

#    print "Creating {$class} {$type} {$name} {$value}\n";
    my $obj = [];
    $obj->[$ELM_CLASS] = $class;
    $obj->[$ELM_TYPE] = $type;
    ##  Need to keep track of when a value was quoted originally.
    my ($valueUnquoted, $nameUnquoted, $valIsQuoted, $nameIsQuoted);
    if ($class eq $CLS_COMPLEXATTR) {
	##  For complex attributes, need some more sophisticated quote handling.
	##  For now, just carry quotes along.
	$nameIsQuoted = 0;
	$valIsQuoted = 0;
    }
    elsif ($class eq $CLS_SIMPLEATTR) {
	($value, $valIsQuoted) = unquote($value);
	$nameIsQuoted = 0;
    }
    elsif ($class eq $CLS_GROUP) {
	##  Name may be quoted. No value.
	($name, $nameIsQuoted) = unquote($name);
	$valIsQuoted = 0;
    }

#    print "createObject:  name={$name} quoted=$nameIsQuoted, value={$value} quoted=$valIsQuoted\n";
    $obj->[$ELM_NAME] = $name;
    $obj->[$ELM_VALUE] = $value;
    $obj->[$ELM_MEMBERS] = [];
    $obj->[$ELM_ROOTNAME] = undef;
    $obj->[$ELM_BIT] = undef;
    $obj->[$ELM_FLAGS] = 0x00000000;
    $obj->[$ELM_TEMP0] = undef;
    $obj->[$ELM_PARENT] = $parent;
 
    defFlag($obj, $FLG_VALQUOTED, $valIsQuoted);
    defFlag($obj, $FLG_NAMEQUOTED, $nameIsQuoted);

    processBusNotation($obj);   ##  Check for bus notation on value and decompose.
#ekta   print "obj->[$ELM_NAME] 	= $obj->[$ELM_NAME]    \n";
#ekta   print "obj->[$ELM_VALUE] 	= $obj->[$ELM_VALUE]   \n";
#ekta   print "obj->[$ELM_MEMBERS]	= $obj->[$ELM_MEMBERS] \n";
#ekta   print "obj->[$ELM_ROOTNAME]	= $obj->[$ELM_ROOTNAME]\n";
#ekta   print "obj->[$ELM_BIT] 	= $obj->[$ELM_BIT]     \n";
#ekta   print "obj->[$ELM_FLAGS] 	= $obj->[$ELM_FLAGS]   \n";
#ekta   print "obj->[$ELM_TEMP0]	= $obj->[$ELM_TEMP0]   \n";
#ekta   print "obj->[$ELM_PARENT] 	= $obj->[$ELM_PARENT]  \n";

    return $obj;
}

sub readLib {
    my $lib = shift;
#    use constant STATE_0 => 0;     ##  Initial lib read state.

    ##  The root of the lib
    $lib = Cwd::abs_path($lib);
    my $root = createObject($CLS_FILE, undef, $lib, undef, undef);
    
    Util::Messaging::iprint("Reading $lib\n");
    if (!(-r $lib)) {error_msg("Cannot open $lib for read\n"); return}

    open(my $LIB,"<","$lib");    #nolint open <
    my $line;
    my @context;
    my $current = $root;
    while ($line = readLine(*$LIB)) {
	##  Reads the next non-blank line.  Continued lines are handled, returned as a single string
	if ($line eq "}") {
	    ##  Group end.
	    $current = pop @context;
	}
	elsif ($line =~ /^(\S+)\s*\(\s*(\S*)\s*\)\s*{$/) {
	    ##  Group begin.
	    my $rec = createObject($CLS_GROUP, $1, $2, undef, $current);
	    #ekta   print "$line:$rec =createObject($CLS_GROUP, $1, $2, undef, $current)\n";
	    push @{$current->[$ELM_MEMBERS]}, $rec;
	    push @context, $current;
	    #ekta   print "changed:$current = $rec;\n";
	    $current = $rec;
	}
	elsif ($line =~ /^(\S+)\s+:\s+(.*)\s*;$/) {
	    ##  Attribute statement
	    my $attrName = $1;
	    my $attrValue =  $2;
	    $attrValue =~ s/^\s+|\s+$//g;    ##  Need to trim leading/trailing whitespace.
	    my $rec = createObject($CLS_SIMPLEATTR, undef, $attrName, $attrValue, $current);
	    #ekta   print "$line:$rec = createObject($CLS_SIMPLEATTR, undef, $attrName, $attrValue, $current);\n";
	    push @{$current->[$ELM_MEMBERS]}, $rec;
	}
	elsif ($line =~ /^(\S+)\s*\(\s*(.*)\s*\)\s*;$/s) {
	    ##  Complex attribure. Form:  name (value);
	    my $rec = createObject($CLS_COMPLEXATTR, undef, $1, $2, $current);
	   #ekta   print "$line:$rec = createObject($CLS_COMPLEXATTR, undef, $1, $2, $current)\n";
	    parseComplexAttrValue($rec); 
	    push @{$current->[$ELM_MEMBERS]}, $rec;
	}
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

#    print Dumper($root);
#    dumpGroup($root, "");
    return $root;
    
}

sub addPin {
my ($cell,$PinName)=@_;
my  $new_pin = alphaLibParser::createObject($CLS_GROUP, "pin", $PinName, undef, $cell);
push @{$cell->[$ELM_MEMBERS]}, $new_pin;
}

sub AddPgpin {
my ($libFile,$toks)=@_;
    my $pin = shift @$toks;
    $pin = '"'.$pin.'"';
    my @values =  @$toks;
    my @cellList = getCellList($libFile);
    foreach my $cell (@cellList) {
    	foreach my $mem (@{$cell->[$ELM_MEMBERS]}) {
		if(($mem->[$ELM_CLASS] eq $CLS_GROUP) &&  $pin =~ /\b$mem->[$ELM_NAME]\b/ && $mem->[$ELM_TYPE] eq "pg_pin"){print "Info: $mem->[$ELM_TYPE] $pin already exist\n"; return;}
	}
	
	my  $new_pin = createObject($CLS_GROUP, "pg_pin", $pin, undef, $cell);
	    push @{$cell->[$ELM_MEMBERS]}, $new_pin;
my  $obj;
 if($values[0] =~/power|pwr/i) {
	  $obj = createObject($CLS_SIMPLEATTR, undef, "pg_type", "primary_power", $new_pin);
	} else {
	  $obj = createObject($CLS_SIMPLEATTR, undef, "pg_type", "primary_ground", $new_pin);
	}
	    push @{$new_pin->[$ELM_MEMBERS]}, $obj;
	 $obj = createObject($CLS_SIMPLEATTR, undef, "voltage_name", "$pin", $new_pin);
	    push @{$new_pin->[$ELM_MEMBERS]}, $obj;
	
}
}
sub DelPgpin {
my ($libFile,$toks)=@_;
    my $pin = shift @$toks;
    my @cellList = getCellList($libFile);
    my $libList = findAllGroups($libFile, "library");
	my $i = 0;
    foreach my $cell (@cellList) {
	foreach my $mem (@{$cell->[$ELM_MEMBERS]}) {
	if(($mem->[$ELM_NAME] eq  $pin) && ($mem->[$ELM_TYPE] eq  "pg_pin")) { 
	splice(@{$cell->[$ELM_MEMBERS]}, $i, 1);  ## Removes element $i;
	 last;}
	$i++;
	}
	}
	}



sub AddVmapPin {
my ($libFile,$toks)=@_;
    my $pin = shift @$toks;
    my $supply = shift @$toks;
    my $volt;
    if ($supply =~ /PWR|power/) { $volt = shift @$toks;} else {  $volt = "0.000";}
    my @cellList = getCellList($libFile);
    my $libList = findAllGroups($libFile, "library");
        my $new = @$libList[0];
	foreach my $mem (@{$new->[$ELM_MEMBERS]}) {
	if($mem->[$ELM_ROOTNAME] eq  "voltage_map" && $mem->[$ELM_VALUE] =~ /\b$pin\b/ ){print "Info: $mem->[$ELM_ROOTNAME] $mem->[$ELM_VALUE] for $pin already exist\n"; return;}
	}
	
	
	

	my  $new_pin = createObject($CLS_COMPLEXATTR, undef, "voltage_map", "\"$pin\",$volt", $libList);
	my $i = 0;
	foreach my $mem (@{$new->[$ELM_MEMBERS]}) {
	if($mem->[$ELM_ROOTNAME] eq  "voltage_map") {    splice(@{$new->[$ELM_MEMBERS]},$i,0,$new_pin); last;}
	elsif($mem->[$ELM_NAME] eq  $cellList[0]->[$ELM_NAME]) {    splice(@{$new->[$ELM_MEMBERS]},$i,0,$new_pin); last;}
	$i++;
	}

}
sub CopyLu_table {
my ($libFilesrc,$libFile,$group,$patt)=@_;
    my @cellList = getCellList($libFile);
    my $libListsrc = findAllGroups($libFilesrc, "library");
    my $libList = findAllGroups($libFile, "library");
    my @group;
    my @group_dst;
       my $new = @$libListsrc[0];
	foreach my $mem (@{$new->[$ELM_MEMBERS]}) {
	if(defined $mem->[$ELM_TYPE] && $mem->[$ELM_TYPE] eq  $group && $mem->[$ELM_ROOTNAME] =~ /$patt/i )  {push(@group,$mem); }
	}

        $new = @$libList[0];
	foreach my $mem (@{$new->[$ELM_MEMBERS]}) {
	if(defined $mem->[$ELM_TYPE] && $mem->[$ELM_TYPE] eq  $group)  {push(@group_dst,$mem); }
	}
	
	foreach my $mem (@group_dst) {
	my $i = 0;
	foreach my $mem_dst (@group) { if($mem->[$ELM_ROOTNAME] eq $mem_dst->[$ELM_ROOTNAME]){splice(@group,$i,1);}
	$i++;
	}
	}
	
	
	my $i = 0;
	foreach my $mem (@{$new->[$ELM_MEMBERS]}) {
	if(defined $mem->[$ELM_TYPE] && $mem->[$ELM_TYPE] eq  $group)  {splice(@{$new->[$ELM_MEMBERS]},$i,0,@group);return; }
	$i++;
	}

}
	
	
sub DelVmapPin {
my ($libFile,$toks)=@_;
    my $pin = shift @$toks;
    my @cellList = getCellList($libFile);
    my $libList = findAllGroups($libFile, "library");
	my $i = 0;
	my $new = @$libList[0];
	foreach my $mem (@{$new->[$ELM_MEMBERS]}) {
	if(($mem->[$ELM_ROOTNAME] eq  "voltage_map") && ($mem->[$ELM_VALUE] =~  /\"$pin\"/)) { 
	splice(@{$new->[$ELM_MEMBERS]}, $i, 1);  ## Removes element $i;
	 last;}
	$i++;
	}

}



sub update_operating_cond {
my ($parent,$process,$corner_type,$voltage,$temp)=@_;
	my $temperature = $temp;
	$temperature =~ s/n/-/g;
	my $i = 0; my $match = 0;
	foreach my $mem (@{$parent->[$ELM_MEMBERS]}) {
	if(($mem->[$ELM_CLASS] eq $CLS_GROUP) && $mem->[$ELM_TYPE] eq  "operating_conditions"){
		renameClsGRP_name($mem,$mem->[$ELM_NAME],"$corner_type"."0p$voltage"."v$temp"."c");
		foreach my $child (@{$mem->[$ELM_MEMBERS]}) {
		if(($child->[$ELM_ROOTNAME] eq  "process") && ($process ne "none")){$child->[$ELM_VALUE]=sprintf("%f",$process) ;}
		if(($child->[$ELM_ROOTNAME] eq  "voltage") && ($voltage ne "none"))  {$child->[$ELM_VALUE]=sprintf("%f","0.$voltage") ;}
		if(($child->[$ELM_ROOTNAME] eq  "temperature") && ($temperature ne "none")) {$child->[$ELM_VALUE]=sprintf("%f",$temperature) ;}
		}
	
	
	$match = 1;last;}
	$i++;
	}
	 unless($match) { print "Error operating_conditions not found in lib file\n";	}
}

sub AddLibrary_attrib {
my ($parent,$line)=@_;
	if ($line =~ /^(\S+)\s*:\s*(.*)\s*$/) {
	    my $attrName = $1;
	    my $attrValue =  $2;
	    $attrValue =~ s/^\s+|\s+$//g;
	    my $rec = createObject($CLS_SIMPLEATTR, undef, $attrName, $attrValue, $parent);
	my $i = 0; my $matched = 0;
	foreach my $mem (@{$parent->[$ELM_MEMBERS]}) {
	if($mem->[$ELM_ROOTNAME] eq  $attrName) {$mem->[$ELM_VALUE] = $attrValue;$matched = 1;}
	$i++;
	}
	unless($matched) {
	$i = 0;
	foreach my $mem (@{$parent->[$ELM_MEMBERS]}) {
	if($mem->[$ELM_CLASS] eq  $CLS_SIMPLEATTR) {splice(@{$parent->[$ELM_MEMBERS]},$i,0,$rec); last;}
	$i++;
	}
	}
	}
	elsif ($line =~ /^(\S+)\s*\(\s*(.*)\s*\)\s*$/s) {
	    my $attrName = $1;
	    my $attrValue =  $2;
	    my $rec = createObject($CLS_COMPLEXATTR, undef, $attrName, $attrValue, $parent);
	    parseComplexAttrValue($rec); 
	my $i = 0;
	foreach my $mem (@{$parent->[$ELM_MEMBERS]}) {
	if(($mem->[$ELM_CLASS] eq $CLS_GROUP) && ($mem->[$ELM_TYPE] eq  "$attrName")&&($mem->[$ELM_VALUE] eq  "$attrValue")) {last;}
	 elsif($mem->[$ELM_ROOTNAME] eq  "$attrName") {splice(@{$parent->[$ELM_MEMBERS]},$i,0,$rec); last;}
	$i++;
	}
	}
	
	elsif ($line =~ /^(\S+)\s*\(\s*(\S*)\s*\)\s*{$/) {
	    my $attrName = $1;
	    my $attrValue =  $2;
	my $i = 0;
	 if(($parent->[$ELM_CLASS] eq $CLS_GROUP) && ($parent->[$ELM_TYPE] eq  "$attrName")) {renameClsGRP_name($parent,$parent->[$ELM_NAME],$attrValue); }
	
	foreach my $mem (@{$parent->[$ELM_MEMBERS]}) {
	if(($mem->[$ELM_CLASS] eq $CLS_GROUP) && ($mem->[$ELM_TYPE] eq  "$attrName")) {renameClsGRP_name($mem,$mem->[$ELM_NAME],$attrValue); last;}
	$i++;
	}
	} else {
	    print STDERR "Unhandled line: \"$line\"\n";
	}
}
sub DelLibrary_attrib {
my ($parent,$toks)=@_;
my $line = shift @$toks;
$line .=";";
my $matched = 0;
	if ($line =~ /^(\S+)\s*:\s*(.*)\s*;$/) {
	    my $attrName = $1;
	    my $attrValue =  $2;
	    $attrValue =~ s/^\s+|\s+$//g;
	    my $rec = createObject($CLS_SIMPLEATTR, undef, $attrName, $attrValue, $parent);
	my $i = 0; 
	foreach my $mem (@{$parent->[$ELM_MEMBERS]}) {
	if($mem->[$ELM_ROOTNAME] eq  $attrName) {$mem->[$ELM_VALUE] = $attrValue;$matched = 1;splice(@{$parent->[$ELM_MEMBERS]},$i,1); last;}
	$i++;
	}
	}
	elsif ($line =~ /^(\S+)\s*\(\s*(.*)\s*\)\s*;$/s) {
	    my $rec = createObject($CLS_COMPLEXATTR, undef, $1, $2, $parent);
	    parseComplexAttrValue($rec); 
	my $i = 0;
	foreach my $mem (@{$parent->[$ELM_MEMBERS]}) {
	if(($mem->[$ELM_ROOTNAME] eq  "$1")&&($mem->[$ELM_VALUE] eq  "$2")) {$matched = 1;splice(@{$parent->[$ELM_MEMBERS]},$i,1); last;}
	$i++;
	}
	}
	else {
	    print STDERR "Unhandled line: \"$line\"\n";
	}

	unless($matched) {print "ERROR:$line not deleted\n";}
}
sub getbusList {
    ##  Builds pin list for file, library, cell or bus object
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
	push @cellList, $obj
    }
    elsif (($obj->[$ELM_CLASS] eq $CLS_GROUP) && ($obj->[$ELM_TYPE] eq "pin")) {
	push @pinList, $obj;
    }
    elsif (($obj->[$ELM_CLASS] eq $CLS_GROUP) && ($obj->[$ELM_TYPE] eq "bus")) {
	push @busList, $obj;
    }
    else {
	error_msg("Expected FILE, GROUP/library, GROUP/cell or GROUP/pin\n");
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
	push @pinList, @$cellPinList;

	##  Don't forget the pins under the buses...
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

sub updateBusDef{

my ($libFile,$pin)= @_;
my $libList = findAllGroups($libFile, "library");
my @cellList = getCellList($libFile);
my $msb ;
my $lsb ;
my $busWidth ;
my $busname ="";
my $obj = @$libList[0];
my $flag;

	foreach my $cell (@cellList) {
    	my @rawPinList = getPinList($cell, 0);
	my $match = "";
	foreach  my $cell (@cellList) {

	my @bit;
	foreach  my $group (findAllGroups($cell, "bus")) {
#		if((validateObject($MainBus, "getallSimpleAttrNames", $CLS_GROUP) && ($MainBus->[$ELM_NAME] =~ /$pin/)) {
		my $i = 0;
		foreach my $MainBus (@$group) {
		if($MainBus->[$ELM_NAME] eq $pin) {
			foreach  my $mem ($MainBus->[$ELM_MEMBERS]) {
			
				foreach  my $bus_pin (@$mem) {if($bus_pin->[$ELM_NAME] =~ /$pin<(.*)>/) {push(@bit,$1);}}
			}
			$busWidth = $#bit+1;
			if($busWidth == 0){removeMember($cell, $MainBus); return;}
			@bit = sort(@bit);
			$msb = $bit[-1];
			$lsb = $bit[0];
			
			$busname = "BUS${busWidth}_type$bit[0]";

		foreach my $mem (@{$MainBus->[$ELM_MEMBERS]}) {
			if($mem->[$ELM_NAME] eq "bus_type") {$mem->[$ELM_VALUE] = "$busname"; }
		}	
		} 

		
		$i++;
		}
		}
		}
	my $i = 0;
	my $flag = "";
next if ($busname eq "") ;
	foreach my $mem (@{$obj->[$ELM_MEMBERS]}) {
	if((defined $mem->[$ELM_NAME]) && ($mem->[$ELM_NAME] eq $busname)) { $flag = "matched";}
	elsif($mem->[$ELM_NAME] eq  $cellList[0]->[$ELM_NAME] && $flag ne "matched") {
		  my $new_bus = createObject($CLS_GROUP, "type", "$busname", undef,$libList);splice(@{$obj->[$ELM_MEMBERS]},$i,0,$new_bus); 
		  my  $obj = createObject($CLS_SIMPLEATTR, undef, "base_type", "array", $new_bus);push @{$new_bus->[$ELM_MEMBERS]}, $obj;
	    	  $obj = createObject($CLS_SIMPLEATTR, undef, "data_type", "bit", $new_bus);push @{$new_bus->[$ELM_MEMBERS]}, $obj;
	    	  $obj = createObject($CLS_SIMPLEATTR, undef, "bit_width",$busWidth , $new_bus);push @{$new_bus->[$ELM_MEMBERS]}, $obj;
		  $obj = createObject($CLS_SIMPLEATTR, undef, "bit_from", $msb, $new_bus);push @{$new_bus->[$ELM_MEMBERS]}, $obj;
		  $obj = createObject($CLS_SIMPLEATTR, undef, "bit_to", $lsb, $new_bus);push @{$new_bus->[$ELM_MEMBERS]}, $obj;
 		last;
		}
	$i++;
	}
	        
	

}
}
sub copyBusattrib {
my ($libFile, $src_pin, $dst_pin,$msb,$lsb)= @_;
	if($lsb > $msb) {($lsb, $msb) = ($msb, $lsb);}
	my $libList = findAllGroups($libFile, "library");
   	my @cellList = getCellList($libFile);
	my $busWidth = $msb-$lsb+1;
	my $busname = "BUS${busWidth}_type$lsb";
	my $i = 0; 
	my $obj = @$libList[0];
	my $flag = "";
	my $new_bus = "";
   	foreach my $cell (@cellList) {
    		my @rawPinList = getPinList($cell, 0);
		my $match = "";
		foreach  my $bus_pin (@rawPinList) {if($bus_pin->[$ELM_NAME] =~ /$dst_pin</) {$match = "exist"; $new_bus = $bus_pin->[$ELM_PARENT];last;}}
		if($match ne "exist") {
		$new_bus = createObject($CLS_GROUP, "bus", $dst_pin, undef, $cell);  push (@{$cell->[$ELM_MEMBERS]}, $new_bus);
  		foreach  my $bus_pin (@rawPinList) {if($bus_pin->[$ELM_NAME] =~ /$src_pin</) { 
		copySimpleAttr($bus_pin->[$ELM_PARENT],$new_bus);
		copyComplexAttr($bus_pin->[$ELM_PARENT],$new_bus);
		last;
		}
		}
		}

}
return $new_bus;
}
sub Addbus {
my ($libFile,$pin,$msb,$lsb, $attrlist)= @_;
   my @attrListParsed = @$attrlist;
	
#	print "$lsb to $msb\n";
	if($lsb > $msb) {($lsb, $msb) = ($msb, $lsb);}
	my $libList = findAllGroups($libFile, "library");
   	my @cellList = getCellList($libFile);
	my $busWidth = $msb-$lsb+1;
	my $busname = "BUS${busWidth}_type$lsb";
	my $i = 0; 
	my $obj = @$libList[0];
	my $flag = "";
	my $new_bus = "";
   	foreach my $cell (@cellList) {
    		my @rawPinList = getPinList($cell, 0);
		my $match = "";
	   	foreach  my $bus_pin (@rawPinList) {if($bus_pin->[$ELM_NAME] =~ /$pin</) {$match = "exist"; $new_bus = $bus_pin->[$ELM_PARENT];last;}}
		if($match ne "exist") {
		$new_bus = createObject($CLS_GROUP, "bus", $pin, undef, $cell);    push (@{$cell->[$ELM_MEMBERS]}, $new_bus); $new_bus->[$ELM_PARENT]=$cell;
		$obj = createObject($CLS_SIMPLEATTR, undef, "bus_type", "$busname", $new_bus);push @{$new_bus->[$ELM_MEMBERS]}, $obj; $obj->[$ELM_PARENT]=$new_bus;
		foreach my $attrRec (@attrListParsed) {
			next if($attrRec->[1] eq "none" || $attrRec->[1] eq "NONE") ;
			if($attrRec->[1] =~ /,/) {
				$attrRec->[1] =~  s/,/, /g;
				$attrRec->[1] =~  s/\"|  //g;
				setComplexAttr($new_bus, $attrRec->[0], $attrRec->[1]);
			} 
			#else {
	    		 	#setSimpleAttr($new_bus, $attrRec->[0], $attrRec->[1]);
			#	}
					
			}
    		}
		
	

		foreach($lsb..$msb) {

		my $match = "";
		foreach  my $bus_pin (@rawPinList) {
		if($bus_pin->[$ELM_NAME] eq "$pin<$_>") {$match = "exist"; $new_bus = $bus_pin->[$ELM_PARENT]; last;}
		} #################check_bus_exist
		if($match eq "exist") {next;}
		 my $new_pin = createObject($CLS_GROUP, "pin", "$pin\[$_\]", undef, $new_bus);
		    push (@{$new_bus->[$ELM_MEMBERS]}, $new_pin);

  		foreach my $attrRec (@attrListParsed) {
			next if($attrRec->[1] eq "none" || $attrRec->[1] eq "NONE") ;
			if($attrRec->[1] =~ /,/) {
				$attrRec->[1] =~  s/,/, /g;
				$attrRec->[1] =~  s/\"|  //g;
	    			setComplexAttr($new_pin, $attrRec->[0], $attrRec->[1]);
			} else {
	    		 	setSimpleAttr($new_pin, $attrRec->[0], $attrRec->[1]);
			
			}
			}

		}
	}
updateBusDef($libFile,"$pin");
}

sub create_New_object {
my ($group,$libFile,$type,$name)=@_;my $obj;
    my @cellList = getCellList($libFile);
    foreach my $cell (@cellList) {
	 $obj = createObject($group, $type, $name, undef, $cell);
	}
	return $obj;
}
sub getSimpleAttrList {
    my $grp = shift;
    my @attrList;

    if (validateObject($grp, "getSimpleAttrList", $CLS_GROUP)) {
	foreach my $mbr (@{$grp->[$ELM_MEMBERS]}) {
	    if ($mbr->[$ELM_CLASS] eq $CLS_SIMPLEATTR) {push @attrList, $mbr}
	}
    }
    return @attrList;
}

sub getComplexAttrList {
    my $grp = shift;
    my @attrList;

    if (validateObject($grp, "getComplexAttrList", $CLS_GROUP)) {
	foreach my $mbr (@{$grp->[$ELM_MEMBERS]}) {
	    if ($mbr->[$ELM_CLASS] eq $CLS_COMPLEXATTR) {push @attrList, $mbr}
	}
    }
    return @attrList;
}

sub parseComplexAttrValue {
    my $obj = shift;

    if (validateObject($obj, "parseComplexAttrValue", $CLS_COMPLEXATTR)) {
	my $attrVal = $obj->[$ELM_VALUE];
	$attrVal =~ s/\\\n//g;   ## Strip out continuations.
#	print "parseComplexAttr:  {$attrVal}\n";
	my @toks = Text::ParseWords::quotewords('\s*,\s*', 0, $attrVal);  ## Splits the value by comma, but obeying quotes.  The "0" removes the quotes.
#	foreach my $t (@toks) {print "\t$t\n"}
	#    my @toks = split(/,/, $attrVal);
	@{$obj->[$ELM_MEMBERS]} = @toks;  ##  Save attr values in the members array
    }
}

sub writeLib {
    my $obj = shift;
    my $fileName = shift;  ## Optional.  Writes to name defined in obj, assuming it's a FILE
 #   print "$fileName\n";
    my @dumpGroups;
    if ($obj->[$ELM_CLASS] eq $CLS_FILE) {
	##  File class.  if fileName is undefined, use name defined in object.
	if (!(defined $fileName)) {$fileName = $obj->[$ELM_NAME]}
	$fileName = Cwd::abs_path($fileName);
#	print Dumper($obj->[$ELM_MEMBERS]);
	@dumpGroups = @{$obj->[$ELM_MEMBERS]};
    }
    elsif (($obj->[$ELM_CLASS] eq $CLS_GROUP) && ($obj->[$ELM_TYPE] == "library")) {
	##  A single library object.  fileName must be defined.
	push @dumpGroups, $obj;
    }
    else {
	error_msg("Object is neither a file nor library group");
	return;
    }
    
    if (!(defined $fileName)) {
	error_msg("Undefined fileName\n");
	return;
    }

    print "Writing $fileName\n";

    my $n = @dumpGroups;
    if (open(my $OUT, ">", "$fileName")) {    #nolint open >
	foreach my $l (@dumpGroups) {
	    ##  Each member should be a library group.
	    if (($l->[$ELM_CLASS] eq $CLS_GROUP) && ($l->[$ELM_TYPE] eq "library")) {
		##  The expected library group
		dumpGroup(*$OUT, $l, "");
	    }
	}
	close $OUT;
    }
    else {
	error_msg("Cannot open $fileName for write");
	return;
    }
}

sub getFlag {
    my $obj = shift;
    my $mask =  shift;
  
    return ($obj->[$ELM_FLAGS] & $mask);
}

sub dumpGroup {
    my $fh = shift;
    my $group = shift;
    my $indent = shift;

    my $q = getFlag($group, $FLG_NAMEQUOTED) ? "\"" : "";
    my $name = $group->[$ELM_NAME];
    if (getFlag($group, $FLG_BUSSQUARE)) {$name =~ tr/<>/[]/}  ## Convert back to square brackets.
    print $fh "$indent$group->[$ELM_TYPE] ($q$name$q) {\n";
    my $newIndent = "  $indent";
    
    foreach my $mbr (@{$group->[$ELM_MEMBERS]}) {
	if ($mbr->[$ELM_CLASS] eq $CLS_GROUP) {
	    dumpGroup($fh, $mbr, $newIndent);
	}
	elsif ($mbr->[$ELM_CLASS] eq $CLS_SIMPLEATTR) {
#	    print $fh "$newIndent$mbr->[$ELM_NAME] : $mbr->[$ELM_VALUE] ;\n";
	    my $offset = length($mbr->[$ELM_NAME]) + 1;
	    my $q = getFlag($mbr, $FLG_VALQUOTED) ? "\"" : "";
	    if($mbr->[$ELM_NAME] eq $ELM_COMMENT) {dumpItem($fh, "$mbr->[$ELM_VALUE]", $newIndent, $offset);}
	    else {dumpItem($fh, "$mbr->[$ELM_NAME] : $q$mbr->[$ELM_VALUE]$q ;", $newIndent, $offset);}
	}
	elsif ($mbr->[$ELM_CLASS] eq $CLS_COMPLEXATTR) {
#	    print $fh "$newIndent$mbr->[$ELM_NAME]($mbr->[$ELM_VALUE]) ;\n";
	    my $offset = length($mbr->[$ELM_NAME]) + 1;
	    my $q = getFlag($mbr, $FLG_VALQUOTED) ? "\"" : "";
	    dumpItem($fh, "$mbr->[$ELM_NAME]($q$mbr->[$ELM_VALUE]$q) ;", $newIndent, $offset);
	}
    }
    print $fh "$indent}  /* End $group->[$ELM_TYPE]($name) */\n";
    
}

sub dumpItem {
    ##  prints something to a file a bit more smartly.

    my ($fh, $line, $indent, $offset) = @_;

    my $mi = "                                                                                                     ";
    my $exIndent = substr($mi, 0, $offset);
    my $newIndent = "$exIndent$indent";
    my @lines = split(/\n/, $line);
    foreach my $l (@lines) {
	print $fh  "$indent$l\n";
	$indent = $newIndent;  ##  Any subsequent lines get extra indent.
    }
}

sub readLine {
    my $fh = shift;

    my $line;
    my $bfr = "";
    while ($line = <$fh>) {
    	if($line !~ /\/\*.*comment.*reference path.*\\*\//) {$line =~ s/\/\*.*\\*\///g; } ## uncomment
	my $last = substr($line, -2, 1);  ##  Last char, before newline.  
	if ($last eq "\\") {
	    ##   Line ends with backslash,  Trim left and append to bfr, and continue
	    $line =~ s/^\s+//;
	    $bfr .= $line;
	}
	else {
	    ##  No continuation.  Trim both ends
	    $line =~ s/^\s+|\s+$//g;
	    $bfr .= $line;
	    if ($bfr eq "") {next}
	    return $bfr;
	}
    }
    return;

}

sub getObjClass {my $obj = shift;return $obj->[$ELM_CLASS];}
sub getObjType {my $obj = shift;return $obj->[$ELM_TYPE];}
sub getObjName {my $obj = shift;return $obj->[$ELM_NAME];}

sub getBusInfo {
    ## Gets bus information.
    my $lib = shift;   ##  The library group, which should contain the type group
    my $bus = shift;   ##  The bus group

    my $bit_from;
    my $bit_to;
    if (validateObject($lib, "getBusInfo", $CLS_GROUP, "library") && validateObject($bus, "getBusInfo", $CLS_GROUP, "bus")) {
	my $bus_type = getSimpleAttrValue($bus, "bus_type");
	if (defined $bus_type) {
	    my $type = getGroup($lib, "type", $bus_type);
	    if (defined $type) {
		$bit_from = getSimpleAttrValue($type, "bit_from");
		$bit_to = getSimpleAttrValue($type, "bit_to");
	    }
	    return ($bit_from, $bit_to);
	}
    }
    return (undef, undef);
}
sub updateBusInfo {
my ($libFile)= @_;
my $libList = findAllGroups($libFile, "library");
my @cellList = getCellList($libFile);
	foreach  my $grp (@$libList) {
		foreach  my $group (findAllGroups($grp, "type")) {
			foreach my $mem (@$group) {
				foreach my $x1 ($mem->[$ELM_MEMBERS]) {
				my ($lsb, $msb , $bit_to, $bit_from);
					foreach my $x (@$x1) {
					    if ($x->[$ELM_CLASS] eq $CLS_SIMPLEATTR && $x->[$ELM_NAME] eq "bit_from") { $bit_from = $x; $msb=$x->[$ELM_VALUE];}
					    if ($x->[$ELM_CLASS] eq $CLS_SIMPLEATTR && $x->[$ELM_NAME] eq "bit_to") {$bit_to = $x; $lsb =$x->[$ELM_VALUE];}
				}
				if($msb<$lsb) {$bit_from->[$ELM_VALUE]=$lsb; $bit_to->[$ELM_VALUE]=$msb;}
				}
				}
}
}
}


sub getAllSimpleAttrNames {
    ## Get all simple attribute names for an group

    my $obj = shift;
    
    my $names;
    if (validateObject($obj, "getallSimpleAttrNames", $CLS_GROUP)) {
	foreach my $x (@{$obj->[$ELM_MEMBERS]}) {
	    if ($x->[$ELM_CLASS] eq $CLS_SIMPLEATTR) {push @$names, $x->[$ELM_NAME]}
	}
    }
    return $names;
}

sub getSimpleAttrValue {
    ## Gets a simple attribute value from an object.
    my $obj = shift;
    my $attrName = shift;
    if (validateObject($obj, "getSimpleAttrValue $attrName", $CLS_GROUP)) {
	foreach my $x (@{$obj->[$ELM_MEMBERS]}) {
	    if ($x->[$ELM_CLASS] eq $CLS_SIMPLEATTR) {
		if ($x->[$ELM_NAME] eq $attrName) {
		    return $x->[$ELM_VALUE]
		}
	    }
	}
    }
    return;
}

sub validateObject {
    ## Validates the class,type,name of an object.
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
    ##  Removes leading/trailing quotes.
    ##  Returns unquoted string and value indicating whether it was quoted  in the first place.
    my $x = shift;
    my $q;
    if (!(defined $x))  {return ""}   ##  Convert undefined values to null strings
    $q = ($x =~ s/^\s*"(.*)"\s*$/$1/g);
    my $quoted = ($q) ? 1 : 0;
    return ($x, $quoted);
}

sub getGroup {
    ##  Gets a specific group, based on type and name.
    my ($obj, $type, $name) = @_;

    my $g = $CLS_GROUP;
#    print "getGroup: $type/\"$name\"\n";
    
    if (validateObject($obj, "getGroup", $CLS_GROUP)) {
	foreach my $x (@{$obj->[$ELM_MEMBERS]}) {
	    if ($x->[$ELM_CLASS] ne $CLS_GROUP) {next}
	    if ((defined $type) && ($x->[$ELM_TYPE] ne $type)) {next}
	    if ((defined $name) && ($x->[$ELM_NAME] ne $name)) {next}
	    return $x;
	}
    }
    return ;
}

sub findAllGroups {
    ## Finds all groups in the object provided.
    ## Object must be either FILE or GROUP to contain any
    ##  Returns a list.

    my $obj = shift;   ## Required
    my $type = shift;  ##  Type of group to find  (optional)
    my $name = shift;  ##  Name of group to find (optional)

    my $matches = [];
    if (($obj->[$ELM_CLASS] eq $CLS_FILE) || ($obj->[$ELM_CLASS] eq $CLS_GROUP)) {
	foreach my $x (@{$obj->[$ELM_MEMBERS]}) {
	    if ($x->[$ELM_CLASS] ne $CLS_GROUP) {next}
	    if ((defined $type) && ($x->[$ELM_TYPE] ne $type)) {next}
	    if ((defined $name) && ($x->[$ELM_NAME] ne $name)) {next}
	    ##  We have a match.
	    push @$matches, $x;
	}
    } else {
	error_msg("Not correct object class for finding groups \"$obj->[$ELM_CLASS]\"");
    }
    return $matches;
}

sub error_msg {
    my ($message)= (@_);
    
    $message='' if (not defined($message));
    
    my $whatiam="Error";
    my $whosmydad=(caller(1))[3];
    
    if (not defined($whosmydad)) {
	$whosmydad=(caller(0))[1];
    }
    else {
	$whosmydad=~s/main\:\://;
    }
    print "$whatiam:$whosmydad: $message\n";
    
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


sub processBusNotation {
    ##  Checks if the value of an object matches a bus notation, decomposes and saves the information.
    my $grp = shift;

    my $value = $grp->[$ELM_NAME];
    if (!(defined $value)) {return}
    if ($value =~ /(\w+)([\[<])(\d+)([\]>])/) {
	##  Bus pin
	$grp->[$ELM_ROOTNAME] = $1;
	$grp->[$ELM_BIT] = $3;
	defFlag($grp, $FLG_ISBUS, 1);
	if ($2 eq "<") {
	    defFlag($grp, $FLG_BUSPOINTY, 1);
	} 
	else {
	    defFlag($grp, $FLG_BUSSQUARE, 1);
	    $grp->[$ELM_NAME] =~ tr/[]/<>/;  ## Convert to pointy.
	}
    }
    else {
	$grp->[$ELM_ROOTNAME] = $value;
	$grp->[$ELM_BIT] = undef;
    }
}

sub processBusPins {
    ## Decompose list of pins into base name and bit number for easier sorting.
    my $pinList = shift;

    foreach my $pin (@$pinList) {
	my $name = $pin->[$ELM_NAME];
	if ($name =~ /(\w+)([\[<])(\d+)([\]>])/) {
	    ##  Bus pin
	    $pin->[$ELM_ROOTNAME] = $1;
	    $pin->[$ELM_BIT] = $3;
	}
	else {
	    $pin->[$ELM_ROOTNAME] = $name;
	    $pin->[$ELM_BIT] = undef;
	}
    }
}

sub pinNameSort {
    ##  Sort function for pins.
    ##  Sort first alphabetically by root name.
    #   If rootname is the same, use bit indices numerically

    if ($a->[$ELM_ROOTNAME] ne $b->[$ELM_ROOTNAME]) {$a->[$ELM_ROOTNAME] cmp $b->[$ELM_ROOTNAME]} else {$b->[$ELM_BIT] <=> $a->[$ELM_BIT]}

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

sub sortArcsExec {
    ##  Sorts the arcs of a pin by simple attribute values.
    my $pin = shift;


    my @arcList;
    my @idx;
    my $i = 0;
    ##  Get timing arcs, and remember where they came from.
    foreach my $obj (@{$pin->[$ELM_MEMBERS]}) {
	if (($obj->[$ELM_CLASS] eq $CLS_GROUP) && ($obj->[$ELM_TYPE] eq "timing")) {
	    push @arcList, $obj;
	    push @idx, $i;
	}
	$i++;
    }


    if (@arcList == 0) {return}  ## Bug out if no arcs.
 
#    print "Sorting arcs for $pin->[$ELM_NAME]\n";

   ##  Build list of attribute names to use for sorting.
    my %nh;
    my $arc;
    foreach my $arc (@arcList) {
	my $nl = getAllSimpleAttrNames($arc);
	foreach my $n (@$nl) {$nh{$n} = 1}
    }
    my @names = sort keys %nh;
    my $attrName;
    my $attrValue;
    
    ##  For each arc, build a temp list of the attr values for each of the attr names. Simpler for sorting.
    foreach my $arc (@arcList) {
	$arc->[$ELM_TEMP0] = [];
	foreach my $attrName (@names) {
	    $attrValue = getSimpleAttrValue($arc, $attrName);
	    if (!(defined $attrValue)) {$attrValue = ""};   ##  Convert undefs to ""; probably not necessary.
	    push @{$arc->[$ELM_TEMP0]}, $attrValue;
	}
    }

    ##  Now have the basis for a sort..
#    print "BEFORE\n";
#    foreach $arc (@arcList) {print "{@{$arc->[$ELM_TEMP0]}}\n"}
    my @arcListSorted = sort arcAttrSort @arcList;

    ## Put sorted arcs back in member list.
    foreach my $arc (@arcListSorted) {
	$i = shift @idx;
	$pin->[$ELM_MEMBERS]->[$i] = $arc;
    }
    $arc->[$ELM_TEMP0] = undef;
    
#    print "AFTER\n";
#    foreach $arc (@arcListSorted) {print "{@{$arc->[$ELM_TEMP0]}}\n"}
}

sub arcAttrSort {
    ##  Sort an arc list based on a variable list of attr values, $(a|b)->[$ELM_TEMP0]
    my $i = 0;
    my $n = @{$a->[$ELM_TEMP0]};  ##  Number of elements the same between a and b.

    ## Finds the first set attr values that are different, and cmp's them.
    for ($i=0; ($i<$n); $i++) {
	if ($a->[$ELM_TEMP0]->[$i] ne $b->[$ELM_TEMP0]->[$i]) {return ($a->[$ELM_TEMP0]->[$i] cmp $b->[$ELM_TEMP0]->[$i])}
    }
    return 0;
}


sub sortArcs {
    ## Sorts arcs for each pin.
    ##  Extend to buses?

    my $obj = shift;  ## Can be a FILE, library, cell, or pin.
    
    my @pinList = getPinList($obj);

    foreach my $pin (@pinList) {
	sortArcsExec($pin);
    }
}
sub getNameOfAttr {
    ##  Gets name from object
    my $obj = shift;
    my $attr = shift;
    my $value = shift;
    
#foreach my $cell (@$obj) {
foreach my $hier (@{$obj->[$ELM_MEMBERS]}) {
if(defined($hier->[$ELM_NAME]) && $hier->[$ELM_NAME] eq  $attr ) {
$hier->[$ELM_VALUE] = $value ;
}
#}


}
}

sub setFilePath($$) {
    ##  Changes the library file path in a FILE object.
    ##  Useful for writing modified libs to a differend area.

    my $obj = shift;
	my $path = shift;

    if (validateObject($obj, "setFilePath", $CLS_FILE)) {
	my $currentPath = $obj->[$ELM_NAME];
	my @t = split(/\//, $currentPath);
	my $rootName = pop @t;
	$path = Cwd::abs_path($path);
	if (!(-d $path)) { mkdir $path}
	my $newPath = "$path/$rootName";
	$obj->[$ELM_NAME] = $newPath;
    }
    else {
	error_msg("Expected class FILE, got $obj->[$ELM_CLASS]\n");
    }

}

sub getName {
    ##  Gets name from object
    my $obj = shift;
    return $obj->[$ELM_NAME];
}

sub getTemp0 {
    ##  Gets temp0 value
    my $obj = shift;
    return $obj->[$ELM_TEMP0];
}

sub getValue {
    ##  Gets name from object
    my $obj = shift;
    return $obj->[$ELM_VALUE];
}

sub getRootname {
    ##  Gets name from object
    my $obj = shift;
    return $obj->[$ELM_ROOTNAME];
}

sub getBit {
    ##  Gets name from object
    my $obj = shift;
    return $obj->[$ELM_BIT];
}

sub getParent {
    ##  Gets name from object
    my $obj = shift;
    return $obj->[$ELM_PARENT];
}

sub removeMember {
    ##  Remove a member object from its parent object
    my ($parent, $member) = @_;
    
	my $i;
    foreach my $parentMember(@{$parent->[$ELM_MEMBERS]}) {
	if ($parentMember == $member) {
	    splice(@{$parent->[$ELM_MEMBERS]}, $i, 1);  
	    return 1
	}
	$i++;
    }

    return 0;
}
sub remove_empty_timingMember {
    ##  Remove a member object from its parent object
    my ($master, $parent) = @_;
    
	my $i;

	my $flag =0;
    for(my $i = $#{$parent->[$ELM_MEMBERS]}; $i>=0; $i--) {
		if (${$parent->[$ELM_MEMBERS]}[$i]->[$ELM_CLASS] eq $CLS_GROUP){
	    $flag++;  last;
	}
	}
	if ($flag == 0) {
    removeMember($master,$parent);
}
    return 0;
}

sub AddMember {
    my ($parent, $member) = @_;
    push @{$parent->[$ELM_MEMBERS]}, $member;
     $member->[$ELM_PARENT] = $parent;
}

sub copyMember {
#copies member2 to member1 with sorting of simple attributes
    my ($member1,$member2) = @_;

	foreach my $element (@{$member2->[$ELM_MEMBERS]}) {
	my $obj = copyObject($element);
	push(@{$member1->[$ELM_MEMBERS]},$obj);
	}
	##Sorting and puting the simple attributes on the top
	my @simple;
	my @unique;
	for(my $i = $#{$member1->[$ELM_MEMBERS]}; $i>=0; $i--) {
		if (${$member1->[$ELM_MEMBERS]}[$i]->[$ELM_CLASS] eq $CLS_SIMPLEATTR) {
			push(@simple,${$member1->[$ELM_MEMBERS]}[$i]);
	    		splice(@{$member1->[$ELM_MEMBERS]}, $i, 1);  ## Removes element $i;
		}
	}


	foreach my $simp (@simple) {
	my $flag = ""; 
	foreach my $uniq (@unique) {if($simp->[$ELM_NAME] eq $uniq->[$ELM_NAME]) {$flag= "matched";last;}}
	if ($flag ne  "matched") {  push(@unique,$simp);}
	}
	    
	unshift(@{$member1->[$ELM_MEMBERS]},@unique);


}
#Updates by Dikshant
sub renameClsGRP {
#return;
#rename $CLS_GROUP by a new pattern  
my ($member,$old,$new) = @_;
my $i;
	if ($member->[$ELM_CLASS] eq $CLS_GROUP && (defined $member->[1]) && ($member->[1] =~ /$old/)) {$member->[1] =~ s/$old/$new/g;$i++;}

	foreach my $element (@{$member->[$ELM_MEMBERS]}) {
		if ($element->[$ELM_CLASS] eq $CLS_GROUP && (defined $element->[1]) && ($element->[1] =~ /$old/)) {$element->[1] =~ s/$old/$new/g;$i++;} 
		elsif ($element->[$ELM_CLASS] eq $CLS_GROUP && (defined $element->[1]) && ($element->[1] =~ /$new/)) {$element->[1] =~ s/$new/$old/g;$i++;} #Added else condition as rise to fall renaming was not working with copy_lut
	}
	return $i;
}
sub renameClsGRP_name {
#return;
#rename $CLS_GROUP by a new pattern  
my ($member,$old,$new) = @_;
my $i;
		if ($member->[$ELM_CLASS] eq $CLS_GROUP && (defined $member->[$ELM_NAME]) && ($member->[$ELM_NAME] =~ /$old/)) {$member->[$ELM_NAME] =~ s/$old/$new/g; $i++;}
	foreach my $element (@{$member->[$ELM_MEMBERS]}) {
		if ($element->[$ELM_CLASS] eq $CLS_GROUP && (defined $element->[$ELM_NAME]) && ($element->[$ELM_NAME] =~ /$old/)) {$element->[$ELM_NAME] =~ s/$old/$new/g; $i++;}
	}
	
	return $i;
}

sub removechildMember {
#return;
#deletes pattern matching member from member
my ($parent,$remove) = @_;
	for(my $i = $#{$parent->[$ELM_MEMBERS]}; $i>=0; $i--) {
		if (($parent->[$ELM_MEMBERS]->[$i]->[$ELM_CLASS] eq $CLS_GROUP)  && (defined $parent->[$ELM_MEMBERS]->[$i]->[1]) && ($parent->[$ELM_MEMBERS]->[$i]->[1] =~ /$remove/)) {
	    		splice(@{$parent->[$ELM_MEMBERS]}, $i, 1);  ## Removes element $i;
  		
		}
	}
	return 0;	
}


sub findGroupIndex {
    ##  Find the index of group object within a list based on type and name;
    ##  Returns undef if no match
    my ($obj, $type, $name,$bus) = @_;
    my $i = 0;
	my $j = 0;
    my $ll = @{$obj->[$ELM_MEMBERS]};
	if ($bus eq 1) {
    for ($i=0; ($i<$ll); $i++) {
	my $lb = @{$obj->[$ELM_MEMBERS]->[$i]->[$ELM_MEMBERS]}; 
	for ($j=0; ($j<$lb) ; $j++) {	
	if ($obj->[$ELM_MEMBERS]->[$i]->[$ELM_MEMBERS]->[$j]->[$ELM_CLASS] ne $CLS_GROUP) {next}  ##  Skip non-groups.
	if ((defined $type) && ($obj->[$ELM_MEMBERS]->[$i]->[$ELM_MEMBERS]->[$j]->[$ELM_TYPE] ne $type)) {next}
	if ((defined $name) && ($obj->[$ELM_MEMBERS]->[$i]->[$ELM_MEMBERS]->[$j]->[$ELM_NAME] ne $name)) {next}
	##  Looks like we have a match.
	return($i,$j);
    }
	}	

	} else {
	for ($i=0; ($i<$ll); $i++) {
	if ($obj->[$ELM_MEMBERS]->[$i]->[$ELM_CLASS] ne $CLS_GROUP) {next}  ##  Skip non-groups.
	if ((defined $type) && ($obj->[$ELM_MEMBERS]->[$i]->[$ELM_TYPE] ne $type)) {next}
	if ((defined $name) && ($obj->[$ELM_MEMBERS]->[$i]->[$ELM_NAME] ne $name)) {next}
	##  Looks like we have a match.
	return $i;
    }
	}
    return;
}

sub UpdateRelatedPin_min_pulse_width {
 ##this proc will upadte related pin to the parent timing pin name if timing_type is min_pulse_width
    my ($member, $pin) = @_;
    
	foreach my $element (@{$member->[$ELM_MEMBERS]}) {
		if ($element->[$ELM_CLASS] eq $CLS_SIMPLEATTR && defined $element->[$ELM_NAME] && $element->[$ELM_NAME] eq "timing_type" && $element->[$ELM_VALUE] eq "min_pulse_width") {
						    my @new_attrList;
						    my $rec = [];
						    @$rec= ("related_pin", $pin);
						    $new_attrList[0] = $rec;
						    UpdateSimpleAttr($member,\@new_attrList);
						    last;
						} #if
		} #foreach
	
}

sub UpdateSimpleAttr {

    ##  Sets a simple attribute value for existing attribute.
    my ($member, $Attrib) = @_;
    
	foreach my $element (@{$member->[$ELM_MEMBERS]}) {
		if ($element->[$ELM_CLASS] eq $CLS_SIMPLEATTR) {
			foreach my $attrRec (@$Attrib) {
					if ((defined $element->[$ELM_NAME]) && ($element->[$ELM_NAME] eq $attrRec->[0])) {
					if ($element->[$ELM_NAME] eq "related_pin") {
						foreach my $mem (@{$member->[$ELM_MEMBERS]}) {
							if ($mem->[$ELM_CLASS] eq $CLS_SIMPLEATTR && defined $mem->[$ELM_NAME] && $mem->[$ELM_NAME] eq "timing_type" && $mem->[$ELM_VALUE] eq "min_pulse_width") {
								print "Warning:Pin $member->[$ELM_PARENT]->[$ELM_NAME] : related_pin of timing group ($mem->[$ELM_NAME]:$mem->[$ELM_VALUE]) is updated from $element->[$ELM_VALUE] to $attrRec->[1]\n";
								last;
								}
							}
						}
						$element->[$ELM_VALUE] = $attrRec->[1];
					}
				}
			} #if
		} #foreach

}
sub setSimpleAttr {
    ##  Sets a simple attribute value for a group.
    ##  Replaces existing value, if attr with the same name exists.
    ##  Creates new, inserting after last existing attr otherwise.
    
    my ($grp, $attrName, $attrVal) = @_;

    my $lastAttr = -1;
    if (validateObject($grp, "setSimpleAttr", $CLS_GROUP)) {
	my $l = @{$grp->[$ELM_MEMBERS]};
	my $i;
	for ($i=0; ($i<$l); $i++) {
	    my $mbr = $grp->[$ELM_MEMBERS]->[$i];
	    if ($mbr->[$ELM_CLASS] eq $CLS_SIMPLEATTR) {
		##  Simple attr
		if ($mbr->[$ELM_NAME] eq $attrName) {
		    ##  Matches the name we're looking for.
		    $mbr->[$ELM_VALUE] = $attrVal;
		    defFlag($mbr, $FLG_VALTOUCHED, 1);
		    return $mbr;
		}
		##  Did not match.  Keep track of last simple attr location.
		$lastAttr = $i;
	    }
	}
	##  Failed to find attr.  Insert in member list after last existing simple attribute.
	##  If there were no simple attributes, inserts at the beginning.
	my $insAt = $lastAttr + 1;
	my $attr = createObject($CLS_SIMPLEATTR, undef, $attrName, $attrVal, $grp);
	splice @{$grp->[$ELM_MEMBERS]}, $insAt, 0, $attr;
	$attr->[$ELM_PARENT]=$grp;
	return $attr;
    }
    return 0;
}

sub setComplexAttr {
    ##  Sets a complex attribute value for a group.
    ##  Replaces existing value, if attr with the same name exists.
    ##  Creates new, inserting after last existing attr otherwise.
    
    my ($grp, $attrName, $attrVal) = @_;

    my $lastAttr = -1;
    my $lastSimple = -1;
    if (validateObject($grp, "setComplexAttr", $CLS_GROUP)) {
	my $l = @{$grp->[$ELM_MEMBERS]};
	my $i;
	for ($i=0; ($i<$l); $i++) {
	    my $mbr = $grp->[$ELM_MEMBERS]->[$i];
	    if ($mbr->[$ELM_CLASS] eq $CLS_SIMPLEATTR) {
		$lastSimple = $i;
		next;
	    }
	    elsif ($mbr->[$ELM_CLASS] eq $CLS_COMPLEXATTR) {
		##  Complex attr
		if ($mbr->[$ELM_NAME] eq $attrName) {
		    ##  Matches the name we're looking for.
		    $mbr->[$ELM_VALUE] = $attrVal;
		    defFlag($mbr, $FLG_VALTOUCHED, 1);
		    return $mbr;
		}
		##  Did not match.  Keep track of last complex attr location.
		$lastAttr = $i;
	    }
	}
	##  Failed to find attr.  Insert in member list after last existing complex attribute.
	##  If there were no complex attributes, inserts after last simple attr.
	my $insAt = ($lastAttr >= 0) ? $lastAttr+1 : $lastSimple+1;
	#  my $insAt = $lastAttr + 1;
	my $attr = createObject($CLS_COMPLEXATTR, undef, $attrName, $attrVal, $grp);
	splice @{$grp->[$ELM_MEMBERS]}, $insAt, 0, $attr;
	$attr->[$ELM_PARENT]=$grp;
	return $attr;
    }
    return 0;
}

sub delSimpleAttr {
    ##  Deletes a simple attribute value for a group.
    
    my ($grp, $attrName, $attrVal) = @_;

    my $lastAttr = -1;
    if (validateObject($grp, $CLS_SIMPLEATTR, $CLS_GROUP)) {
	my $l = @{$grp->[$ELM_MEMBERS]};
	my $i;
	for ($i=0; ($i<$l); $i++) {
	    my $mbr = $grp->[$ELM_MEMBERS]->[$i];
	    if ($mbr->[$ELM_CLASS] eq $CLS_SIMPLEATTR) {
		##  Simple attr
		if ($mbr->[$ELM_NAME] eq $attrName) {
		    ##  Matches the name we're looking for.
		    splice(@{$grp->[$ELM_MEMBERS]}, $i, 1);  ## Removes element $i;
		    return 1;
		}
	    }
	}
	##  Failed to find attr.  Insert in member list after last existing simple attribute.
	##  If there were no simple attributes, inserts at the beginning.
	return 0;
    }
    return 0;
}

sub delComplexAttr {
    ##  Deletes a simple attribute value for a group.
    
    my ($grp, $attrName, $attrVal) = @_;

    my $lastAttr = -1;
    if (validateObject($grp, $CLS_COMPLEXATTR, $CLS_GROUP)) {
	my $l = @{$grp->[$ELM_MEMBERS]};
	my $i;
	for ($i=0; ($i<$l); $i++) {
	    my $mbr = $grp->[$ELM_MEMBERS]->[$i];
	    if ($mbr->[$ELM_CLASS] eq $CLS_COMPLEXATTR) {
		if ($mbr->[$ELM_NAME] eq $attrName) {
		    ##  Matches the name we're looking for.
		    splice(@{$grp->[$ELM_MEMBERS]}, $i, 1);  ## Removes element $i;
		    return 1;
		}
	    }
	}
	##  Failed to find attr.  Insert in member list after last existing simple attribute.
	##  If there were no simple attributes, inserts at the beginning.
	return 0;
    }
    return 0;
}

sub deleteGroup {
    my ($obj, $groupType, $groupName) = @_;

    if (validateObject($obj, "deleteGroup", $CLS_GROUP)) {
	my $idx = findGroupIndex($obj, $groupType, $groupName,0);
	if (defined $idx) {
	    ##  Found it.
	    splice(@{$obj->[$ELM_MEMBERS]}, $idx, 1);  ## Removes element $idx;
	    #return 1;
	    deleteGroup($obj, $groupType, $groupName);
	    return 1;
	} else {
		####for buses
		foreach my $childobj (@{$obj->[$ELM_MEMBERS]}) {
		if ($childobj->[$ELM_CLASS] eq $CLS_GROUP) {
		my $idx = findGroupIndex($childobj, $groupType, $groupName,0);
			if (defined $idx) {
			    ##  Found it.
			    splice(@{$childobj->[$ELM_MEMBERS]}, $idx, 1);  ## Removes element $idx;
			    #return 1;
			    deleteGroup($childobj, $groupType, $groupName);
			    return 1;
			    
			}
			}
    		}
 	return 0;
	}
   }
}

#Updated RenameGroup function to accomodate renameBus feature
sub renameGroup {
    my ($obj, $groupType, $groupName, $new,$bus) = @_;
	my $idx = -1;
	my $idy = -1;
    if (validateObject($obj, "renameGroup", $CLS_GROUP)) {
	if($bus eq 0) {
		$idx = findGroupIndex($obj, $groupType, $groupName,$bus);
	} elsif($bus eq 1) {
		($idx,$idy) = findGroupIndex($obj, $groupType, $groupName,$bus);
	}

	if (($idx ne -1) and ($idy eq -1)) {
	    ##  Found it.
	    my @rec;
	    @rec = @{$obj->[$ELM_MEMBERS]}[$idx];
	    $obj->[$ELM_MEMBERS]->[$idx]->[$ELM_NAME]= $new;
	    return 1;
	} elsif (($idx ne -1) and ($idy ne -1)) {
	    my @rec;
	    @rec = @{$obj->[$ELM_MEMBERS]}[$idx];
	    $obj->[$ELM_MEMBERS]->[$idx]->[$ELM_MEMBERS]->[$idy]->[$ELM_NAME] = $new;
		$new =~ m/(.+)<.+/;
		$obj->[$ELM_MEMBERS]->[$idx]->[$ELM_NAME] = $1;
	    return 1;
		
	} else {
	    return 0;
	}
    }
}

sub defFlag {
    ##  Sets a flag's value according to the boolean value of $value
    my ($obj, $mask, $value) = @_;

    if ($value) {$obj->[$ELM_FLAGS] |= $mask} else {$obj->[$ELM_FLAGS] &= ~$mask}

}

sub getCellList {
    ##  Builds cell list for file or library object
    my $obj = shift;
    my $patt = shift;  ## optional pattern for name filtering
    
    my @fileList;
    my @libList;
    my @cellList;

    if ($obj->[$ELM_CLASS] eq $CLS_FILE) {
	push @fileList, $obj;
    }
    elsif (($obj->[$ELM_CLASS] eq $CLS_GROUP) && ($obj->[$ELM_TYPE] eq "library")) {
	push @libList, $obj;
    }
    elsif (($obj->[$ELM_CLASS] eq $CLS_GROUP) && ($obj->[$ELM_TYPE] eq "cell")) {
	push @cellList, $obj
    }
    else {
	error_msg("Expected FILE, GROUP/library or GROUP/cell\n");
	return @cellList;
    }

    foreach my $file (@fileList) {
	my $fileLibList = findAllGroups($file, "library");
	push @libList, @$fileLibList;
    }
    foreach my $lib (@libList) {
	my $libCellList = findAllGroups($lib, "cell");
	if (defined $patt) {
	    foreach my $cell (@$libCellList) {
		if ($cell->[$ELM_NAME] =~ /$patt/) {push @cellList, $cell}
	    }
	}
	else {push @cellList, @$libCellList}
    }
    return @cellList;
}

sub getPinList {
    ##  Builds pin list for file, library, cell or bus object
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
	push @cellList, $obj
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
	error_msg("Expected FILE, GROUP/library, GROUP/cell or GROUP/pin\n");
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
	push @pinList, @$cellPinList;
	$cellPinList = findAllGroups($cell, "pg_pin");
	push @pinList, @$cellPinList;

	##  Don't forget the pins under the buses...
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

sub getAttrList {
    ##  Gets all attributes from a group and returns a list.
    my $grp = shift;

    my @dst;
    if (validateObject($grp,"pushAllAttr", $CLS_GROUP)) {
 	foreach my $attr (@{$grp->[$ELM_MEMBERS]}) {
	    if (($attr->[$ELM_CLASS] eq $CLS_SIMPLEATTR) || ($attr->[$ELM_CLASS] eq $CLS_COMPLEXATTR)) {
		push @dst, copyObject($attr);
	    }
	}
    }
    return @dst;
}

sub findAttr {
    ##  Finds a particular attribute, simple or complex, by name
    my ($grp, $name) = @_;
    
    if (validateObject($grp,"findAttr", $CLS_GROUP)) {
 	foreach my $attr (@{$grp->[$ELM_MEMBERS]}) {
	    if (($attr->[$ELM_CLASS] eq $CLS_SIMPLEATTR) || ($attr->[$ELM_CLASS] eq $CLS_COMPLEXATTR)) {
		if ($name eq $attr->[$ELM_NAME]) {return $attr}
	    }
	}
    }
    return ;
}

sub pushObj {
    ##  Just pushes the provided list onto the object.
    my ($obj, $objToPush) = @_;
    
    if (validateObject($obj,"pushObj", $CLS_GROUP)) {
	push @{$obj->[$ELM_MEMBERS]}, $objToPush;
    }
}

sub pushObjList {
    ##  Just pushes the provided list onto the object.
    my ($obj, $objToPush) = @_;
    
    if (validateObject($obj,"pushObj", $CLS_GROUP)) {
	push @{$obj->[$ELM_MEMBERS]}, @$objToPush;
    }
}


sub copySimpleAttr {
    ## Copies the simple attributes from mone group to another.
    my ($src, $dst) = @_;

    if (validateObject($src,"copySimpleAttr", $CLS_GROUP) && validateObject($dst, "copySimpleAttr", $CLS_GROUP)) {
	foreach my $attr (@{$src->[$ELM_MEMBERS]}) {
	    if ($attr->[$ELM_CLASS] eq $CLS_SIMPLEATTR) {
		my $n = $attr->[$ELM_NAME];
		my $v = $attr->[$ELM_VALUE];
		my $newAttr = setSimpleAttr($dst, $attr->[$ELM_NAME], $attr->[$ELM_VALUE]);
		if ($newAttr) {$newAttr->[$ELM_FLAGS] = $src->[$ELM_FLAGS]}
	    }
	}
    }
}

sub copyComplexAttr {
    ## Copies the simple attributes from mone group to another.
    my ($src, $dst) = @_;

    if (validateObject($src,"copyComplexAttr", $CLS_GROUP) && validateObject($dst, "copyComplexAttr", $CLS_GROUP)) {
	foreach my $attr (@{$src->[$ELM_MEMBERS]}) {
	    if ($attr->[$ELM_CLASS] eq $CLS_COMPLEXATTR) {
		my $n = $attr->[$ELM_NAME];
		my $v = $attr->[$ELM_VALUE];
		my $newAttr = setComplexAttr($dst, $attr->[$ELM_NAME], $attr->[$ELM_VALUE]);
		if ($newAttr) {$newAttr->[$ELM_FLAGS] = $src->[$ELM_FLAGS]}
	    }
	}
    }
}

sub valString {
    my $var = shift;
    if (defined $var) {return $var} else {return "<undef>"};
}

sub dumpObj {
    my $obj = shift;

    if ($obj->[$ELM_CLASS] eq $CLS_FILE) {
	my $n = valString($obj->[$ELM_NAME]);
	print "FILE object: name=\"$n\"\n";
    }
    elsif ($obj->[$ELM_CLASS] eq $CLS_GROUP) {
	my $n = valString($obj->[$ELM_NAME]);
	my $t = valString($obj->[$ELM_TYPE]);
	print "GROUP object: type=$t, name=\"$n\"\n";
	foreach my $mbr ($obj->[$ELM_MEMBERS]) {
	    
	}
    }
    elsif ($obj->[$ELM_CLASS] eq $CLS_SIMPLEATTR) {
	my $n = valString($obj->[$ELM_NAME]);
	my $v = valString($obj->[$ELM_VALUE]);
	print "SIMPLE ATTR object: name=$n, value=\"$v\"\n";
    }
    elsif ($obj->[$ELM_CLASS] eq $CLS_COMPLEXATTR) {
	my $n = valString($obj->[$ELM_NAME]);
	my $v = valString($obj->[$ELM_VALUE]);
	print "COMPLEX ATTR object: name=$n, value=\"$v\"\n";
    }
}

sub createSimpleAttr {
    ##  Creates a simple attribute object
    my ($name, $value, $parent) = @_;

    my $attr = createObject($CLS_SIMPLEATTR, undef, $name, $value, $parent);
    return $attr;
}

sub insertObject {
    ## Insert a member at a particular location.
    my ($obj, $mbr, $idx) = @_;
    
    if (validateObject($obj, "insertObject", $CLS_GROUP)) {
	if (defined $idx) {
	    splice @{$obj->[$ELM_MEMBERS]}, $idx, 0, $mbr;
	}
	else {
	    push @{$obj->[$ELM_MEMBERS]}, $mbr;
	}
    }
}

1;
