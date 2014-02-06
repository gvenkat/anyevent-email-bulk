use AnyEvent::Email::Bulk::Constants;

use common::sense;
use parent 'Exporter';

our @EXPORT = qw/
  START
  CONNECTION
  HELLO
  STARTTLS
  AUTH
  LOGIN
  PASSWORD
  DATA
  DATA_END
/;

use constant {
  START       => 0,
  CONNECTION  => 1,
  HELLO       => 2,
  STARTTLS     => 3,
  AUTH        => 4,
  LOGIN       => 5,
  PASSWORD    => 6,
  DATA        => 7,
  DATA_END    => 8
};


1;
__END__
