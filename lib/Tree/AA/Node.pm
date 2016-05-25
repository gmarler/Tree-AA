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

sub strip {
  my $self     = shift;
  my $callback = shift;

  undef $self->[_LEFT];
  undef $self->[_RIGHT];
  #my @stack;
  #my $trav = $self;
  #while ($trav != nil()) {
  #  push @stack, $trav;
  #  $trav = $trav->[_LEFT];
  #}

  #while (my $node = pop @stack) {
  #  my $result = $node;
  #  if ($node->[_RIGHT] != nil()) {
  #    $node = $node->[_RIGHT];
  #    while ($node != nil()) {
  #      push @stack, $node;
  #      $node = $node->[_LEFT];
  #    }
  #  }
  #  my $leaf = $result->leaf;
  #  # detach $leaf from the (sub)tree
  #  no warnings "uninitialized";
  #  if ($leaf == $result->[_LEFT]) {
  #    undef $result->[_LEFT];
  #  } else {
  #    undef $result->[_RIGHT];
  #  }

  #  if ($callback) {
  #    $callback->($leaf);
  #  }

  #}
}

sub DESTROY { $_[0]->strip; }

1;
