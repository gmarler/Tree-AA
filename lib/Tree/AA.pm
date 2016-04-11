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
  default   => sub {
                 my $nil =
                   Tree::AA->new( level => 0 );
                 $nil->left( $nil );
                 $nil->right( $nil );
                 return $nil;
               },
);

has 'node' => ( is => 'rw', isa => 'Any' );

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
  predicate => 'has_left',
  lazy      => 1,
  default   => sub { Tree::AA->new( $_[0] ) },
  #trigger   => \&set_something,
);

has 'level' => (
  is        => 'rw',
  isa       => 'Int',
  default   => 0,
);



1;
