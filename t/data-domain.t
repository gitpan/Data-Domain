#!perl

use Test::More tests => 130;
use Data::Dumper;

BEGIN {
  use_ok( 'Data::Domain', qw/:all/ );
}

diag( "Testing Data::Domain $Data::Domain::VERSION, Perl $], $^X" );

my $dom;

#----------------------------------------------------------------------
# Whatever
#----------------------------------------------------------------------
$dom = Whatever;

ok(!$dom->inspect(undef), "Whatever / undef");
ok(!$dom->inspect(1), "Whatever / 1");
ok(!$dom->inspect(0), "Whatever / 0");

$dom = Whatever(-defined => 1);
ok($dom->inspect(undef), "Whatever-defined / undef");
ok(!$dom->inspect(1), "Whatever-defined / 1");
ok(!$dom->inspect(0), "Whatever-defined / 0");

$dom = Whatever(-defined => 0);
ok(!$dom->inspect(undef), "Whatever-undefined / undef");
ok($dom->inspect(1), "Whatever-undefined / 1");
ok($dom->inspect(0), "Whatever-undefined / 0");

$dom = Whatever(-true => 1);
ok($dom->inspect(undef), "Whatever-true / undef");
ok(!$dom->inspect(1), "Whatever-true / 1");
ok($dom->inspect(0), "Whatever-true / 0");

$dom = Whatever(-true => 0);
ok(!$dom->inspect(undef), "Whatever-false / undef");
ok($dom->inspect(1), "Whatever-false / 1");
ok(!$dom->inspect(0), "Whatever-false / 0");

$dom = Whatever(-true => 1, -optional => 1);
ok(!$dom->inspect(undef), "Whatever-optional-true / undef");
ok(!$dom->inspect(1), "Whatever-optional-true / 1");
ok($dom->inspect(0), "Whatever-optional-true / 0");


$dom = Whatever(-defined => 1, -true => 0);
ok($dom->inspect(undef), "Whatever-defined-false / undef");
ok($dom->inspect(1), "Whatever-defined-false / 1");
ok(!$dom->inspect(0), "Whatever-defined-false / 0");

$dom = Whatever(-isa => "Data::Domain");
ok(!$dom->inspect($dom), "Whatever-isa / ok");

$dom = Whatever(-isa => "Foo::Bar");
ok($dom->inspect($dom), "Whatever-isa / fail");

$dom = Whatever(-can => "inspect");
ok(!$dom->inspect($dom), "Whatever-can / inspect");

$dom = Whatever(-can => [qw/inspect msg subclass/]);
ok(!$dom->inspect($dom), "Whatever-can / inspect msg subclass");

$dom = Whatever(-can => [qw/dance sing/]);
ok($dom->inspect($dom), "Whatever-can / dance sing");

#----------------------------------------------------------------------
# Num
#----------------------------------------------------------------------

$dom = Num;
ok(!$dom->inspect(-3.33), "Num / ok");
ok($dom->inspect(undef), "Num / undef");
ok($dom->inspect("foo"), "Num / string");

$dom = Num(-range => [-1, 1], -not_in => [0.5, 0.7]);
ok(!$dom->inspect(-1), "Num / bounds");
ok(!$dom->inspect(0), "Num / bounds");
ok(!$dom->inspect(1), "Num / bounds");
ok($dom->inspect(-2), "Num / bounds");
ok($dom->inspect(2), "Num / bounds");
ok($dom->inspect(0.5), "Num / excl. set");
ok($dom->inspect(0.7), "Num / excl. set");

#----------------------------------------------------------------------
# Int
#----------------------------------------------------------------------

$dom = Int;
ok(!$dom->inspect(1234), "Int / ok");
ok(!$dom->inspect(-1234), "Int / ok");
ok($dom->inspect(3.33), "Int / float");
ok($dom->inspect(undef), "Int / undef");


#----------------------------------------------------------------------
# Date
#----------------------------------------------------------------------

