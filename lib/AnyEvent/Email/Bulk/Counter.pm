package AnyEvent::Email::Bulk::Counter;

use common::sense;
use AnyEvent;

my $condvar = AnyEvent->condvar;
my $email_count = 0;


sub increment {
  $email_count++;
}


sub decrement {
  $condvar->send if --$email_count == 0;
}


sub done {
  $condvar->recv;
}


1;

