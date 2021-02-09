BEGIN {
  undef $ENV{$_} foreach (qw(EXTENDED_TESTING AUTHOR_TESTING RELEASE_TESTING PERL_STRICT));
}
use Devel::StrictMode;

use lib 't/lib';
use GQLTest;
use mro;

BAIL_OUT('STRICT mode is enabled') if STRICT;

package OtherNamespace::Foo {
  use GraphQL::Type::Object;
}

package OtherNamespace::Bar {
  use GraphQL::MaybeTypeCheck;
}

subtest 'GraphQL::MaybeTypeCheck not inherited' => sub {
  my $expected = ['OtherNamespace::Foo'];
  my @external_isa = mro::get_linear_isa($expected->[0]);

  is_deeply shift @external_isa, $expected, "External packages don't inherit GraphQL::MaybeTypeCheck";
};

subtest 'GraphQL::MaybeTypeCheck explicitly inherited' => sub {
  my $expected = ['OtherNamespace::Bar', 'GraphQL::MaybeTypeCheck'];
  my @internal_isa = mro::get_linear_isa($expected->[0]);

  is_deeply shift @internal_isa, $expected, "GraphQL packages inherit GraphQL::MaybeTypeCheck";
};

done_testing;