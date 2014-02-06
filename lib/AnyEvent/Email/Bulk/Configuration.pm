package AnyEvent::Email::Bulk::Configuration;

use common::sense;
use Carp qw( croak confess );
use aliased 'AnyEvent::Email::Bulk::Util';

my @params = qw(
  label
  host
  port
  username
  password
  max_connections
  ssl
  starttls
);


my %configuration_pool;

sub add {
  my $class = shift;
  my $config = $class->new( @_ );

  $configuration_pool{ $config->label } = $config;
}

sub get {
  my ( $class, $label ) = @_;
  $configuration_pool{ $label } or croak( "Unable to find configuration for $label" );
}

sub any {
  my $class = shift;

  while( my ( $key, $value ) = each( %configuration_pool ) ) {
    return $value if $value;
  }

  croak "No configuration available";

}


sub new {
  my $class = shift;
  my $label = shift;

  my $self = bless Util->as_hash( @_ ), $class;

  # set the label
  $self->label( $label );

  # return the object
  $self;

}


Util->create_accessors( @params );


1;
__END__
