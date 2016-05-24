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

# Create sentinel nil node with accessor
{
  my $obj = [];
  $obj->[_RIGHT] = $obj;
  $obj->[_LEFT]  = $obj;
  $obj->[_LEVEL] = 0;
  bless $obj, __PACKAGE__;

  # Our accessor
  sub nil {
    shift;   # Intentionally ignore invocant
    return $obj;
  }
}

sub min {
  my $self = shift;
  while ($self->[_LEFT] != nil()) {
    $self = $self->[_LEFT];
  }
  return $self;
}

sub max {
  my $self = shift;
  while ($self->[_RIGHT] != nil()) {
    $self = $self->[_RIGHT];
  }
  return $self;
}

sub leaf {
  my $self = shift;

  while (my $any_child = $self->[_LEFT] || $self->[_RIGHT]) {
    $self = $any_child;
  }
  return $self;
}

sub successor {
  my $self = shift;

  if ($self->[_RIGHT] != nil()) {
    return $self->[_RIGHT]->min;
  }
}

sub predecessor {
  my $self = shift;

  if ($self->[_LEFT]) {
    return $self->[_LEFT]->max;
  }
}

1;
