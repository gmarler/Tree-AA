# NOTE: TF stands for TestsFor::...
package TF::Tree::AA;

use File::Temp          qw();
use Data::Dumper        qw();
use Assert::Conditional qw();
use boolean;
# Possible alternative assertion methodology
# use Devel::Assert     qw();

use Test::Class::Moose;
with 'Test::Class::Moose::Role::AutoUse';


sub test_startup {
  my ($test, $report) = @_;
  $test->next::method;

  # Log::Log4perl configuration in a string ...
# my $log_conf = q(
#   logperl.rootLogger              = DEBUG, Screen

#   log4perl.Appender.Screen        = Log::Log4perl::Appender::Screen
#   log4perl.Appender.Screen.stderr = 0
#   log4perl.Appender.Screen.layout = Log::Log4perl::Layout::SimpleLayout
# );

# # ... passed as a reference to init()
# Log::Log4perl::init( \$log_conf );
}

sub test_setup {
  my $test = shift;
  my $test_method = $test->test_report->current_method;

  if ( 'test_without_priv' eq $test_method->name ) {
      $test->test_skip("Need to handle failure in non-privileged case");
  }
}

sub test_load {
  my $test = shift;

  use_ok($test->test_class);
}

sub test_nil {
  my $test = shift;

  use_ok($test->class_name);

  my $root = $test->class_name->new();

  my $nil = $test->class_name->nil;

  cmp_ok($root->nil, 'eq', $nil,
         'Class nil object should be identical between instances and class');
}