$dom = Date;
ok(!$dom->inspect('01.02.2003'), "Date / ok");
ok($dom->inspect('foo'), "Date / fail");
ok($dom->inspect('31.02.2003'), "Date / fail");

$dom = Date(-range => ['01.01.2001', 'today'], 
            -not_in => [qw/02.02.2002 yesterday/]);
ok($dom->inspect('01.01.1991'), "Date / bounds");
ok($dom->inspect('01.01.2991'), "Date / bounds");
ok(!$dom->inspect('01.01.2001'), "Date / bounds");
ok($dom->inspect('02.02.2002'), "Date / excl. set");


#----------------------------------------------------------------------
# Time
#----------------------------------------------------------------------
$dom = Time;
ok(!$dom->inspect('10:14'), "Time / ok");
ok($dom->inspect('foobar'), "Time / invalid");
ok($dom->inspect('25:99'), "Time / invalid");

$dom = Time(-range => ['08:00', '16:00']);
ok(!$dom->inspect('12:12'), "Time / ok bounds");
ok($dom->inspect('06:12'), "Time / bounds");
ok($dom->inspect('23:12'), "Time / bounds");



#----------------------------------------------------------------------
# String
#----------------------------------------------------------------------
$dom = String;
ok($dom->inspect(undef), "String / undef");
ok(!$dom->inspect("foo"), "String / ok");

$dom = String(qr/^(foo|bar)$/);
ok(!$dom->inspect("foo"), "String / regex");
ok(!$dom->inspect("bar"), "String / regex");
ok($dom->inspect("fail"), "String / regex");



$dom = String(-regex      => qr/^foo/,
              -antiregex  => qr/bar/,
              -length     => [5, 10],
              -range      => ['fooAB', 'foozz'],
              -not_in     => [qw/foo_foo_foo foo_foo_bar/],
             );
ok(!$dom->inspect("foo_foo"), "String / ok regex");
ok($dom->inspect("foo_bar"), "String / antiregex");
ok($dom->inspect("foo_foo_foo"), "String / excl. set");
ok($dom->inspect("foo_"), "String / too short");
ok($dom->inspect("foo_much_too_long_string"), "String / too long");
ok($dom->inspect("foo_much_too_long_string"), "String / too long");



#----------------------------------------------------------------------
# Enum
#----------------------------------------------------------------------

$dom = Enum(qw/foo bar buz/);
ok(!$dom->inspect("foo"), "Enum ok");
ok($dom->inspect("foobar"), "Enum fail");


#----------------------------------------------------------------------
# List
#----------------------------------------------------------------------

$dom = List;
ok(!$dom->inspect([]), "List ok");
ok(!$dom->inspect([1 .. 4]), "List ok");
ok($dom->inspect("foobar"), "List fail");

$dom = List(Int, Num, String(-optional => 1));
ok(!$dom->inspect([1, 2, 3]), "List items ok");
ok(!$dom->inspect([1, 2.5, "foo"]), "List items ok");
ok(!$dom->inspect([1, 2.5, "foo", "bar"]), "List items ok");
ok($dom->inspect([1.5, 2, "foo", "bar"]), "List items fail");
ok($dom->inspect([1]), "List fail");
ok($dom->inspect([]), "List fail2");
ok(!$dom->inspect([1, 2]), "List optional");
ok(!$dom->inspect([1, 2, {}]), "List wrong optional");

$dom = List(-size => [2, 5], -all => Int);
ok(!$dom->inspect([1, 2, 3]), "List ok");
ok($dom->inspect([1]), "List min_size");
ok($dom->inspect([1 .. 6]), "List max_size");
ok($dom->inspect([1, 2, 3, "foo"]), "List not all");

$dom = List(-size => [2, 5], -any => Int);
ok(!$dom->inspect([1, 2, 3]), "List ok");
ok($dom->inspect([qw/foo bar buz/]), "List not any");
ok(!$dom->inspect([qw/foo bar buz/, 3]), "List any");


