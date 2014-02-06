package AnyEvent::Email::Bulk::Commands;

use common::sense;
use aliased 'AnyEvent::Email::Bulk::Util';
use AnyEvent::Email::Bulk::Constants;
use MIME::Base64;
use Data::Dumper;
use parent qw/
  Class::StateMachine
  Object::Event
/;

use Carp 'croak';
use constant CRLF => "\015\012";

our $AUTOLOAD;

Util->create_accessors( 
  qw/
    error
    success
    handle
    configuration
  /
);



sub new {
  my $class = shift;

  # FIXME: Perform validation after this point to verify 
  # things are working correcty and all parameters are
  # correct
  my $self = Class::StateMachine::bless( Util->as_hash( @_ ), $class, 'init' );

  # setup configuration
  $self->configuration( $self->_get_configuration );

  # initialize Object::Event
  $self->init_object_events;


  $self;

}




sub _write {
  my $self = shift;
  my $message = shift;
  my $filter = shift;

  warn "STATE: " . $self->state;
  warn "SENT: $message";

  # do we need this?
  $message =~ s/[\015\012]//g unless( $filter );

  $self
    ->handle
    ->push_write( $message . CRLF );

}

sub auth {
  my $self = shift;
  $self->_write( "AUTH PLAIN" );
}


sub run_with {
  my ( $self, $state ) = @_;

  $self->state( $state );
  $self->write;

}

sub _write_config {
  my ( $self, $config ) = @_;

  $self->_write( 
    MIME::Base64::encode_base64( 
      $self->configuration->$config 
    )
  );
}

sub AUTOLOAD {

  my $self = shift;

  # automate state checkers
  my ( $method ) = $AUTOLOAD =~ /\:\:is_(\w+)$/;

  croak "Undefined method: $AUTOLOAD" unless $method;

  # else just check the state
  $self->state eq $method;

}




# state machine stuff
sub write :OnState( 'connected' ) {
  my $self = shift;
  $self->_write( "EHLO " . $self->configuration->host );
}

sub write :OnState( 'starttls' ) {
  shift->_write( "STARTTLS" );
}

sub write :OnState( 'endtls' ) {
}

sub write :OnState( 'auth' ) {
  shift->_write( "AUTH LOGIN" );
}

sub write :OnState( 'post_auth' ) {
  shift->_write( "LOGIN" );
}

sub write :OnState( 'login' ) {
  shift->_write_config( 'username' );
}

sub write :OnState( 'password' ) {
  shift->_write_config( 'password' );
}

sub write :OnState( 'from' ) {
  my $self = shift;
  $self->_write( "MAIL FROM:" . $self->from );
}

sub write :OnState( 'to' ) {
  my $self = shift;
  $self->_write( "RCPT TO:" . $self->to );
}

sub write :OnState( 'data' ) {
  shift->_write( 'DATA' );
}

sub write :OnState( 'data_start' ) {
  my $self = shift;
  $self->_write( $self->data, 1 );
  $self->_write( '.' );
}

sub write :OnState( 'quit' ) {
  my $self = shift;
  $self->_write( 'QUIT' );
  $self->_success;

}



1;
__END__
