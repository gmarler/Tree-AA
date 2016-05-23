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

done_testing();
