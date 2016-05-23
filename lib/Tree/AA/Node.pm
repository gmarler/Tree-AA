use strict;
use warnings;
package Tree::AA::Node;

use v5.22;
use Carp;
use Tree::AA::Node::_Constants;

# VERSION

my %attribute = (
  key    => _KEY,
  val    => _VAL,
  level  => _LEVEL,
  left   => _LEFT,
  right  => _RIGHT,
);

sub _accessor {
  my $index = shift;

  return
    sub {
      my $self = shift;
      if (@_) {
        $self->[$index] = shift;
      }
      return $self->[$index];
    };
}

while ( my ($at, $idx) = each %attribute ) {
  no strict 'refs';
  *$at = _accessor( $idx );
}

sub new {
  my $class = shift;
  my $obj   = [];

  if (@_) {
    $obj->[_KEY] = shift;
    $obj->[_VAL] = shift;
  }
  return bless $obj, $class;
}

1;
