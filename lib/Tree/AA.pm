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
*import = \&Exporter::import;
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
          $node = $self->$start_fn;
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


# Extract sentinel 'NIL' node from Tree::AA::Node
our $nil = Tree::AA::Node->nil();

sub _reset_hash_iter {
  my $self = shift;

  if ($self->[HASH_SEEK_ARG]) {
    my $iter = ($self->[HASH_SEEK_ARG]{'-reverse'} ? 'rev_iter' : 'iter');
    $self->[HASH_ITER] = $self->$iter($self->[HASH_SEEK_ARG]{'-key'});
  } else {
    $self->[HASH_ITER] = $self->iter;
  }
}

sub FIRSTKEY {
  my $self = shift;
  $self->_reset_hash_iter;

  # TODO: Return undef or sentinel node?
  my $node = $self->[HASH_ITER]->next
    or return;
  return $node->[_KEY];
}

sub NEXTKEY {
  my $self = shift;

  # TODO: Return undef or sentinel node?
  my $node = $self->[HASH_ITER]->next
    or return;
  return $node->[_KEY];
}


sub new {
  my ($class, $cmp) = @_;

  my $obj = [];
  # We haven't 'blessed' the object into Tree::AA yet, so we have to set size
  # without the accessor method
  $obj->[SIZE] = 0;
  $obj->[ROOT] = $nil;
  if ($cmp) {
    ref $cmp eq 'CODE'
      or croak('Invalid arg: coderef expected');
    $obj->[CMP] = $cmp;
  }
  return bless $obj => $class;
}

*TIEHASH = \&new;

sub DESTROY { $_[0]->[ROOT]->DESTROY if $_[0]->[ROOT] }

sub CLEAR {
  my $self = shift;

  if ($self->[ROOT]) {
    $self->[ROOT]->DESTROY;
    undef $self->[ROOT];
    undef $self->[HASH_ITER];
    $self->[SIZE] = 0;
  }
}

sub UNTIE {
  my $self = shift;
  $self->DESTROY;
  undef @$self;
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
  return undef unless $self->root != $nil;

  my $ptr = $self->root;
  while ($ptr->[_LEFT] != $nil) {
    $ptr = $ptr->[_LEFT];
  }
  return $ptr;
}

sub max {
  my $self = shift;
  return undef unless $self->root != $nil;

  my $ptr = $self->root;
  while ($ptr->[_RIGHT] != $nil) {
    $ptr = $ptr->[_RIGHT];
  }
  return $ptr;
}

sub lookup {
  my $self = shift;
  my $key  = shift;

  defined $key
    or croak("Can't use undefined value as lookup key");

  my $mode = shift || LUEQUAL;
  my $cmp  = $self->[CMP];

  my $y;
  my $x = $self->[ROOT]
    or return;

  my $next_child;

  while ($x) {
    $y = $x;
    if ($cmp ? $cmp->($key, $x->[_KEY]) == 0
             : $key eq $x->[_KEY]) {
      # Exact match!
      if ($mode == LUGREAT || $mode == LUNEXT) {
        $x = $x->successor;
      } elsif ($mode == LULESS || $mode == LUPREV) {
        $x = $x->predecessor;
      }
      return
        wantarray ? ($x->[_VAL], $x)
                  : $x->[_VAL];
    }
    if ($cmp ? $cmp->($key, $x->[_KEY]) < 0
             : $key lt $x->[_KEY]) {
      $next_child = _LEFT;
    } else {
      $next_child = _RIGHT;
    }
    $x = $x->[$next_child];
  }
  # Didn't find an exact match
  if ($mode == LUGTEQ || $mode == LUGREAT) {
    if ($next_child == _LEFT) {
      return wantarray ? ($y->[_VAL], $y) : $y->[_VAL];
    } else {
      my $next = $y->successor
        or return;
      return wantarray ? ($next->[_VAL], $next) : $next->[_VAL];
    }
  } elsif ($mode == LULTEQ || $mode == LULESS) {
    if ($next_child == _RIGHT) {
      return wantarray ? ($y->[_VAL], $y) : $y->[_VAL];
    } else {
      my $next = $->predecessor
        or return;
      return wantarray ? ($next->[_VAL], $next): $next->[_VAL];
    }
  }
  return;
}

