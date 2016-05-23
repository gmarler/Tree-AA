use strict;
use warnings;
package Tree::AA::Node::_Constants;

use Carp;
use vars qw( @EXPORT );

# VERSION

require Exporter;
*import = \&Exporter::import;

my @Node_slots;

BEGIN {
  @Node_slots = qw( LEFT RIGHT LEVEL KEY VAL );
}

@EXPORT = (map {"_$_"} @Node_slots);

use enum @Node_slots;

# enum does'nt allow symbols to start with "_", but we want them
foreach my $s (@Node_slots) {
  no strict 'refs';
  *{"_$s"} = \&$s;
  delete $Tree::AA::Node::_Constants::{$s};
}

1;
