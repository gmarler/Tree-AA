package Tree::AA;

use strict;
use warnings;
use v5.20;

use Moose;

has 'node' => ( is => 'rw', isa => 'Any' );

has 'left' => (
  is        => 'rw',
  isa       => 'Tree::AA',
  predicate => 'has_left',
  lazy      => 1,
  default   => sub { Tree::AA->new( $_[0] ) },
  trigger   => \&set_something,
);

has 'right' => ( );

has 'level' => ( is => 'rw' );





1;