$dom = List(-items => [String, Num], 
            -any => Int);
ok($dom->inspect(['foo', 2]), "List + items not any");
ok(!$dom->inspect(['foo', 2, 3]), "List + items any 1");
ok(!$dom->inspect(['foo', 2, 'foo', 'bar', 3]), "List + items any 2");

$dom = List(-items => [String, Num], 
            -any => [String(qr/^foo/), Int(-range => [1, 10])]);
ok($dom->inspect(['foo', 2, undef, 'foobar']), "List 2 anys nok 1");
ok($dom->inspect(['foo', 2, 3, 'bar', 'bie']), "List 2 anys nok 2");
ok(!$dom->inspect(['foo', 2, 3, 'foobar']), "List 2 anys ok 1");
ok(!$dom->inspect(['foo', 2, undef, 3, 'foobar']), "List 2 anys ok 2");


#----------------------------------------------------------------------
# Struct
#----------------------------------------------------------------------

$dom = Struct;
ok(!$dom->inspect({}), "Struct ok");
ok($dom->inspect([]), "Struct fail list");
ok($dom->inspect(undef), "Struct fail undef");
ok($dom->inspect(123), "Struct fail scalar");

$dom = Struct(int => Int, str => String, num => Num(-optional => 1));
ok(!$dom->inspect({int => 3, str => "foo"}), "Struct ok");
ok(!$dom->inspect({int => 3, str => "foo", bar => 123}), "Struct more fields");
ok(!$dom->inspect({int => 3, str => "foo", num => 123}), "Struct ok num");
ok($dom->inspect({int => "foo", str => 3, num => 123}), "Struct fail");

$dom = Struct(-exclude => [qw/foo bar/], int => Int);
ok(!$dom->inspect({int => 3, foobar => 4}), "Struct foobar");
ok($dom->inspect({int => 3, foo => 4}), "Struct foo");

$dom = Struct(-fields => [int => Int], 
              -exclude => qr/foo|bar/);
ok($dom->inspect({int => 3, foobar => 4}), "Struct foobar");
ok($dom->inspect({int => 3, foo => 4}), "Struct foo");
ok(!$dom->inspect({int => 3, other => 4}), "Struct other");

$dom = Struct(-fields => {int => Int}, 
              -exclude => '*');
ok(!$dom->inspect({int => 3}), "Struct ok");
ok($dom->inspect({int => 3, foobar => 4}), "Struct foobar");
ok($dom->inspect({int => 3, foo => 4}), "Struct foo");
ok($dom->inspect({int => 3, other => 4}), "Struct other");

#----------------------------------------------------------------------
# One_of
#----------------------------------------------------------------------

$dom = One_of(String(qr/^[AEIOU]/), Int(-min => 0));
ok(!$dom->inspect("Alleluia"), "One_of ok1");
ok(!$dom->inspect(1234), "One_of ok2");
ok($dom->inspect("hello, world"), "One_of fail string");
ok($dom->inspect(undef), "One_of fail undef");
ok($dom->inspect(-789), "One_of fail neg. num");


#----------------------------------------------------------------------
# context and lazy constructors
#----------------------------------------------------------------------

$dom = Struct(
  d_begin => Date,
  d_end   => sub {my $context = shift;
                  Date(-min => $context->{flat}{date_begin})},
 );

ok(!$dom->inspect({d_begin => '01.01.2001', 
                   d_end   => '02.02.2002'}), "Dates order ok");

ok(!$dom->inspect({d_begin => '03.03.2003', 
                   d_end   => '02.02.2002'}), "Dates order fail");


sub clone { # can't remember which CPAN module implements cloning
  my $node = shift;
  for (ref $node) {
    /ARRAY/ and return [map {clone($_)} @$node];
    /HASH/  and do { my $r = {};
                     $r->{$_} = clone($node->{$_}) foreach keys %$node;
                     return $r; };
    /^$/    and return $node;
    die "cloning incorrect data";
  }
}

