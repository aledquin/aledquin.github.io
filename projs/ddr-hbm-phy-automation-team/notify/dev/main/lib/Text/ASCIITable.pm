package Text::ASCIITable;
# by Håkon Nessjøen <lunatic@cpan.org>
 
@ISA=qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw();
$VERSION = '0.22';
use Exporter;
use strict;
use Carp;
use Text::ASCIITable::Wrap qw{ wrap };
use overload '@{}' => 'addrow_overload', '""' => 'drawit';
use utf8;
use List::Util qw(reduce max sum);
 
sub new {
  my $self = {
                tbl_cols => [],
                tbl_rows => [],
                tbl_cuts => [],
                tbl_align => {},
                tbl_lines => {},
 
                des_top       => ['.','.','-','-'],
                des_middle    => ['+','+','-','+'],
                des_bottom    => ["'","'",'-','+'],
                des_rowline   => ['+','+','-','+'],
 
                des_toprow    => ['|','|','|'],
                des_middlerow => ['|','|','|'],
 
                cache_width   => {},
 
                options => $_[1] || { }
  };
 
  $self->{options}{reportErrors} = defined($self->{options}{reportErrors}) ? $self->{options}{reportErrors} : 0; # default setting
  $self->{options}{alignHeadRow} = $self->{options}{alignHeadRow} || 'auto'; # default setting
  $self->{options}{undef_as} = $self->{options}{undef_as} || ''; # default setting
  $self->{options}{chaining} = $self->{options}{chaining} || 0; # default setting
 
  bless $self;
 
  return $self;
}
 
sub setCols {
  my $self = shift;
  do { $self->reperror("setCols needs an array"); return $self->{options}{chaining} ? $self : 1; } unless defined($_[0]);
  @_ = @{$_[0]} if (ref($_[0]) eq 'ARRAY');
  do { $self->reperror("setCols needs an array"); return $self->{options}{chaining} ? $self : 1; } unless scalar(@_) != 0;
  do { $self->reperror("Cannot edit cols at this state"); return $self->{options}{chaining} ? $self : 1; } unless scalar(@{$self->{tbl_rows}}) == 0;
 
  my @lines = map { [ split(/\n/,$_) ] } @_;
 
  # Multiline support
  my $max=0;
  my @out;
  grep {$max = scalar(@{$_}) if scalar(@{$_}) > $max} @lines;
  foreach my $num (0..($max-1)) {
    my @tmp = map defined $$_[$num] && $$_[$num], @lines;
    push @out, \@tmp;
  }
 
  @{$self->{tbl_cols}} = @_;
        @{$self->{tbl_multilinecols}} = @out if ($max);
  $self->{tbl_colsismultiline} = $max;
 
  return $self->{options}{chaining} ? $self : undef;
}
 
sub addRow {
  my $self = shift;
  @_ = @{$_[0]} if (ref($_[0]) eq 'ARRAY');
  do { $self->reperror("Received too many columns"); return $self->{options}{chaining} ? $self : 1; } if scalar(@_) > scalar(@{$self->{tbl_cols}}) && ref($_[0]) ne 'ARRAY';
  my (@in,@out,@lines,$max);
 
        if (scalar(@_) > 0 && ref($_[0]) eq 'ARRAY') {
                foreach my $row (@_) {
                        $self->addRow($row);
                }
                return $self->{options}{chaining} ? $self : undef;
        }
 
  # Fill out row, if columns are missing (requested) Mar 21  2004 by a anonymous person
  while (scalar(@_) < scalar(@{$self->{tbl_cols}})) {
    push @_, ' ';
  }
 
  # Word wrapping & undef-replacing
  foreach my $c (0..$#_) {
    $_[$c] = $self->{options}{undef_as} unless defined $_[$c]; # requested by david@landgren.net/dland@cpan.org - https://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-ASCIITable
    my $colname = $self->{tbl_cols}[$c];
    my $width = $self->{tbl_width}{$colname} || 0;
    if ($width > 0) {
      $in[$c] = wrap($_[$c],$width);
    } else {
      $in[$c] = $_[$c];
    }
  }
 
  # Multiline support:
  @lines = map { [ split /\n/ ] } @in;
  $max = max map {scalar @$_} @lines;
  foreach my $num (0..($max-1)) {
    my @tmp = map { defined(@{$_}[$num]) && $self->count(@{$_}[$num]) ? @{$_}[$num] : '' } @lines;
    push @out, [ @tmp ];
  }
 
  # Add row(s)
  push @{$self->{tbl_rows}}, @out;
 
  # Rowlinesupport:
  $self->{tbl_rowline}{scalar(@{$self->{tbl_rows}})} = 1;
 
  return $self->{options}{chaining} ? $self : undef;
}
 
