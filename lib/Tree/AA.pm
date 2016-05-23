package Tree::AA;

use strict;
use warnings;
use v5.20;

use Tree::AA::Node;
use Tree::AA::Node::_Constants;

# VERSION

# use Moose;
# use MooseX::ClassAttribute;
# use namespace::autoclean;
# 
# class_has 'nil' => (
#   is        => 'ro',
#   isa       => 'Tree::AA',
#   lazy      => 1,
#   builder   => '_build_nil',
# );
# 
# 
# has 'data' => (
#   is        => 'rw',
#   isa       => 'Any',
#   default   => undef,
# );
# 
# has 'left' => (
#   is        => 'rw',
#   isa       => 'Tree::AA',
#   predicate => 'has_left',
#   lazy      => 1,
#   default   => sub { Tree::AA->new( $_[0] ) },
#   #trigger   => \&set_something,
# );
# 
# has 'right' => (
#   is        => 'rw',
#   isa       => 'Tree::AA',
#   predicate => 'has_right',
#   lazy      => 1,
#   default   => sub { Tree::AA->new( $_[0] ) },
#   #trigger   => \&set_something,
# );
# 
# has 'level' => (
#   is        => 'rw',
#   isa       => 'Int',
#   default   => 1,
# );
# 
# 
# sub _build_nil {
#   my $nil =
#     Tree::AA->new( level => 0 );
#   $nil->left( $nil );
#   $nil->right( $nil );
#   return $nil;
# }
# 
# sub insert {
#   my ($self, $data) = @_;
#   my ($root);
#   my ($nil) = Tree::AA->nil;
# 
#   if ($self eq $nil) {
#     $root = Tree::AA->new( data  => $data,
#                            level => 1,
#                          );
#   } else {
#     $root = $self;
#   }
# 
#   my $it = $root;
#   my (@up, $top, $dir) = ((), 0, undef);
# 
#   while (1) {
#     $up[$top++] = $it;
#     $dir = $it->data < $data ? "left" : "right";
# 
#     if ($it->$dir eq $nil) {
#       last;
#     }
# 
#     $it = $it->$dir;
#   }
# 
#   $it->$dir(Tree::AA->new( data => $data, level => 1, ));
# 
#   while (--$top >= 0) {
#     if ($top != 0) {
#       $dir = ($up[$top - 1]->right == $up[$top]) ? "left" : "right";
#     }
# 
#     $up[$top] = $self->skew($up[$top]);
#     $up[$top] = $self->split($up[$top]);
# 
#     if ($top != 0) {
#       $up[$top - 1]->$dir($up[$top]);
#     } else {
#       $root = $up[$top];
#     }
#   }
# 
#   return $root;
# }

use vars qw( @EXPORT_OK );

require Exporter;
*import = &Exporter::import;
@EXPORT_OK = qw[ LUEQUAL LUGTEQ LULTEQ LUGREAT LULESS LUNEXT LUPREV ];

use enum qw{
  LUEQUAL
  LUGTEQ
  LULTEQ
  LUGREAT
  LULESS
  LUNEXT
  LUPREV
};

# Object slots
use enum qw{
  ROOT
  CMP
  SIZE
  HASH_ITER
  HASH_SEEK_ARG
};

# Node and hash Iteration
sub _mk_iter {
  my $start_fn = shift || 'min';
  my $next_fn  = shift || 'successor';

  return sub {
    my $self = shift;
    my $key  = shift;
    my $node;
    my $iter = sub {
      if ($node) {
        $node = $node->$next_fn;
      } else {
        if (defined $key) {
          # seek to $key
          (undef, $node) = $self->lookup(
            $key,
            $next_fn eq 'successor' ? LUGTEQ : LULTEQ
          );
        } else {
          $node = $self->start_fn;
        }
      }
      return $node;
    };
    return bless($iter => 'Tree::AA::Iterator');
  };
}

*Tree::AA::Iterator::next = sub { $_[0]->() };

*iter     = _mk_iter(qw/min successor/);
*rev_iter = _mk_iter(qw/max predecessor/);


# Create magical 'NIL' node
my $nil = Tree::AA::Node->new();
$nil->level(0);
$nil->left($nil);
$nil->right($nil);

sub new {
  my ($class, $cmp) = @_;

  my $obj = [];
  # We haven't 'blessed' the object into Tree::AA yet, so we have to set size
  # the hard way
  $obj->[SIZE] = 0;
  if ($cmp) {
    ref $cmp eq 'CODE'
      or croak('Invalid arg: coderef expected');
    $obj->[CMP] = $cmp;
  }
  return bless $obj => $class;
}

sub make_node {
  my $self  = shift;
  my $key   = shift;
  my $value = shift;
  my $level = shift;

  my $rn = Tree::AA::Node->new($key, $value);
  $rn->level($level);
  $rn->left($nil);
  $rn->right($nil);

  return $rn;
}


sub root { $_[0]->[ROOT] }
sub size { $_[0]->[SIZE] }
 
*SCALAR = \&size;
 
sub min {
    my $self = shift;
    return undef unless $self->[ROOT];
    return $self->[ROOT]->min;
}
 
sub max {
    my $self = shift;
    return undef unless $self->[ROOT];
    return $self->[ROOT]->max;
}


sub skew {
  my $self = shift;
  my $root = shift;

  if ( ($root->[_LEFT]->[_LEVEL] == $root->[_LEVEL]) &&
       $root->[_LEVEL] != 0 )
  {
    my $save = $root->[_RIGHT];

    $root->[_RIGHT] = $save->[_LEFT];
    $save->[_LEFT]  = $root;
    $root = $save;
    $root->[_LEVEL]++;
  }
  return $root;
}

sub split {
  my $self = shift;
  my $root = shift;

  if (($root->[_RIGHT]->[_RIGHT]->[_LEVEL] == $root->[_LEVEL]) &&
      $root->[_LEVEL] != 0 )
  {
    my $save = $root->[_RIGHT];

    $root->[_RIGHT] = $save->[_LEFT];
    $save->[_LEFT]  = $root;
    $root = $save;
    $root->[_LEVEL]++;
  }
  return $root;
}

1;