*FETCH = \&lookup;
*get   = \&lookup;

sub nth {
  my ($self, $i) = @_;

  $i =~ /^-?\d+$/
    or croak('Integer index expected');
  if ($i < 0) {
    $i += $self->[SIZE];
  }
  if ($i < 0 | $i >= $self->[SIZE]) {
    # TODO: Do we get an undef or the sentinel node here if nothing is found?
    return;
  }

  my ($node, $next, $moves);

  if ($i > $self->[SIZE] / 2) {
    $node = $self->max;
    $next = 'predecessor';
    $moves = $self->[SIZE] - $i - 1;
  } else {
    $node = $self->min;
    $next = 'successor';
    $moves = $i;
  }

  my $count = 0;
  while ($count != $moves) {
    $node = $node->$next;
    ++$count;
  }
  # TODO: Do we get an undef or the sentinel node here if nothing is found?
  return $node;
}

sub EXISTS {
  my $self = shift;
  my $key  = shift;

  # Semantics say we get undef rather than the nil sentinel node here
  return defined $self->lookup($key);
}

sub put {
  my $self = shift;
  my $key_or_node = shift;
  defined $key_or_node
    or croak("Can't use undefined value as key or node");
  my $value = shift;

  my $cmp = $self->[CMP];
  #my $z = (ref $key_or_node eq 'Tree::AA::Node')
  #          ? $key_or_node
  #          : Tree::AA::Node->new($key_or_node => $val);
  my $key = $key_or_node;

  # Now we insert the new node

  my $root = $self->[ROOT];

  if ($root == $nil) {
    $root = $self->make_node($key, $value, 1);
  } else {
    my $it = $root;
    my @up = ();
    my ($top,$dir) = (0,undef);

    for (;;) {
      $up[$top++] = $it;
      if ($cmp) {
        if ($cmp->($it->[_KEY], $key) < 0) {
          $dir = _RIGHT;
        } elsif ($cmp->($it->[_KEY], $key) > 0) {
          $dir = _LEFT;
        } else {
          say "Inserting over existing key $key";
          return $root;
        }
      } else {
        if ($it->[_KEY] lt $key) {
          $dir = _RIGHT;
        } elsif ($it->[_KEY] gt $key) {
          $dir = _LEFT;
        } else {
          say "Inserting over existing key $key";
          return $root;
        }
      }

      if ($it->[$dir] == $nil) {
        last;
      }

      $it = $it->[$dir];
    }

    $it->[$dir] = $self->make_node($key, $value, 1);

    while (--$top >= 0) {
      if ($top != 0) {
        $dir =
          ($up[$top - 1]->[_RIGHT] == $up[$top])
          ? _RIGHT
          : _LEFT;
      }

      $up[$top] = $self->aa_skew($up[$top]);
      $up[$top] = $self->aa_split($up[$top]);

      if ($top != 0) {
        $up[$top - 1]->[$dir] = $up[$top];
      } else {
        $root = $up[$top];
      }
    }
  }

  $self->[ROOT] = $root;
  $self->[SIZE]++;
  return $root;
}

*STORE = \&put;

sub delete {
  my ($self, $key_or_node) = @_;

  defined $key_or_node
    or croak("Can't delete without a key or node to do it with");


}

*DELETE = \&delete;

sub aa_skew {
  my $self = shift;
  my $root = shift;

  if ( ($root->[_LEFT]->[_LEVEL] == $root->[_LEVEL]) &&
       $root->[_LEVEL] != 0 )
  {
    my $save = $root->[_LEFT];

    $root->[_LEFT]   = $save->[_RIGHT];
    $save->[_RIGHT]  = $root;
    $root = $save;
    $self->[ROOT] = $root;
  }
  return $root;
}

# Have to choose aa_split, because split is a reserved Perl word
sub aa_split {
  my $self = shift;
  my $root = shift;

  if (($root->[_RIGHT]->[_RIGHT]->[_LEVEL] == $root->[_LEVEL]) &&
      $root->[_LEVEL] != 0 )
  {
    my $save = $root->[_RIGHT];

    $root->[_RIGHT] = $save->[_LEFT];
    $save->[_LEFT]  = $root;
    $root = $save;
    ++$root->[_LEVEL];
    $self->[ROOT] = $root;
  }
  return $root;
}

1;
