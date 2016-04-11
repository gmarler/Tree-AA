package Tree::AA;

use strict;
use warnings;
use v5.20;

use Moose;
use MooseX::ClassAttribute;
use namespace::autoclean;

class_has 'nil' => (
  is        => 'ro',
  isa       => 'Tree::AA',
  lazy      => 1,
  builder   => '_build_nil',
);


has 'data' => (
  is        => 'rw',
  isa       => 'Any',
  default   => undef,
);

has 'left' => (
  is        => 'rw',
  isa       => 'Tree::AA',
  predicate => 'has_left',
  lazy      => 1,
  default   => sub { Tree::AA->new( $_[0] ) },
  #trigger   => \&set_something,
);

has 'right' => (
  is        => 'rw',
  isa       => 'Tree::AA',
  predicate => 'has_right',
  lazy      => 1,
  default   => sub { Tree::AA->new( $_[0] ) },
  #trigger   => \&set_something,
);

has 'level' => (
  is        => 'rw',
  isa       => 'Int',
  default   => 1,
);


sub _build_nil {
  my $nil =
    Tree::AA->new( level => 0 );
  $nil->left( $nil );
  $nil->right( $nil );
  return $nil;
}

sub insert {
  my ($self, $data) = @_;
  my ($root);
  my ($nil) = Tree::AA->nil;

  if ($self eq $nil) {
    $root = Tree::AA->new( data  => $data,
                           level => 1,
                         );
  } else {
    $root = $self;
  }

  my $it = $root;
  my (@up, $top, $dir) = ((), 0, undef);

  while (1) {
    $up[$top++] = $it;
    $dir = $it->data < $data ? "left" : "right";

    if ($it->$dir eq $nil) {
      last;
    }

    $it = $it->$dir;
  }

  $it->$dir(Tree::AA->new( data => $data, level => 1, ));

  while (--$top >= 0) {
    if ($top != 0) {
      $dir = ($up[$top - 1]->right == $up[$top]) ? "left" : "right";
    }

    $up[$top] = $self->skew($up[$top]);
    $up[$top] = $self->split($up[$top]);

    if ($top != 0) {
      $up[$top - 1]->$dir($up[$top]);
    } else {
      $root = $up[$top];
    }
  }

  return $root;
}

1;
