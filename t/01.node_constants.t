use Test::Most;

use_ok( 'Tree::AA::Node::_Constants' );

diag( "Testing Tree::AA::Node::_Constants" );

foreach my $m (qw[
    _LEFT
    _RIGHT
    _LEVEL
    _KEY
    _VAL
  ])
{
    can_ok('Tree::AA::Node::_Constants', $m);
}

done_testing();
