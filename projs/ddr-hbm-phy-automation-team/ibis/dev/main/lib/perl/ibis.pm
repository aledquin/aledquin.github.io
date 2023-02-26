###############################################################################
# Common IBIS utility functions.
# Author: Harsimrat Singh Wadhawan
###############################################################################
package ibis;

use strict;
use warnings;

use strict;
use warnings;
use Exporter;
use Term::ANSIColor;
use Data::Dumper;
use Scalar::Util qw(looks_like_number);
use FindBin qw( $RealBin $RealScript );
use lib "$RealBin/../../lib/perl";
use Util::CommonHeader;
use Util::Messaging;
use Util::Misc;
use Util::DS;

print "-PERL- Loading Package: ". __PACKAGE__ ."\n";
our @ISA   = qw(Exporter);

# Symbols (subs or vars) to export by default 
our @EXPORT    = qw( 
  map_name map_voltage 
  remove_blanks
  lerp
  get_number verify odtoffConstant
);

# Symbols to export by request 
our @EXPORT_OK = qw();

#---- CONSTANTS -------------------#
use constant DDR1_VIO   => 2.5;
use constant DDR2_VIO   => 1.8;
use constant DDR3_VIO   => 1.5;
use constant DDR3L_VIO  => 1.35;
use constant DDR4_VIO   => 1.2;
use constant DDR5_VIO   => 1.1;
#----------------------------------#
use constant LPDDR1_VIO   => 1.8;
use constant LPDDR2_VIO   => 1.2;
use constant LPDDR3_VIO   => 1.2;
use constant LPDDR4_VIO   => 1.1;
use constant LPDDR4X_VIO  => 0.6;
use constant LPDDR5_VIO   => 0.5;
use constant LPDDR5X_VIO  => 0.5;

#--------------------------------------
# Map name to a specific description
#--------------------------------------
sub map_name($$) {

	my $model 		= shift;
	my $description = shift;

	if 	  ($model =~ /.*_d3_.*/i   && $description =~ /ddr3/i	) { return 1; }
	elsif ($model =~ /.*_d3l_.*/i  && $description =~ /ddr3l/i	) { return 1; }
	elsif ($model =~ /.*_dl3_.*/i  && $description =~ /lpddr3/i	) { return 1; }
	elsif ($model =~ /.*_d4_.*/i   && $description =~ /ddr4/i	) { return 1; }
	elsif ($model =~ /.*_d4b_.*/i  && $description =~ /ddr4/i	) { return 1; }
	elsif ($model =~ /.*_lpd4_.*/i && $description =~ /lpddr4/i	) { return 1; }
	elsif ($model =~ /.*_dl4_.*/i  && $description =~ /lpddr4/i	) { return 1; }	
	elsif ($model =~ /.*_lp4x_.*/i && $description =~ /lpddr4x/i) { return 1; }
	elsif ($model =~ /.*_dl4x_.*/i && $description =~ /lpddr4x/i) { return 1; }
	elsif ($model =~ /.*_lpd5_.*/i && $description =~ /lpddr5/i	) { return 1; }	
	elsif ($model =~ /.*_d5_.*/i   && $description =~ /ddr5/i	) { return 1; }
	elsif ($model =~ /.*_d5b_.*/i  && $description =~ /ddr5/i	) { return 1; }
	else                                                          { return 0; }
	
}

#--------------------------------------
# Map model name to a specific VDDQ voltage (JEDEC standards)
#--------------------------------------
sub map_voltage($){

    my $model = shift;

    if 	  ($model =~ /.*_d3_.*/i   	) { return DDR3_VIO;   }
	elsif ($model =~ /.*_d3l_.*/i  	) { return DDR3L_VIO;  }
	elsif ($model =~ /.*_dl3_.*/i  	) { return DDR3L_VIO;  }
	elsif ($model =~ /.*_d4_.*/i   	) { return DDR4_VIO;   }
	elsif ($model =~ /.*_d4b_.*/i  	) { return DDR4_VIO;   }
	elsif ($model =~ /.*_lpd4_.*/i 	) { return LPDDR4_VIO; }
	elsif ($model =~ /.*_dl4_.*/i  	) { return LPDDR4_VIO; }	
	elsif ($model =~ /.*_lp4x_.*/i  ) { return LPDDR4X_VIO;}
	elsif ($model =~ /.*_dl4x_.*/i  ) { return LPDDR4X_VIO;}
	elsif ($model =~ /.*_lpd5_.*/i 	) { return LPDDR5_VIO; }	
	elsif ($model =~ /.*_d5_.*/i   	) { return DDR5_VIO;   }
	elsif ($model =~ /.*_d5b_.*/i  	) { return DDR5_VIO;   }
	else                              { return NULL_VAL;   }

}

