package Text::ASCIITable::Wrap;
 
@ISA=qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(wrap);
$VERSION = '0.2';
use Exporter;
use strict;
use Carp;
 
sub wrap {
  my ($text,$width,$nostrict) = @_;
  Carp::shortmess('Missing required text or width parameter.') if (!defined($text) || !defined($width));
  my $result='';
  for (split(/\n/,$text)) {
    $result .= _wrap($_,$width,$nostrict)."\n";
  }
  chop($result);
  return $result;
}
 
sub _wrap {
  my ($text,$width,$nostrict) = @_;
  my @result;
  my $line='';
  $nostrict = defined($nostrict) && $nostrict == 1 ? 1 : 0;
  for (split(/ /,$text)) {
    my $spc = $line eq '' ? 0 : 1;
    my $len = length($line);
    my $newlen = $len + $spc + length($_);
    if ($len == 0 && $newlen > $width) {
      push @result, $nostrict == 1 ? $_ : substr($_,0,$width); # kutt ned bredden
      $line='';
    }
    elsif ($len != 0 && $newlen > $width) {
      push @result, $nostrict == 1 ? $line : substr($line,0,$width);
      $line = $_;
    } else {
      $line .= (' ' x $spc).$_;
    }
  }
  push @result,$nostrict == 1 ? $line : substr($line,0,$width) if $line ne '';
  return join("\n",@result);
}
 
 
1;
 
__END__