sub addrow_overload {
   my $self = shift;
   my @arr;
   tie @arr, $self;
   return \@arr;
}
 
sub addRowLine {
  my ($self,$row) = @_;
  do { $self->reperror("rows not added yet"); return $self->{options}{chaining} ? $self : 1; } unless scalar(@{$self->{tbl_rows}}) > 0;
 
        if (defined($row) && ref($row) eq 'ARRAY') {
                foreach (@$row) {
                        $_=int($_);
                        $self->{tbl_lines}{$_} = 1;
                }
        }
        elsif (defined($row)) {
                $row = int($row);
                do { $self->reperror("$row is higher than number of rows added"); return $self->{options}{chaining} ? $self : 1; } if ($row < 0 || $row > scalar(@{$self->{tbl_rows}}));
                $self->{tbl_lines}{$row} = 1;
        } else {
                $self->{tbl_lines}{scalar(@{$self->{tbl_rows}})} = 1;
        }
 
        return $self->{options}{chaining} ? $self : undef;
}
 
# backwardscompatibility, deprecated
sub alignColRight {
  my ($self,$col) = @_;
  do { $self->reperror("alignColRight is missing parameter(s)"); return $self->{options}{chaining} ? $self : 1; } unless defined($col);
  return $self->alignCol($col,'right');
}
 
sub alignCol {
  my ($self,$col,$direction) = @_;
  do { $self->reperror("alignCol is missing parameter(s)"); return $self->{options}{chaining} ? $self : 1; } unless defined($col) && defined($direction) || (defined($col) && ref($col) eq 'HASH');
  do { $self->reperror("Could not find '$col' in columnlist"); return $self->{options}{chaining} ? $self : 1; } unless defined(&find($col,$self->{tbl_cols})) || (defined($col) && ref($col) eq 'HASH');
 
  if (ref($col) eq 'HASH') {
    for (keys %{$col}) {
      do { $self->reperror("Could not find '$_' in columnlist"); return $self->{options}{chaining} ? $self : 1; } unless defined(&find($_,$self->{tbl_cols}));
      $self->{tbl_align}{$_} = $col->{$_};
    }
  } else {
    $self->{tbl_align}{$col} = $direction;
  }
  return $self->{options}{chaining} ? $self : undef;
}
 
sub alignColName {
  my ($self,$col,$direction) = @_;
  do { $self->reperror("alignColName is missing parameter(s)"); return $self->{options}{chaining} ? $self : 1; } unless defined($col) && defined($direction);
  do { $self->reperror("Could not find '$col' in columnlist"); return $self->{options}{chaining} ? $self : 1; } unless defined(&find($col,$self->{tbl_cols}));
 
  $self->{tbl_colalign}{$col} = $direction;
  return $self->{options}{chaining} ? $self : undef;
}
 
sub setColWidth {
  my ($self,$col,$width,$strict) = @_;
  do { $self->reperror("setColWidth is missing parameter(s)"); return $self->{options}{chaining} ? $self : 1; } unless defined($col) && defined($width);
  do { $self->reperror("Could not find '$col' in columnlist"); return $self->{options}{chaining} ? $self : 1; } unless defined(&find($col,$self->{tbl_cols}));
  do { $self->reperror("Cannot change width at this state"); return $self->{options}{chaining} ? $self : 1; } unless scalar(@{$self->{tbl_rows}}) == 0;
 
  $self->{tbl_width}{$col} = int($width);
  $self->{tbl_width_strict}{$col} = $strict ? 1 : 0;
 
  return $self->{options}{chaining} ? $self : undef;
}
 
sub headingWidth {
        my $self = shift;
  my $title = $self->{options}{headingText};
  return max map {$self->count($_)} split /\r?\n/, $self->{options}{headingText};
}
 
