package AnyEvent::Email::Bulk::Emailer;

use common::sense;
use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Socket;
use Net::Cmd;

use aliased 'AnyEvent::Email::Bulk::Configuration';
use aliased 'AnyEvent::Email::Bulk::Util';
use AnyEvent::Email::Bulk::Constants; 

use Net::Cmd;
use Mail::Address;
use Carp qw(croak confess);

use constant {
  LAST_STATE => 0,
  CURRENT_LINE_STATUS => 1
};

use parent qw/
  AnyEvent::Email::Bulk::Commands
  AnyEvent::Email::Bulk::Counter
  AnyEvent::Email::Bulk::LineParser
/;


my @params = qw/
  from
  to
  data
  use
  fh
/;


sub send {

  my $self    = shift;
  my $config  = $self->configuration;
  my $done    = AnyEvent->condvar;

  $self->increment;

  tcp_connect $config->host, $config->port => sub {

    # FIXME: die if we dont' have a socket here
    my $sock = shift or $self->_error( "Unable to connect" );
    my $handle = AnyEvent::Handle->new( 

      fh => $sock,

      tls_ctx => {
        method          => "any",
        verify          => 0,
        verify_peername => 'smtp'
      },

      on_eof => sub {
        warn "EOF RECIEVED";
      }

    );

    # save the handler
    $self->handle( $handle );

    # set it up
    $self->setup_handler;

  };

}

sub setup_handler {
  my $self = shift;

  # move on
  $self->handle->on_read(
    $self->on_read_handler
  );

  # set the state and write
  $self->run_with( 'connected' );

}


sub checks {
  +{
    login     => [ auth => 'continue_with_username' ],
    password  => [ login => 'continue_with_password' ],
    from => [ password => 'ok' ],
    to => [ from => 'ok' ],
    data => [ to => 'ok' ],
    data_start => [ data => 'continue' ],
    quit => [ data_start => 'ok' ]
  };

}


sub on_read_handler {
  my $self = shift;
  my $handle = $self->handle;
  my $config = $self->configuration;

  sub {
    my $aeh = shift;

    # read every line
    $aeh->unshift_read( line => sub {
      my ( $aeh, $line ) = @_;

      warn "RECIEVED: $line";

      # handle errors first
      if( $self->is_error( $line ) ) {
        $self->_error( $line );
        return;
      }

      # we are in connected state and we got an OK
      elsif( $self->ok( $line ) && $self->is_connected ) { 

        $self->run_with( 'greeted' );

        # we need to starttls now
        if( $config->starttls ) {
          $self->run_with( 'starttls' )
        }

        else {
          # or do the auth
          $self->run_with( 'auth' );
        }

      }

      # starttls state and are we ready to start the handshake
      elsif(  $self->is_starttls && $self->starttls_ready( $line ) ) {

        $self->handle->on_starttls( sub {
            my ( $handle, $success ) = @_;

            if( $success ) {
              $self->run_with( 'auth' );
            }

            else {
              $self->_error( "TLS Handshake failed" );
              return;
            }

        } );

        $self->handle->starttls( 'connect' );
      }

  
      else {

        my $checks = $self->checks;
        while( my ( $key, $value ) = each( %{ $checks } ) ) {
          my $last_state = "is_" . $value->[ LAST_STATE ];
          my $current_state = $value->[ CURRENT_LINE_STATUS ];

          # warn "CALLING: $last_state AND $current_state";
          if( $self->$last_state && $self->$current_state( $line ) ) {
            # warn "SUCCEEDED";
            $self->run_with( $key );
            last;
          }
        }

      }

    });

  };

}

sub _error {
  my ( $self, $message ) = @_;

  $self->decrement;

  $self->handle->destroy 
    if $self->handle;

  my $error = $self->error || sub { warn @_ };

  ( $self->error || sub { warn @_ } )->( $message );

}

sub _success {
  my $self = shift;

  $self->decrement;

  # pass the object
  ( $self->success || sub { } )->( $self );

}


sub _get_configuration {
  my $self = shift;

  # use a specific configuration
  return Configuration->get( $self->use )
    if $self->use;

  # or just use anything available
  Configuration->any;

}


Util->create_accessors( @params );

1;
__END__
