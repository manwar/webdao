# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More (no_plan);
use Data::Dumper;
use strict;
BEGIN { use_ok('HTML::WebDAO') }
BEGIN { use_ok('HTML::WebDAO::Engine') }
BEGIN { use_ok('HTML::WebDAO::Store::MLDBM') }
BEGIN { use_ok('HTML::WebDAO::Container') }
BEGIN { use_ok('HTML::WebDAO::SessionSH') }
BEGIN { use lib 'contrib';use_ok('TestWDAO') }

my $ID       = "tcontainer";
my $store_ml = new HTML::WebDAO::Store::MLDBM:: path => 'tmp';
my $session  = new HTML::WebDAO::SessionSH:: store=>$store_ml;
$session->U_id($ID);
my $test_class = 'TestWDAO';
my $test_alias = "testclass";
my $eng        = new HTML::WebDAO::Engine::
  session  => $session,
  register => { $test_class => $test_alias, 'HTML::WebDAO::Container'=>'contaner'};
my $telement = $eng->_createObj( "t1", $test_alias );
ok( $telement, "Create test1 object" );
ok( $telement->_obj_name eq 't1', " test obj name" );
$eng->_add_childs($telement);
$telement->_sess2(6);

my $obj_by_name = $eng->_get_obj_by_name('t1');
ok( $obj_by_name, "test get obj by name" );
ok( $telement->_obj_name eq $obj_by_name->_obj_name, " test eq obj name" );
my $tcontainer = $eng->_createObj('c1','contaner');
ok( $tcontainer, "test create container" );
my $t2 = $eng->_createObj( "t2", $test_alias );
ok( $t2, "Create test2 object" );
$tcontainer->_add_childs($t2);
$eng->_add_childs($tcontainer);
ok (@{$eng->_get_childs} == 2, 'Test count of inserted');
my $t3 = $eng->_createObj( "t3", $test_alias );
ok( $t3, "Create test3 object" );
$tcontainer->_add_childs($t3);
$eng->_destroy;
$session->flush_session;

my $store_ml1 = new HTML::WebDAO::Store::MLDBM:: path => 'tmp';
my $session1  = new HTML::WebDAO::SessionSH:: store=>$store_ml1;
$session1->U_id($ID);
my $eng1        = new HTML::WebDAO::Engine::
  session  => $session1,
  register => { $test_class => $test_alias, 'HTML::WebDAO::Container'=>'contaner'};
my $telement_ = $eng1->_createObj( "t1", $test_alias );
ok( $telement_, "Create test1 object" );
ok( $telement_->_obj_name eq 't1', " test obj name" );
$eng1->_add_childs($telement_);
ok( $telement_->_sess2 == 6, "test restore attr");


#print Dumper($eng->__obj);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

