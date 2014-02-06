package AnyEvent::Email::Bulk::LineParser;

use common::sense;
use constant {
  CODE      => 0,
  MESSAGE   => 1,
};

# line parsers
sub _parse {
  my ( $self, $line ) = @_;
  [ $line =~ /(\d\d\d)\s+(.*)$/ ]
}

sub ok {
  my ( $self, $line ) = @_;
  my $ok = $self->_parse( $line )->[ CODE ]; 

  $ok >= 200 && $ok < 300;
}

sub starttls_ready {
  my ( $self, $line ) = @_;
  my $parsed = $self->_parse( $line );

  $parsed->[ CODE ] == 220 && $parsed->[ MESSAGE ] =~ /TLS/;
}


sub password_ok {
  shift->_parse( @_ )->[ CODE ] == 235; 
}


sub continue {
  my $code =  shift->_parse( @_ )->[ CODE ];

  $code >= 300 && $code < 400;
}

sub continue_with_username {
  my ( $self, $line ) = @_;
  my $parsed = $self->_parse( $line );

  $parsed->[ CODE ] == 334 && $parsed->[ MESSAGE ] =~ /VXNlcm5hbWU6/;
}

sub continue_with_password {
  my ( $self, $line ) = @_;
  my $parsed = $self->_parse( $line );

  $parsed->[ CODE ] == 334 && $parsed->[ MESSAGE ] =~ /UGFzc3dvcmQ6/;
}

sub continue_with_data {
  shift->_parse( @_ )->[ MESSAGE ] =~ /Continue/;
}

sub is_error {
  my ( $self, $line ) = @_;
  my $parsed = $self->_parse( $line );

  $parsed->[ CODE ] > 400;
}


1;
__END__
