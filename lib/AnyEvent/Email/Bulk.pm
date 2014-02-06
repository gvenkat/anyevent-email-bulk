package AnyEvent::Email::Bulk;

use common::sense;
use parent 'Exporter';

use aliased 'AnyEvent::Email::Bulk::Configuration';
use aliased 'AnyEvent::Email::Bulk::Emailer';

our @EXPORT = qw/
  configure_for
  email
  done
/;


# configure for
sub configure_for {
  Configuration->add( @_ );
}

sub email {
  emailer( @_ )->send;
}

sub emailer {
  Emailer->new( @_ ); 
}

sub done {
  Emailer->done;
}



1;
__END__
