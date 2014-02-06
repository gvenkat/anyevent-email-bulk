package AnyEvent::Email::Bulk::Util;

use common::sense;
use Carp qw( croak confess );
use Data::Dumper;

sub as_hash {
  my $class = shift;
  my @args = @_;

  if( @args == 1 && ref( $args[ 0 ] ) eq 'HASH' ) {
    # copy the HASHREF and return
    # and new HASHREF
    +{ %{ $_[0 ] } };
  }

  elsif( @args % 2 == 0 ) {
    +{ @args };
  }

  else {
    croak "Expected HASH or HASHREF, Recieved odd number of arguments";
  }

}

sub debug {
  my $class = shift;

  # warn Dumper \@_

}

sub create_accessors {
  # ignore class
  shift;

  my @params = @_;
  my $caller = caller;

  {
    no strict 'refs';
    no warnings 'redefine';

    for my $param ( @params ) {

      *{ "${caller}::$param"} = sub {
        my ( $self, $value ) = @_;

        $self->{ $param } = $value if $value;

        $self->{ $param };
      };

    }

  }


}



1;
__END__
