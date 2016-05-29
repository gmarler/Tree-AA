use Test::Most;

use strict;
use warnings;
use Data::Dumper;

use_ok( 'Tree::AA' );

diag( "Testing Tree::AA" );

#
foreach my $m (qw[
    new
    root
    put
    insert
    delete
    remove
    lookup
    iter
    rev_iter
    size
    min
    max
    nth
  ])
{
    can_ok('Tree::AA', $m);
}

my $tree = Tree::AA->new;
isa_ok($tree, 'Tree::AA');
ok($tree->size == 0, 'New tree has size zero');
# Make sure root() method returns undef for a tree with no nodes
is($tree->root(), undef, 'Empty tree as an undef root, as expected');

$tree->put('France'  => 'Paris');
$tree->put('England' => 'London');
$tree->put('Hungary' => 'Budapest');
$tree->put('Ireland' => 'Dublin');
$tree->put('Egypt'   => 'Cairo');
$tree->put('Germany' => 'Berlin');

ok($tree->size == 6, 'size check after inserts');

is($tree->min->key, 'Egypt', 'min');
is($tree->max->key, 'Ireland', 'max');

#
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

# Reverse iterator tests
$it = $tree->rev_iter;
isa_ok($it, 'Tree::AA::Iterator');
can_ok($it, 'next');

my @rev_iter_tests = (reverse(@iter_tests[0 .. $#iter_tests-1]), $iter_tests[-1]);

foreach my $t (@rev_iter_tests) {
    $t->($it);
}

# seeking
my $node;
$it = $tree->iter('France');
$node = $it->next;
is($node->key, 'France', 'seek check, key exists');

$it = $tree->iter('Iceland');
$node = $it->next;
is($node->key, 'Ireland', 'seek check, key does not exist but is lt max key');

$it = $tree->iter('Timbuktu');
$node = $it->next;
ok(!defined $node, 'seek check, non existent key gt all keys')
  or diag(Dumper($node));

# seeking in reverse
$it = $tree->rev_iter('Hungary');
$node = $it->next;
is($node->key, 'Hungary', 'reverse seek check, key exists');
$node = $it->next;
is($node->key, 'Germany', 'reverse seek check, next key lt this one');

$it = $tree->rev_iter('Finland');
$node = $it->next;
is($node->key, 'England', 'reverse seek check, key does not exist but is gt min key');

$it = $tree->rev_iter('Albania');
$node = $it->next;
ok(!defined $node, 'reverse seek check, non existant key lt all keys');

$tree->put('Timbuktu' => '');
is($tree->get('Timbuktu'), '', 'False values can be stored');

# A Tree with a numeric comparison
$tree = Tree::AA->new(
  sub {
    my ($i, $j) = @_;
    if ($i < $j)  { return -1 }
    if ($i == $j) { return  0 }
    if ($i > $j)  { return  1 }
  }
);

$tree->put(0 => 0);
$tree->put(1 => 1);
$tree->put(2 => 2);
$tree->put(3 => 3);
$tree->put(4 => 4);
$tree->put(5 => 5);

ok($tree->size == 6, 'size check after inserts');

$it = $tree->iter;
isa_ok($it, 'Tree::AA::Iterator');
can_ok($it, 'next');

my @numeric_iter_tests = (
  sub {
    my $node = $_[0]->next;
    ok($node->key == 0 && $node->val == 0, 'numeric iterator check');
  },
  sub {
    my $node = $_[0]->next;
    ok($node->key == 1 && $node->val == 1, 'numeric iterator check');
  },
  sub {
    my $node = $_[0]->next;
    ok($node->key == 2 && $node->val == 2, 'numeric iterator check');
  },
 sub {
   my $node = $_[0]->next;
   ok($node->key == 3 && $node->val == 3, 'numeric iterator check');
 },
 sub {
   my $node = $_[0]->next;
   ok($node->key == 4 && $node->val == 4, 'numeric iterator check');
 },
 sub {
   my $node = $_[0]->next;
   ok($node->key == 5 && $node->val == 5, 'numeric iterator check');
 },
 sub {
   my $node = $_[0]->next;
   ok(!defined $node, 'numeric iterator check - no more items');
 },
);

foreach my $t (@numeric_iter_tests) {
  $t->($it);
}

# Reverse numeric iterator tests
$it = $tree->rev_iter;
isa_ok($it, 'Tree::AA::Iterator');
can_ok($it, 'next');

my @rev_numeric_iter_tests = (reverse(@numeric_iter_tests[0 .. $#numeric_iter_tests-1]), $numeric_iter_tests[-1]);

foreach my $t (@rev_numeric_iter_tests) {
  $t->($it);
}

# Larger numeric test
$tree = Tree::AA->new(
  sub {
    my ($i, $j) = @_;
    if ($i < $j)  { return -1 }
    if ($i == $j) { return  0 }
    if ($i > $j)  { return  1 }
  }
);

my (@nums,@extracted_nums);
for (my $i = 0; $i <= 5000; $i++) {
  $tree->insert($i => $i);
  push @nums, $i;
}

cmp_ok(scalar(@nums), '==', 5001, 'have 5001 items to use as keys');
cmp_ok($tree->size, '==', 5001, 'numeric tree has 5001 nodes');

$it = $tree->iter;

while (my $node = $it->next) {
  push @extracted_nums, $node->key;
}
cmp_ok(scalar(@extracted_nums), '==', 5001, 'confirm we have 5001 keys');

cmp_deeply(\@extracted_nums,
           \@nums,
           'proper numeric keys, ordered correctly in tree');
done_testing();
