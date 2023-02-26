package Email::Stuff;
 
use 5.005;
use strict;
use Carp                   ();
use File::Basename         ();
use Params::Util           '_INSTANCE';
use Email::MIME            ();
use Email::MIME::Creator   ();
use Email::Send            ();
use prefork 'File::Type';
 
use vars qw{$VERSION};
BEGIN {
        $VERSION = '2.105';
}
 
#####################################################################
# Constructor and Accessors
 
sub new {
        my $class = ref $_[0] || $_[0];
 
        my $self = bless {
                send_using => [ 'Sendmail' ],
                # mailer   => undef,
                parts      => [],
                email      => Email::MIME->create(
                        header => [],
                        parts  => [],
                        ),
                }, $class;
 
        $self;
}
 
sub _self {
        my $either = shift;
        ref($either) ? $either : $either->new;
}
 
sub header_names {
        shift()->{email}->header_names;
}
 
sub headers {
        shift()->{email}->header_names; ## This is now header_names, headers is depreciated
}
 
sub parts {
        grep { defined $_ } @{shift()->{parts}};
}
 
 
 
 
 
#####################################################################
# Header Methods
 
sub header {
        my $self = shift()->_self;
        $self->{email}->header_str_set(ucfirst shift, shift) ? $self : undef;
}
 
sub to {
        my $self = shift()->_self;
        $self->{email}->header_str_set(To => shift) ? $self : undef;
}
 
sub from {
        my $self = shift()->_self;
        $self->{email}->header_str_set(From => shift) ? $self : undef;
}
 
sub cc {
        my $self = shift()->_self;
        $self->{email}->header_str_set(Cc => shift) ? $self : undef;
}
 
sub bcc {
        my $self = shift()->_self;
        $self->{email}->header_str_set(Bcc => shift) ? $self : undef;
}
 
sub subject {
        my $self = shift()->_self;
        $self->{email}->header_str_set(Subject => shift) ? $self : undef;
}
 
#####################################################################
# Body and Attachments
 
sub text_body {
        my $self = shift()->_self;
        my $body = defined $_[0] ? shift : return $self;
        my %attr = (
                # Defaults
                content_type => 'text/plain',
                charset      => 'utf-8',
                encoding     => 'quoted-printable',
                format       => 'flowed',
                # Params overwrite them
                @_,
                );
 
        # Create the part in the text slot
        $self->{parts}->[0] = Email::MIME->create(
                attributes => \%attr,
                body_str   => $body,
                );
 
        $self;
}
 
sub html_body {
        my $self = shift()->_self;
        my $body = defined $_[0] ? shift : return $self;
        my %attr = (
                # Defaults
                content_type => 'text/html',
                charset      => 'utf-8',
                encoding     => 'quoted-printable',
                # Params overwrite them
                @_,
                );
 
        # Create the part in the HTML slot
        $self->{parts}->[1] = Email::MIME->create(
                attributes => \%attr,
                body_str   => $body,
                );
 
        $self;
}
 
sub attach {
        my $self = shift()->_self;
        my $body = defined $_[0] ? shift : return undef;
        my %attr = (
                # Cheap defaults
                encoding => 'base64',
                # Params overwrite them
                @_,
                );
 
        # The more expensive defaults if needed
        unless ( $attr{content_type} ) {
                require File::Type;
                $attr{content_type} = File::Type->checktype_contents($body);
        }
 
        ### MORE?
 
        # Determine the slot to put it at
        my $slot = scalar @{$self->{parts}};
        $slot = 3 if $slot < 3;
 
        # Create the part in the attachment slot
        $self->{parts}->[$slot] = Email::MIME->create(
                attributes => \%attr,
                body       => $body,
                );
 
        $self;
}
 
