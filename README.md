```perl

  # configure smtp
  configure_for mailgun => {
    host      => 'smtp.mailgun.org',
    port      => 25,
    username  => '<<username>>',
    password  => '<<password>>'
  };

  # can configure other smtp servers too
  # make sure you label them, so you can decide 
  # to use one them later on
  configure_for amazon => {
    host => 'email-smtp.us-east-1.amazonaws.com',
    port => 25,
    username => '<<username>>',
    password => '<<password>>',
    starttls => 1
  };


  email
    use     => 'amazon',
    from    => 'foo@bar.com',
    to      => 'moo@bar.com',
    data    => "Some email data",

    success => sub { 
      # on success callback
    },

    error   => sub { 
      # failure callback
    };


  # make as many email calls as you want
  # and call done to wait until all emails
  # are sent out, this returns 
  done;

```