# drawing etc, below
sub getColWidth {
  my ($self,$colname) = @_;
  $self->reperror("Could not find '$colname' in columnlist") unless defined find($colname, $self->{tbl_cols});
 
  return $self->{cache_width}{$colname};
}
 
# Width-calculating functions rewritten for more speed by Alexey Sheynuk <asheynuk@iponweb.net>
# Thanks :)
sub calculateColWidths {
  my ($self) = @_;
  $self->{cache_width} = undef;
  my $cols = $self->{tbl_cols};
  foreach my $c (0..$#{$cols}) {
    my $colname = $cols->[$c];
    if (defined($self->{tbl_width_strict}{$colname}) && ($self->{tbl_width_strict}{$colname} == 1) && int($self->{tbl_width}{$colname}) > 0) {
      # maxsize plus the spaces on each side
      $self->{cache_width}{$colname} = $self->{tbl_width}{$colname} + 2;
    } else {
      my $colwidth = max((map {$self->count($_)} split(/\n/,$colname)), (map {$self->count($_->[$c])} @{$self->{tbl_rows}}));
      $self->{cache_width}{$colname} = $colwidth + 2;
    }
  }
  $self->addExtraHeadingWidth;
}
 
sub addExtraHeadingWidth {
  my ($self) = @_;
  return unless defined $self->{options}{headingText};
  my $tablewidth = -3 + sum map {$_ + 1} values %{$self->{cache_width}};
  my $headingwidth = $self->headingWidth();
  if ($headingwidth > $tablewidth) {
    my $extra = $headingwidth - $tablewidth;
    my $cols = scalar(@{$self->{tbl_cols}});
    my $extra_for_all = int($extra/$cols);
    my $extrasome = $extra % $cols;
    my $antall = 0;
    foreach my $col (@{$self->{tbl_cols}}) {
      my $extrawidth = $extra_for_all;
      if ($antall < $extrasome) {
        $antall++;
        $extrawidth++;
      }
      $self->{cache_width}{$col} += $extrawidth;
    }
  }
}
 
sub getTableWidth {
  my $self = shift;
  my $totalsize = 1;
  if (!defined($self->{cache_TableWidth})) {
    $self->calculateColWidths;
    grep {$totalsize += $self->getColWidth($_,undef) + 1} @{$self->{tbl_cols}};
    $self->{cache_TableWidth} = $totalsize;
  }
  return $self->{cache_TableWidth};
}
 
sub drawLine {
  my ($self,$start,$stop,$line,$delim) = @_;
  do { $self->reperror("Missing reqired parameters"); return 1; } unless defined($stop);
  $line = defined($line) ? $line : '-'; 
  $delim = defined($delim) ? $delim : '+'; 
 
  my $contents;
 
  $contents = $start;
 
  for (my $i=0;$i < scalar(@{$self->{tbl_cols}});$i++) {
    my $offset = 0;
    $offset = $self->count($start) - 1 if ($i == 0);
    $offset = $self->count($stop) - 1 if ($i == scalar(@{$self->{tbl_cols}}) -1);
 
    $contents .= $line x ($self->getColWidth(@{$self->{tbl_cols}}[$i]) - $offset);
 
    $contents .= $delim if ($i != scalar(@{$self->{tbl_cols}}) - 1);
  }
  return $contents.$stop."\n";
}
 
sub setOptions {
  my ($self,$name,$value) = @_;
  my $old;
  if (ref($name) eq 'HASH') {
    for (keys %{$name}) {
      $self->{options}{$_} = $name->{$_};
    }
  } else {
    $old = $self->{options}{$name} || undef;

    $self->{options}{$name} = $value;
  }
  return $old;
}
 
# Thanks to Khemir Nadim ibn Hamouda <nadim@khemir.net>
# Original code from Spreadsheet::Perl::ASCIITable
sub prepareParts {
  my ($self)=@_;
  my $running_width = 1 ;
 
  $self->{tbl_cuts} = [];
  foreach my $column (@{$self->{tbl_cols}}) {
    my $column_width = $self->getColWidth($column,undef);
    if ($running_width  + $column_width >= $self->{options}{outputWidth}) {
      push @{$self->{tbl_cuts}}, $running_width;
      $running_width = $column_width + 2;
    } else {
      $running_width += $column_width + 1 ;
    }
  }
  push @{$self->{tbl_cuts}}, $self->getTableWidth() ;
}
 