sub attach_file {
        my $self = shift;
  my $body_arg = shift;
        my $name = undef;
        my $body = undef;
 
        # Support IO::All::File arguments
        if ( Params::Util::_INSTANCE($body_arg, 'IO::All::File') ) {
                $name = $body_arg->name;
                $body = $body_arg->all;
 
        # Support file names
        } elsif ( defined $body_arg and -f $body_arg ) {
                $name = $body_arg;
                $body = _slurp( $body_arg ) or return undef;
 
        # That's it
        } else {
                return undef;
        }
 
        # Clean the file name
        $name = File::Basename::basename($name) or return undef;
 
        # Now attach as normal
        $self->attach( $body, name => $name, filename => $name, @_ );
}
 
# Provide a simple _slurp implementation
sub _slurp {
        my $file = shift;
        local $/ = undef;
        local *SLURP;
        open( SLURP, "<$file" ) or return undef;
        my $source = <SLURP>;
        close( SLURP ) or return undef;
        \$source;
}
 
sub using {
        my $self = shift;
 
        if ( @_ ) {
                # Change the mailer
                if ( _INSTANCE($_[0], 'Email::Send') ) {
                        $self->{mailer} = shift;
                        delete $self->{send_using};
                } else {
                        $self->{send_using} = [ @_ ];
                        delete $self->{mailer};
                        $self->mailer;
                }
        }
 
        $self;
}
 
 
 
 
 
#####################################################################
# Output Methods
 
sub email {
        my $self  = shift;
        my @parts = $self->parts;
 
        ### Lyle Hopkins, code added to Fix single part, and multipart/alternative problems
        if ( scalar( @{ $self->{parts} } ) >= 3 ) {
                ## multipart/mixed
                $self->{email}->parts_set( \@parts );
        }
        ## Check we actually have any parts
        elsif ( scalar( @{ $self->{parts} } ) ) {
                if ( _INSTANCE($parts[0], 'Email::MIME') && _INSTANCE($parts[1], 'Email::MIME') ) {
                        ## multipart/alternate
                        $self->{email}->header_set( 'Content-Type' => 'multipart/alternative' );
                        $self->{email}->parts_set( \@parts );
                }
                ## As @parts is $self->parts without the blanks, we only need check $parts[0]
                elsif ( _INSTANCE($parts[0], 'Email::MIME') ) {
                        ## single part text/plain
                        _transfer_headers( $self->{email}, $parts[0] );
                        $self->{email} = $parts[0];
                }
        }
 
        $self->{email};
}
 
# Support coercion to an Email::MIME
sub __as_Email_MIME { shift()->email }
 
# Quick any routine
sub _any (&@) {
        my $f = shift;
        return if ! @_;
        for (@_) {
                return 1 if $f->();
        }
        return 0;
}
 
# header transfer from one object to another
sub _transfer_headers {
        # $_[0] = from, $_[1] = to
        my @headers_move = $_[0]->header_names;
        my @headers_skip = $_[1]->header_names;
        foreach my $header_name (@headers_move) {
                next if _any { $_ eq $header_name } @headers_skip;
                my @values = $_[0]->header($header_name);
                $_[1]->header_str_set( $header_name, @values );
        }
}
 
sub as_string {
        shift()->email->as_string;
}
 
sub send {
        my $self = shift;
        $self->using(@_) if @_; # Arguments are passed to ->using
        my $email = $self->email or return undef;
        $self->mailer->send( $email );
}
 
sub _driver {
        my $self = shift;
        $self->{send_using}->[0];
}
 
sub _options {
        my $self = shift;
        my $options = $#{$self->{send_using}};
        @{$self->{send_using}}[1 .. $options];
}
 
sub mailer { 
        my $self = shift;
        return $self->{mailer} if $self->{mailer};
 
        my $driver = $self->_driver;
        $self->{mailer} = Email::Send->new( {
                mailer      => $driver,
                mailer_args => [ $self->_options ],
                } );
        unless ( $self->{mailer}->mailer_available($driver, $self->_options) ) {
                Carp::croak("Driver $driver is not available");
        }
 
        $self->{mailer};
}
 
#####################################################################
# Legacy compatibility
 
sub To      { shift->to(@_)      }
sub From    { shift->from(@_)    }
sub CC      { shift->cc(@_)      }
sub BCC     { shift->bcc(@_)     }
sub Subject { shift->subject(@_) }
sub Email   { shift->email(@_)   }
 
1;
