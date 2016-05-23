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

done_testing();