sub pageCount {
  my $self = shift;
  do { $self->reperror("Table has no max output-width set"); return 1; } unless defined($self->{options}{outputWidth});
 
  return 1 if ($self->getTableWidth() < $self->{options}{outputWidth});
  $self->prepareParts() if (scalar(@{$self->{tbl_cuts}}) < 1);
 
  return scalar(@{$self->{tbl_cuts}});
}
 
sub drawSingleColumnRow {
  my ($self,$text,$start,$stop,$align,$opt) = @_;
  do { $self->reperror("Missing reqired parameters"); return 1; } unless defined($text);
 
  my $contents = $start;
  my $width = 0;
  my $tablewidth = $self->getTableWidth();
  # ok this is a bad shortcut, but 'till i get up with a better one, I use this.
  if (($tablewidth - 4) < $self->count($text) && $opt eq 'title') {
    $width = $self->count($text);
  }
  else {
    $width = $tablewidth - 4;
  }
  $contents .= ' '.$self->align(
                       $text,
                       $align || 'left',
                       $width,
                       ($self->{options}{allowHTML} || $self->{options}{allowANSI} || $self->{options}{cb_count} ?0:1)
                   ).' ';
  return $contents.$stop."\n";
}
 
sub drawRow {
  my ($self,$row,$isheader,$start,$stop,$delim) = @_;
  do { $self->reperror("Missing reqired parameters"); return 1; } unless defined($row);
  $isheader = $isheader || 0;
  $delim = $delim || '|';
 
  my $contents = $start;
  for (my $i=0;$i<scalar(@{$row});$i++) {
    my $colwidth = $self->getColWidth(@{$self->{tbl_cols}}[$i]);
    my $text = @{$row}[$i];
 
    if ($isheader != 1 && defined($self->{tbl_align}{@{$self->{tbl_cols}}[$i]})) {
      $contents .= ' '.$self->align(
                         $text,
                         $self->{tbl_align}{@{$self->{tbl_cols}}[$i]} || 'auto',
                         $colwidth-2,
                         ($self->{options}{allowHTML} || $self->{options}{allowANSI} || $self->{options}{cb_count}?0:1)
                       ).' ';
    } elsif ($isheader == 1) {
 
      $contents .= ' '.$self->align(
                         $text,
                         $self->{tbl_colalign}{@{$self->{tbl_cols}}[$i]} || $self->{options}{alignHeadRow} || 'left',
                         $colwidth-2,
                         ($self->{options}{allowHTML} || $self->{options}{allowANSI} || $self->{options}{cb_count}?0:1)
                       ).' ';
    } else {
      $contents .= ' '.$self->align(
                         $text,
                         'auto',
                         $colwidth-2,
                         ($self->{options}{allowHTML} || $self->{options}{allowANSI} || $self->{options}{cb_count}?0:1)
                       ).' ';
    }
    $contents .= $delim if ($i != scalar(@{$row}) - 1);
  }
  return $contents.$stop."\n";
}
 
sub drawit {scalar shift()->draw()}
 
sub drawPage {
  my $self = shift;
  my ($pagenum,$top,$toprow,$middle,$middlerow,$bottom,$rowline) = @_;
  return $self->draw($top,$toprow,$middle,$middlerow,$bottom,$rowline,$pagenum);
}
 
# Thanks to Khemir Nadim ibn Hamouda <nadim@khemir.net> for code and idea.
sub getPart {
  my ($self,$page,$text) = @_;
  my $offset=0;
 
  return $text unless $page > 0;
  $text =~ s/\n$//;
 
  $self->prepareParts() if (scalar(@{$self->{tbl_cuts}}) < 1);
  $offset += (@{$self->{tbl_cuts}}[$_] - 1) for(0..$page-2);
 
  return substr($text, $offset, @{$self->{tbl_cuts}}[$page-1]) . "\n" ;
}
 
