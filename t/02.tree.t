use Test::Most;

use strict;
use warnings;
use Data::Dumper;

use_ok( 'Tree::AA' );

diag( "Testing Tree::AA" );

#   put
#
foreach my $m (qw[
    new
    iter
    rev_iter
    size
  ])
{
    can_ok('Tree::AA', $m);
}

my $tree = Tree::AA->new;
isa_ok($tree, 'Tree::AA');
ok($tree->size == 0, 'New tree has size zero');

$tree->put('France'  => 'Paris');
$tree->put('England' => 'London');
$tree->put('Hungary' => 'Budapest');
$tree->put('Ireland' => 'Dublin');
$tree->put('Egypt'   => 'Cairo');
$tree->put('Germany' => 'Berlin');

ok($tree->size == 6, 'size check after inserts');

is($tree->min->key, 'Egypt', 'min');
is($tree->max->key, 'Ireland', 'max');

# Iterator tests
my $it;
$it = $tree->iter;
isa_ok($it, 'Tree::AA::Iterator');
can_ok($it, 'next');

my @iter_tests = (
  sub {
    my $node = $_[0]->next;
    ok($node->key eq 'Egypt' && $node->val eq 'Cairo', 'iterator check');
  },
  sub {
    my $node = $_[0]->next;
    ok($node->key eq 'England' && $node->val eq 'London', 'iterator check');
  },
  sub {
    my $node = $_[0]->next;
    ok($node->key eq 'France' && $node->val eq 'Paris', 'iterator check');
  },
 sub {
   my $node = $_[0]->next;
   ok($node->key eq 'Germany' && $node->val eq 'Berlin', 'iterator check');
 },
 sub {
   my $node = $_[0]->next;
   ok($node->key eq 'Hungary' && $node->val eq 'Budapest', 'iterator check');
 },
 sub {
   my $node = $_[0]->next;
   ok($node->key eq 'Ireland' && $node->val eq 'Dublin', 'iterator check');
 },
 sub {
   my $node = $_[0]->next;
   ok(!defined $node, 'iterator check - no more items');
 },
);

foreach my $t (@iter_tests) {
  $t->($it);
}

done_testing();
