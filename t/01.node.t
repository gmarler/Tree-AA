use Test::Most;

use_ok( 'Tree::AA::Node');

diag ("Testing Tree::AA::Node");

foreach my $m (
  qw[
      new
      nil
      key
      val
      level
      left
      right
      min
      max
    ])
{
  can_ok('Tree::AA::Node', $m);
}

my $node = Tree::AA::Node->new( 'England' => 'London' );

#    [ England : London ]

isa_ok($node, 'Tree::AA::Node');
is($node->key, 'England', 'key retrieved after new');
is($node->val, 'London',  'value retrieved after new');
 
$node->key('France');
 
#    [France: London]
 
is($node->key, 'France', 'key retrieved after set');
 
$node->val('Paris');
 
#    [France: Paris]
 
is($node->val, 'Paris', 'value retrieved after set');
 
$node->level(1);
is($node->level, 1, 'level retrieved after set');

done_testing();