sub draw {
  my $self = shift;
  my ($top,$toprow,$middle,$middlerow,$bottom,$rowline,$page) = @_;
  my ($tstart,$tstop,$tline,$tdelim) = defined($top) ? @{$top} : @{$self->{des_top}};
  my ($trstart,$trstop,$trdelim) = defined($toprow) ? @{$toprow} : @{$self->{des_toprow}};
  my ($mstart,$mstop,$mline,$mdelim) = defined($middle) ? @{$middle} : @{$self->{des_middle}};
  my ($mrstart,$mrstop,$mrdelim) = defined($middlerow) ? @{$middlerow} : @{$self->{des_middlerow}};
  my ($bstart,$bstop,$bline,$bdelim) = defined($bottom) ? @{$bottom} : @{$self->{des_bottom}};
  my ($rstart,$rstop,$rline,$rdelim) = defined($rowline) ? @{$rowline} : @{$self->{des_rowline}};
  my $contents=""; $page = defined($page) ? $page : 0;
 
  delete $self->{cache_TableWidth}; # Clear cache
  $self->calculateColWidths;
 
  $contents .= $self->getPart($page,$self->drawLine($tstart,$tstop,$tline,$tdelim)) unless $self->{options}{hide_FirstLine};
  if (defined($self->{options}{headingText})) {
    my $title = $self->{options}{headingText};
    if ($title =~ m/\n/) { # Multiline title-support
      my @lines = split(/\r?\n/,$title);
      foreach my $line (@lines) {
        $contents .= $self->getPart($page,$self->drawSingleColumnRow($line,$self->{options}{headingStartChar} || '|',$self->{options}{headingStopChar} || '|',$self->{options}{headingAlign} || 'center','title'));
      }
    } else {
      $contents .= $self->getPart($page,$self->drawSingleColumnRow($self->{options}{headingText},$self->{options}{headingStartChar} || '|',$self->{options}{headingStopChar} || '|',$self->{options}{headingAlign} || 'center','title'));
    }
    $contents .= $self->getPart($page,$self->drawLine($mstart,$mstop,$mline,$mdelim)) unless $self->{options}{hide_HeadLine};
  }
 
  unless ($self->{options}{hide_HeadRow}) {
                # multiline-column-support
                foreach my $row (@{$self->{tbl_multilinecols}}) {
                        $contents .= $self->getPart($page,$self->drawRow($row,1,$trstart,$trstop,$trdelim));
                }
        }
  $contents .= $self->getPart($page,$self->drawLine($mstart,$mstop,$mline,$mdelim)) unless $self->{options}{hide_HeadLine};
  my $i=0;
  for (@{$self->{tbl_rows}}) {
    $i++;
    $contents .= $self->getPart($page,$self->drawRow($_,0,$mrstart,$mrstop,$mrdelim));
                if (($self->{options}{drawRowLine} && $self->{tbl_rowline}{$i} && ($i != scalar(@{$self->{tbl_rows}}))) || 
                                (defined($self->{tbl_lines}{$i}) && $self->{tbl_lines}{$i} && ($i != scalar(@{$self->{tbl_rows}})) && ($i != scalar(@{$self->{tbl_rows}})))) {
            $contents .= $self->getPart($page,$self->drawLine($rstart,$rstop,$rline,$rdelim)) 
                }
  }
  $contents .= $self->getPart($page,$self->drawLine($bstart,$bstop,$bline,$bdelim)) unless $self->{options}{hide_LastLine};
 
  return $contents;
}
 
# nifty subs
 
