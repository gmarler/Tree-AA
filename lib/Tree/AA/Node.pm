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

sub min {
  my $self = shift;
  while ($self->[_LEFT]) {
    $self = $self->[_LEFT];
  }
  return $self;
}

sub max {
  my $self = shift;
  while ($self->[_RIGHT]) {
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

  if ($self->[_RIGHT]) {
    return $self->[_RIGHT]->min;
  }

}

1;
