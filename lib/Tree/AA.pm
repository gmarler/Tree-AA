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

# Extract sentinel 'NIL' node from Tree::AA::Node
our $nil = Tree::AA::Node->nil();

# Node and hash Iteration
sub _mk_iter {
  my $start_fn = shift || 'min';
  my $next_fn  = shift || 'successor';

  my $next_coderef;

  return sub {
    my $self = shift;
    my $key  = shift;
    my $node;
    my @stack;
    my $node_tracker = $self->[ROOT];

    # TODO: Should this test for an empty tree be earlier?
    if ($node_tracker->level != 0) {
      # build the appropriate traversal stack, based on whether we are
      # iterating forwards or backwards
      while ($node_tracker->level != 0) {
        push(@stack,$node_tracker);
        if ($next_fn eq 'successor') {
          $node_tracker = $node_tracker->[_LEFT];
        } else {
          $node_tracker = $node_tracker->[_RIGHT];
        }
      }
    }

    my $successor = sub {
      my $node = scalar(@stack) ? pop @stack : undef;
      return $node if (!defined($node));
      for (my $node2 = $node->[_RIGHT];
           $node2->level != 0;
           $node2 = $node2->[_LEFT]) {
           push @stack, $node2;
      }
      return $node;
    };

    my $predecessor = sub {
      my $node = scalar(@stack) ? pop @stack : undef;
      return $node if (!defined($node));
      for (my $node2 = $node->[_LEFT];
           $node2->level != 0;
           $node2 = $node2->[_RIGHT]) {
           push @stack, $node2;
      }
      return $node;
    };

   my $iter = sub {
      if ($node) {
        # We're in the middle of an ongoing iteration
        #$node = $node->$next_fn;
        $node = $self->$next_coderef();
      } else {
        # We're just starting an iteration

        # Specify the proper coderef
        if ($next_fn eq 'successor') {
          $next_coderef = $successor;
        } else {
          $next_coderef = $predecessor;
        }
 
        if (defined $key) {
          # seek to $key and return that as the first item in the iteration
          (undef, $node) = $self->lookup(
            $key,
            $next_fn eq 'successor' ? LUGTEQ : LULTEQ
          );
        } else {
          # find the node to start the iteration with...
          #$node = $self->$start_fn;
          $node = $self->$next_coderef();
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

sub root { $_[0]->[ROOT] == $nil ? undef : $_[0]->[ROOT] }
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

  while ($x != $nil) {
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
      my $next = $y->predecessor
        or return;
      return wantarray ? ($next->[_VAL], $next): $next->[_VAL];
    }
  }
  return;  # undef
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
  if ($i < 0 || $i >= $self->[SIZE]) {
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
    $root = Tree::AA::Node->new($key, $value, 1);
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

    $it->[$dir] = Tree::AA::Node->new($key, $value, 1);

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

*STORE    = \&put;
*insert   = \&lookup;

sub delete {
  my ($self, $key_or_node) = @_;

  defined $key_or_node
    or croak("Can't delete without a key or node to do it with");


}

*DELETE = \&delete;
*remove = \&delete;

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
__END__

=head1 NAME

Tree::AA - Perl implementation of the AA tree, a type of auto-balancing binary search tree.

=head1 SYNOPSIS

  use Tree::AA;

  # By default, this tree compares nodes lexically/asciibetically
  my $tree = Tree::AA->new;
  $tree->put('France'  => 'Paris');
  $tree->put('England' => 'London');
  $tree->put('Hungary' => 'Budapest');
  $tree->put('Ireland' => 'Dublin');
  $tree->put('Egypt'   => 'Cairo');
  $tree->put('Germany' => 'Berlin');

  $tree->put('Alaska' => 'Anchorage'); # D'oh! Alaska isn't a Country
  $tree->delete('Alaska');

  print scalar $tree->get('Ireland'); # 'Dublin'

  print $tree->size; # 6
  print $tree->min->key; # 'Egypt' 
  print $tree->max->key; # 'Ireland' 

  print $tree->nth(0)->key;  # 'Egypt' 
  print $tree->nth(-1)->key; # 'Ireland' 

  # print items, ordered by key
  my $it = $tree->iter;

  while(my $node = $it->next) {
      printf "key = %s, value = %s\n", $node->key, $node->val;
  }

  # print items in reverse order
  $it = $tree->rev_iter;

  while(my $node = $it->next) {
      printf "key = %s, value = %s\n", $node->key, $node->val;
  }

  # Hash interface
  tie my %capital, 'Tree::RB';

  # or do this to store items in descending order 
  tie my %capital, 'Tree::RB', sub { $_[1] cmp $_[0] };

  $capital{'France'}  = 'Paris';
  $capital{'England'} = 'London';
  $capital{'Hungary'} = 'Budapest';
  $capital{'Ireland'} = 'Dublin';
  $capital{'Egypt'}   = 'Cairo';
  $capital{'Germany'} = 'Berlin';

  # print items in order
  while(my ($key, $val) = each %capital) {
      printf "key = $key, value = $val\n";
  }

=head1 DESCRIPTION

This is a Perl implementation of the Arne Andersson, or AA tree, a type of auto-balancing binary search tree which generally has better lookup performance than a Red/Black tree.

See the Wikipedia article at L<https://en.wikipedia.org/wiki/AA_tree> for detailed information on AA Trees.

=head1 INTERFACE

=head2 new([CODEREF])

Creates and returns a new tree. If a reference to a subroutine is passed to
new(), the subroutine will be used to override the tree's default lexical
ordering and provide a user defined ordering.

This subroutine should be just like a comparator subroutine used with L<sort>,
except that it doesn't do the $a, $b trick.

For example, to get a case insensitive ordering

    my $tree = Tree::AA->new(sub { lc $_[0] cmp lc $_[1]});
    $tree->put('Wall'  => 'Larry');
    $tree->put('Smith' => 'Agent');
    $tree->put('mouse' => 'micky');
    $tree->put('duck'  => 'donald');

    my $it = $tree->iter;

    while(my $node = $it->next) {
        printf "key = %s, value = %s\n", $node->key, $node->val;
    }

=head2 size()

Returns the number of nodes in the tree.

=head2 min()

Returns the node with the minimal key.

=head2 max()

Returns the node with the maximal key.

=head2 lookup(KEY, [MODE])

When called in scalar context, lookup(KEY) returns the value
associated with KEY.

When called in list context, lookup(KEY) returns a list whose first
element is the value associated with KEY, and whose second element
is the node containing the key/value.

An optional MODE parameter can be passed to lookup() to influence
which key is returned.

The values of MODE are constants that are exported on demand by
Tree::AA

    use Tree::AA qw[LUEQUAL LUGTEQ LULTEQ LUGREAT LULESS LUNEXT LUPREV];

=over

=item LUEQUAL

This is the default mode. Returns the node exactly matching the key, or C<undef> if not found. 

=item LUGTEQ

Returns the node exactly matching the specified key, 
if this is not found then the next node that is greater than the specified key is returned.

=item LULTEQ

Returns the node exactly matching the specified key, 
if this is not found then the next node that is less than the specified key is returned.

=item LUGREAT

Returns the node that is just greater than the specified key - not equal to. 
This mode is similar to LUNEXT except that the specified key need not exist in the tree.

=item LULESS

Returns the node that is just less than the specified key - not equal to. 
This mode is similar to LUPREV except that the specified key need not exist in the tree.

=item LUNEXT

Looks for the key specified, if not found returns C<undef>. 
If the node is found returns the next node that is greater than 
the one found (or C<undef> if there is no next node). 

This can be used to step through the tree in order.

=item LUPREV

Looks for the key specified, if not found returns C<undef>. 
If the node is found returns the previous node that is less than 
the one found (or C<undef> if there is no previous node). 

This can be used to step through the tree in reverse order.

=back

=head2 get(KEY)

get() is an alias for lookup().

=head2 iter([KEY])

Returns an iterator object that can be used to traverse the tree in order.

The iterator object supports a 'next' method that returns the next node in the
tree or undef if all of the nodes have been visited.

See the synopsis for an example.

If a key is supplied, the iterator returned will traverse the tree in order starting from
the node with key greater than or equal to the specified key.

    $it = $tree->iter('France');
    my $node = $it->next;
    print $node->key; # -> 'France'

=head2 rev_iter([KEY])

Returns an iterator object that can be used to traverse the tree in reverse order.

If a key is supplied, the iterator returned will traverse the tree in order starting from
the node with key less than or equal to the specified key.

    $it = $tree->rev_iter('France');
    my $node = $it->next;
    print $node->key; # -> 'France'

    $it = $tree->rev_iter('Finland');
    my $node = $it->next;
    print $node->key; # -> 'England'

=head2 put(KEY, VALUE)

Adds a new node to the tree. 

The first argument is the key of the node, the second is its value. 

If a node with that key already exists, its value is replaced with 
the given value and the old value is returned. Otherwise, undef is returned.



=head1 DEPENDENCIES

L<enum>


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests via the GitHub web interface at 
L<https://github.com/gmarler/Tree-AA/issues>.

=head1 AUTHOR

Gordon Marler  C<< <gmarler@cpan.org> >>

Some (okay, most) of the code, tests and documentation have been borrowed from Arun Prasad's L<https://metacpan.org/pod/Tree::RB>.

=head1 ACKNOWLEDGEMENTS

Julienne Walker's AA Tree Tutorial (L<http://www.eternallyconfuzzled.com/tuts/datastructures/jsw_tut_andersson.aspx>).

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2016, Gordon Marler C<< <gmarler@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