# Replaces length() because of optional HTML and ANSI stripping
sub count {
  my ($self,$str) = @_;
 
  if (defined($self->{options}{cb_count}) && ref($self->{options}{cb_count}) eq 'CODE') {
    my $ret = eval { return &{$self->{options}{cb_count}}($str); };
    return $ret if (!$@);
    do { $self->reperror("Error: 'cb_count' callback returned error, ".$@); return 1; } if ($@);
  }
  elsif (defined($self->{options}{cb_count}) && ref($self->{options}{cb_count}) ne 'CODE') {
    $self->reperror("Error: 'cb_count' set but no valid callback found, found ".ref($self->{options}{cb_count}));
    return length($str);
  }
  $str =~ s/<.+?>//g if $self->{options}{allowHTML};
  $str =~ s/\33\[(\d+(;\d+)?)?[musfwhojBCDHRJK]//g if $self->{options}{allowANSI}; # maybe i should only have allowed ESC[#;#m and not things not related to
  $str =~ s/\33\([0B]//g if $self->{options}{allowANSI};                           # color/bold/underline.. But I want to give people as much room as they need.
 
  return length($str);
}
 
sub align {
 
  my ($self,$text,$dir,$length,$strict) = @_;
 
  if ($dir =~ /auto/i) {
    if ($text =~ /^-?\d+([.,]\d+)*[%\w]?$/) {
      $dir = 'right';
    } else {
      $dir = 'left';
    }
  }
  if (ref($dir) eq 'CODE') {
    my $ret = eval { return &{$dir}($text,$length,$self->count($text),$strict); };
    return 'CB-ERR' if ($@);
    # Removed in v0.14 # return 'CB-LEN-ERR' if ($self->count($ret) != $length);
    return $ret;
  } elsif ($dir =~ /right/i) {
    my $visuallen = $self->count($text);
    my $reallen = length($text);
    if ($length - $visuallen > 0) {
      $text = (" " x ($length - $visuallen)).$text;
    }
    return substr($text,0,$length - ($visuallen-$reallen)) if ($strict);
    return $text;
  } elsif ($dir =~ /left/i) {
    my $visuallen = $self->count($text);
    my $reallen = length($text);
    if ($length - $visuallen > 0) {
      $text = $text.(" " x ($length - $visuallen));
    }
    return substr($text,0,$length - ($visuallen-$reallen)) if ($strict);
    return $text;
  } elsif ($dir =~ /justify/i) {
                my $visuallen = $self->count($text);
                my $reallen = length($text);
                $text = substr($text,0,$length - ($visuallen-$reallen)) if ($strict);
                if ($self->count($text) < $length - ($visuallen-$reallen)) {
                        $text =~ s/^\s+//; # trailing whitespace
                        $text =~ s/\s+$//; # tailing whitespace
 
                        my @tmp = split(/\s+/,$text); # split them words
 
                        if (scalar(@tmp)) {
                                my $extra = $length - $self->count(join('',@tmp)); # Length of text without spaces
 
                                my $modulus = $extra % (scalar(@tmp)); # modulus
                                $extra = int($extra / (scalar(@tmp))); # for each word
 
                                $text = '';
                                foreach my $word (@tmp) {
                                        $text .= $word . (' ' x $extra); # each word
                                        if ($modulus) {
                                                $modulus--;
                                                $text .= ' '; # the first $modulus words, to even out
                                        }
                                }
                        }
                }
          return $text; # either way, output text
  } elsif ($dir =~ /center/i) {
    my $visuallen = $self->count($text);
    my $reallen = length($text);
    my $left = ( $length - $visuallen ) / 2;
    # Someone tell me if this is matematecally totally wrong. :P
    $left = int($left) + 1 if ($left != int($left) && $left > 0.4);
    my $right = int(( $length - $visuallen ) / 2);
    $text = ($left > 0 ? " " x $left : '').$text.($right > 0 ? " " x $right : '');
    return substr($text,0,$length) if ($strict);
    return $text;
  } else {
    return $self->align($text,'auto',$length,$strict);
  }
}
 
sub TIEARRAY {
  my $self = shift;
 
        return bless { workaround => $self } , ref $self;
}
sub FETCH {
  shift->{workaround}->reperror('usage: push @$t,qw{ one more row };');
  return undef;
}
sub STORE {
  my $self = shift->{workaround};
  my ($index, $value) = @_;
 
  $self->reperror('usage: push @$t,qw{ one more row };');
}
sub FETCHSIZE {return 0;}
sub STORESIZE {return;}
 
# PodMaster should be really happy now, since this was in his wishlist. (ref: http://perlmonks.thepen.com/338456.html)
sub PUSH {
  my $self = shift->{workaround};
  my @list = @_;
 
  if (scalar(@list) > scalar(@{$self->{tbl_cols}})) {
    $self->reperror("too many elements added");
    return;
  }
 
  $self->addRow(@list);
}
 
sub reperror {
  my $self = shift;
  print STDERR Carp::shortmess(shift) if $self->{options}{reportErrors};
}
 
# Best way I could think of, to search the array.. Please tell me if you got a better way.
sub find {
  return undef unless defined $_[1];
  grep {return $_ if @{$_[1]}[$_] eq $_[0];} (0..scalar(@{$_[1]})-1);
  return undef;
}
 
1;
 