my $context;
$dom = Struct(
     foo => List(Whatever, 
                 Whatever, 
                 Struct(bar => sub {$context = clone(shift); String;})
                )
     );
my $data   = {foo => [undef, 99, {bar => "hello, world"}]};
$dom->inspect($data);

my $proof_context  = {
    root => {foo => [undef, 99, {bar => 'hello, world'}]},
    path => ['foo', 2, 'bar'],
    flat => { bar => 'hello, world'},
  };
$proof_context->{flat}{foo} 
  = $proof_context->{list} 
  = $proof_context->{root}{foo};
is_deeply($context, $proof_context, "context");


my $some_cities = {
   Switzerland => [qw/Gen�ve Lausanne Bern Zurich Bellinzona/],
   France      => [qw/Paris Lyon Marseille Lille Strasbourg/],
   Italy       => [qw/Milano Genova Livorno Roma Venezia/],
};
$dom = Struct(
   country => Enum(keys %$some_cities),
   city    => sub {
      my $context = shift;
      Enum(-values => $some_cities->{$context->{flat}{country}});
    });

ok(!$dom->inspect({country => 'Switzerland', city => 'Gen�ve'}), "city ok");
ok($dom->inspect({country => 'France', city => 'Gen�ve'}), "city fail");


$dom = List(-all => sub {
      my $context = shift;
      my $index = $context->{path}[-1];
      return Int if $index == 0; # first item has no constraint
      return Int(-min => $context->{list}[$index-1] + 1);
    });
ok(!$dom->inspect([1, 2, 3, 5, 7, 11, 13]), "order ok");
ok($dom->inspect([1, 2, 5, 3, 7, 11, 13]), "order fail");



$dom = One_of(Num, Struct(op    => String(qr(^[-+*/]$)),
                          left  => sub {$dom},
                          right => sub {$dom}));
ok(!$dom->inspect({
  op => '*', 
  left => {op => '+', left => 4, right => 5},
  right => 9
 }), "recursive ok");

ok($dom->inspect({
  op => '*', 
  left => {op => '+', left => 4, right => 5},
  right => {}
 }), "recursive fail");





#----------------------------------------------------------------------
# messages
#----------------------------------------------------------------------


Data::Domain->messages("fran�ais");

$dom = Int;
my $msg = $dom->inspect("foobar");
is($msg, "Int: nombre incorrect", "msg fran�ais");

$dom = Int(-name => "PositiveInt", -min => 0);
$msg = $dom->inspect("foobar");
is($msg, "PositiveInt: nombre incorrect", "msg fran�ais");


$dom = Int(-messages => "fix that number");
$msg = $dom->inspect("foobar");
is($msg, "Int: fix that number", "msg string");


$dom = Int(-min => 4, 
           -max => 5,
           -messages => {TOO_SMALL => "too small", 
                         TOO_BIG => "too big"}); 
$msg = $dom->inspect(99);
is($msg, "Int: too big", "msg direct");

$dom = Int(-min => 4, 
           -max => 5,
           -messages => sub {"got an error ($_[0])"});
$msg = $dom->inspect(99);
is($msg, "got an error (TOO_BIG)", "msg sub");

Data::Domain->messages(sub {"validation error ($_[0])"});
$dom = Int(-min => 0);
$msg = $dom->inspect(-99);
is($msg, "validation error (TOO_SMALL)", "msg global sub");



#----------------------------------------------------------------------
# examples from doc
#----------------------------------------------------------------------

sub Phone   { String(-regex => qr/^\+?[0-9() ]+$/, @_) }
sub Email   { String(-regex => qr/^[-.\w]+\@[\w.]+$/, @_) }
sub Contact { Struct(-fields => [name   => String,
                                 phone  => Phone,
                                 mobile => Phone(-optional => 1),
                                 emails => List(-all => Email)], @_) }

$msg = Contact->inspect({name => "Foo", 
                         phone => 12345,
                         emails => ['foo.bar@foo.com']});

ok(!$msg, "contact OK");




