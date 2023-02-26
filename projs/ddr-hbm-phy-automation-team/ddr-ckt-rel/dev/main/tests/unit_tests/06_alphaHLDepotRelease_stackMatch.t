use strict;
use warnings;
use 5.14.2;

use Test2::Bundle::More;
use File::Temp;
use Data::Dumper;

use FindBin qw($RealBin $RealScript);

use lib "$RealBin/../../lib/perl/";
use alphaHLDepotRelease;

our $DEBUG         = 0;
our $VERBOSITY     = 0;
our $FPRINT_NOEXIT = 1;

sub Main() {

	plan(9);

	my %stackHash     = ();
	my @metalStacks   = ();
	my @metalStacksIp = ();
	my %expected_hash = ();

	# No input arguments
	%stackHash     = ();
	@metalStacks   = ();
	@metalStacksIp = ();
	%expected_hash = ();
	do {
		local *STDOUT;
		open(STDOUT, '>>', "/dev/null") || return 0;
		open(STDERR, '>>', "/dev/null") || return 0;
		stackMatch( \@metalStacks, \@metalStacksIp, \%stackHash );
	};

	is_deeply( \%stackHash, \%expected_hash );

	# Testcase 1
	%stackHash     = ();
	@metalStacks   = ("13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z");
	@metalStacksIp = ("6M_1X_h_1Xa_v_1Ya_h_2Y_vh");
	%expected_hash = ( "13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z" => "6M_1X_h_1Xa_v_1Ya_h_2Y_vh" );
	do {
		local *STDOUT;
		open(STDOUT, '>>', "/dev/null") || return 0;
		open(STDERR, '>>', "/dev/null") || return 0;
		stackMatch( \@metalStacks, \@metalStacksIp, \%stackHash );
	};

	is_deeply( \%stackHash, \%expected_hash );

	# Testcase 2
	%stackHash     = ();
	@metalStacks   = ("10M_3Mx_4Cx_2Kx_1Gx_LB");
	@metalStacksIp = ("9M_3Mx_4Cx_2Kx");
	%expected_hash = ( "10M_3Mx_4Cx_2Kx_1Gx_LB" => "9M_3Mx_4Cx_2Kx" );
	do {
		local *STDOUT;
		open(STDOUT, '>>', "/dev/null") || return 0;
		open(STDERR, '>>', "/dev/null") || return 0;
		stackMatch( \@metalStacks, \@metalStacksIp, \%stackHash );
	};

	is_deeply( \%stackHash, \%expected_hash );

	# Testcase 3
	%stackHash     = ();
	@metalStacks   = ( "10M_3Mx_4Cx_2Kx_1Gx_LB", "13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z", "15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R" );
	@metalStacksIp = ( "9M_3Mx_4Cx_2Kx", "6M_1X_h_1Xa_v_1Ya_h_2Y_vh" );
	%expected_hash = (
		"10M_3Mx_4Cx_2Kx_1Gx_LB"              => "9M_3Mx_4Cx_2Kx",
		"13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z" => "6M_1X_h_1Xa_v_1Ya_h_2Y_vh"
	);
	do {
		local *STDOUT;
		open(STDOUT, '>>', "/dev/null") || return 0;
		open(STDERR, '>>', "/dev/null") || return 0;
		stackMatch( \@metalStacks, \@metalStacksIp, \%stackHash );
	};

	is_deeply( \%stackHash, \%expected_hash );

	# Testcase with empty arrays
	%stackHash     = ();
	@metalStacks   = ("10M_3Mx_4Cx_2Kx_1Gx_LB");
	@metalStacksIp = ();
	%expected_hash = ();
	do {
		local *STDOUT;
		open(STDOUT, '>>', "/dev/null") || return 0;
		open(STDERR, '>>', "/dev/null") || return 0;
		stackMatch( \@metalStacks, \@metalStacksIp, \%stackHash );
	};

	is_deeply( \%stackHash, \%expected_hash );

	# Testcase with empty arrays
	%stackHash     = ();
	@metalStacks   = ();
	@metalStacksIp = ("10M_3Mx_4Cx_2Kx_1Gx_LB");
	%expected_hash = ();
	do {
		local *STDOUT;
		open(STDOUT, '>>', "/dev/null") || return 0;
		open(STDERR, '>>', "/dev/null") || return 0;
		stackMatch( \@metalStacks, \@metalStacksIp, \%stackHash );
	};

	is_deeply( \%stackHash, \%expected_hash );

	# Testcase with numbers instead of strings
	%stackHash     = ();
	@metalStacks   = (123);
	@metalStacksIp = (1);
	%expected_hash = ( 123 => 1 );

	# This will work successfully because the internal regex substitution will
	# remove all numbers and the strings will be chaged into empty strings.
	# And, those empty strings will match each other.
	do {
		local *STDOUT;
		open(STDOUT, '>>', "/dev/null") || return 0;
		open(STDERR, '>>', "/dev/null") || return 0;
		stackMatch( \@metalStacks, \@metalStacksIp, \%stackHash );
	};

	is_deeply( \%stackHash, \%expected_hash );

	# Testcase with stringed numbers instead of metal stacks
	%stackHash     = ();
	@metalStacks   = ("123");
	@metalStacksIp = ("1");
	%expected_hash = ( 123 => 1 );
	do {
		local *STDOUT;
		open(STDOUT, '>>', "/dev/null") || return 0;
		open(STDERR, '>>', "/dev/null") || return 0;
		stackMatch( \@metalStacks, \@metalStacksIp, \%stackHash );
	};
	is_deeply( \%stackHash, \%expected_hash );

	# Large testcase
	%stackHash   = ();
	@metalStacks = qw (
	  10M_1X_h_1Xa_v_1Ya_h_4Y_vhvh_2Z
	  11M_2Xa1Xd_h_3Xe_vhv_2Y2R
	  12M_2X_hv_1Ya_h_6Y_vhvhvh_2Z
	  13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_SHDMIM
	  15M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Yx2R_MIM
	  16M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_6Y_vhvhvh_2Yy2R
	  7M_2X_vh_1Ya_v_3Y_hvh
	  7M_4Mx_3Dx
	  8M_4Mx_4Dx
	);
	@metalStacksIp = qw (
	  6M_5X
	  7M_2Xa1Xd_h_3Xe_vhv
	  6M_2X_hv_1Ya_h_2Y_vh
	  8M_1X_h_1Xa_v_1Ya_h_4Y_vhvh
	  8M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_2Y
	  8M_3Mx_5Dx
	  8M_4Mx_4Dx
	);
	%expected_hash = (
		"10M_1X_h_1Xa_v_1Ya_h_4Y_vhvh_2Z"                  => "8M_1X_h_1Xa_v_1Ya_h_4Y_vhvh",
		"11M_2Xa1Xd_h_3Xe_vhv_2Y2R"                        => "7M_2Xa1Xd_h_3Xe_vhv",
		"12M_2X_hv_1Ya_h_6Y_vhvhvh_2Z"                     => "6M_2X_hv_1Ya_h_2Y_vh",
		"13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_SHDMIM"       => "8M_1X_h_1Xa_v_1Ya_h_4Y_vhvh",
		"15M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Yx2R_MIM"       => "8M_1X_h_1Xa_v_1Ya_h_4Y_vhvh",
		"16M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_6Y_vhvhvh_2Yy2R" => "8M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_2Y",
		"7M_2X_vh_1Ya_v_3Y_hvh"                            => "6M_5X",
		"7M_4Mx_3Dx"                                       => "8M_4Mx_4Dx",
		"8M_4Mx_4Dx"                                       => "8M_4Mx_4Dx",
	);
	do {
		local *STDOUT;
		open(STDOUT, '>>', "/dev/null") || return 0;
		open(STDERR, '>>', "/dev/null") || return 0;
		stackMatch( \@metalStacks, \@metalStacksIp, \%stackHash );
	};

	is_deeply( \%stackHash, \%expected_hash );

	done_testing();

	return 0;
}

Main();

