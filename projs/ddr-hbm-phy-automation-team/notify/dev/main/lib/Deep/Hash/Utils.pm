package Deep::Hash::Utils;
$Deep::Hash::Utils::VERSION = '0.04';
use 5.006;
use strict;
use warnings;
 
require Exporter;
 
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw( reach slurp nest deepvalue ) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = ();
 
 
my $C;
 
# Recursive version of C<each>;
sub reach {
        my $ref = shift;
        if (ref $ref eq 'HASH') {
 
 
                if (defined $C->{$ref}{v}) {
                        if (ref $C->{$ref}{v} eq 'HASH') {
                            if (my @rec = reach($C->{$ref}{v})) {
                                    return ($C->{$ref}{k},@rec);
                            } 
                        } elsif (ref $C->{$ref}{v} eq 'ARRAY') {
                                if (my @rec = reach($C->{$ref}{v})) {
                                        if (defined $C->{$ref}{k}) {
                                                return $C->{$ref}{k},@rec;
                                        }
                                        return @rec;
                                } 
 
                        }
                        undef $C->{$ref};
                } 
 
 
                if (my ($k,$v) = each %$ref) {
                        $C->{$ref}{v} = $v;
                        $C->{$ref}{k} = $k;
                        return ($k,reach($v));
                }
 
                return ();
 
 
        } elsif (ref $ref eq 'ARRAY') {
 
 
                if (defined $C->{$ref}{v}) {
                        if (ref $C->{$ref}{v} eq 'HASH' || 
                            ref $C->{$ref}{v} eq 'ARRAY') {
 
                                if (my @rec = reach($C->{$ref}{v})) {
                                        if (defined $C->{$ref}{k}) {
                                                return $C->{$ref}{k},@rec;
                                        }
                                        return @rec;
                                } 
                        } 
                }
 
 
                if (my $v = $ref->[$C->{$ref}{i}++ || 0]) {
                        $C->{$ref}{v} = $v;
                        return (reach($v));
                }
 
                return ();
        }
        return $ref;
}
 
 
# run C<reach> over entire hash and return the final list of values at once
sub slurp {
        my $ref = shift;
        my @h;
        while (my @a = reach($ref)) {
                push @h,\@a;
        }
        return @h;
}
 
 
# Define nested hash keys from the given list of values
sub nest {
        my $hr = shift;
        my $key = shift;
        $hr->{$key} ||= {};
        my $ref = $hr->{$key};
 
        while ($key = shift @_) {
                $hr = $ref;
                if (@_ > 1) {
                        $hr->{$key} ||= {};
                        $ref = $hr->{$key};
                } else {
                        $hr->{$key} = shift;
                }
        }
        return $hr;
}
 
 
# Return value at the end of the given nested hash keys and/or array indexes
sub deepvalue {
        my $hr = shift;
        while (@_) {
                my $key = shift;
                if (ref $hr eq 'HASH') {
                        return unless ($hr = $hr->{$key});
                } elsif (ref $hr eq 'ARRAY') {
                        return unless ($hr = $hr->[$key]);
                } else {
                        return;
                }
        }
        return $hr;
}
 
 
1;
__END__