#--------------CONSTANTS-----------#
#----------------------------------#
use constant odtoffConstant => 5000000;

#-----------------------------------------------------------------
#  sub 'remove_blanks'
#  Remove blank lines from an array of lines.
#-----------------------------------------------------------------
sub remove_blanks {

	my ($one_ref) = @_;
	my @a = @{$one_ref};

	my @indices;

	for ( my $i = 0 ; $i < @a ; $i++ ) {
		my $line = $a[$i];
		if ( !scalar trim $line) {
			push @indices, $i;
		}
	}

	my @sorted = sort { $b <=> $a } @indices;

	foreach my $index (@sorted) {
		splice @a, $index, 1;
	}

	return @a;

}

#-----------------------------------------------------------------
#  sub 'lerp'
#  linear interpolation
#-----------------------------------------------------------------
sub lerp {

	my $x  = shift;
	my $x1 = shift;
	my $y1 = shift;
	my $x2 = shift;
	my $y2 = shift;
	return $y1 + ( $x - $x1 ) * ( ( $y2 - $y1 ) / ( $x2 - $x1 ) );

}

#-----------------------------------------------------------------
#  sub 'get_number'
#  Extracts numbers from a string with units.
#-----------------------------------------------------------------
sub get_number($) {

	my $input  = shift;
	my $answer = $input;

	# Amperes, Volts, Farads, Seconds

	if ( $input =~ /^[-+]?[0-9]*\.?[0-9]+(a|v|f|s)$/i ) {
		$answer =~ s/[^0-9.-]//g;
		return $answer / 1;
	}

	elsif ( $input =~ /[-+]?[0-9]*\.?[0-9]+m(a|v|f|s)/i ) {
		$answer =~ s/[^0-9.]//g;
		if   ( $input =~ /-/ ) { return $answer / -1000; }
		else                   { return $answer / 1000; }
	}

	elsif ( $input =~ /[-+]?[0-9]*\.?[0-9]+u(a|v|f|s)/i ) {
		$answer =~ s/[^0-9.]//g;
		if   ( $input =~ /-/ ) { return $answer / -1000000; }
		else                   { return $answer / 1000000; }
	}

	elsif ( $input =~ /[-+]?[0-9]*\.?[0-9]+n(a|v|f|s)/i ) {
		$answer =~ s/[^0-9.]//g;
		if   ( $input =~ /-/ ) { return $answer / -1000000000; }
		else                   { return $answer / 1000000000; }
	}

	elsif ( $input =~ /[-+]?[0-9]*\.?[0-9]+p(a|v|f|s)/i ) {
		$answer =~ s/[^0-9.]//g;
		if   ( $input =~ /-/ ) { return $answer / -1000000000000; }
		else                   { return $answer / 1000000000000; }
	}

	elsif ( $input =~ /[-+]?[0-9]*\.?[0-9]+f(a|v|f|s)/i ) {
		$answer =~ s/[^0-9.]//g;
		if   ( $input =~ /-/ ) { return $answer / -1000000000000000; }
		else                   { return $answer / 1000000000000000; }
	}

	elsif ( $input =~ /^[-+]?[0-9]*\.?[0-9]+$/i ) {
		return $input;
	}

	else {
		return NULL_VAL;
	}

}

# find whether the values are within the specified percentage values
sub verify($$$) {

	my $thresh    = shift;
	my $value  	  = shift;
	my $new_value = shift;

	unless (defined $thresh && defined $thresh && defined $thresh){
		dprint(HIGH, "The \"verify\" subroutine requires 3 arguments; threshold value, expected impedance, actual impedance.");
		return -1;
	}

	unless (looks_like_number($thresh) && looks_like_number($value) && looks_like_number($new_value)){
		dprint(HIGH, "The \"verify\" subroutine was not given integer/float arguments. Given arguments: $thresh, $value, $new_value\n");
		return -1;
	}

	$thresh = $thresh / 100;

	if ( $value == odtoffConstant and $new_value > odtoffConstant ) { return 1; }
	elsif ( $new_value <= ($value + ($value * $thresh)) and $new_value >= ( $value - $value * $thresh ) ) { return 1; }
	else                                                                                                  { return 0; }

}

################################
# A package must return "TRUE" #
################################

1;


__END__