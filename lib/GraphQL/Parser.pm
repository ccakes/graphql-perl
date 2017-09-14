package GraphQL::Parser;

use 5.014;
use strict;
use warnings;
use base 'Pegex::Receiver';
use Return::Type;
use Types::Standard -all;
use Function::Parameters;

require Pegex::Parser;
require GraphQL::Grammar;

=head1 NAME

GraphQL::Parser - GraphQL language parser

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

  use GraphQL::Parser;
  my $parsed = GraphQL::Parser->parse(
    $source
  );

=head1 DESCRIPTION

Provides both an outside-accessible point of entry into the GraphQL
parser (see above), and a subclass of L<Pegex::Receiver> to turn Pegex
parsing events into data usable by GraphQL.

=head1 METHODS

=head2 parse

  GraphQL::Parser->parse($source, $noLocation);

=cut

method parse(Str $source, Bool $noLocation = undef) :ReturnType(HashRef) {
  my $parser = Pegex::Parser->new(
    grammar => GraphQL::Grammar->new,
    receiver => __PACKAGE__->new,
  );
  my $input = Pegex::Input->new(string => $source);
  return $parser->parse($input);
}

method gotrule (Any $param = undef) {
  return unless defined $param;
  return {$self->{parser}{rule} => $param};
}

method final (Any $param = undef) {
  return $param if defined $param;
  return {$self->{parser}{rule} => []};
}

method got_arguments (Any $param = undef) {
  return unless defined $param;
  $param = $param->[0]; # zap first useless layer
  my %args;
  for my $arg (@$param) {
    ($arg) = values %$arg; # zap useless layer
    my $name = shift @$arg;
    my $value = shift(@$arg)->{value};
    my ($value_type) = keys %$value;
    $value = $value->{$value_type};
    $args{$name} = {
      type => $value_type,
      value => $value,
    };
  }
  return {$self->{parser}{rule} => \%args};
}

method got_objectValue (Any $param = undef) {
  return unless defined $param;
  $param = $param->[0]; # zap first useless layer
  my %obj_value;
  for my $arg (@$param) {
    ($arg) = values %$arg; # zap useless layer
    my $name = shift @$arg;
    my $value = shift(@$arg)->{value};
    my ($value_type) = keys %$value;
    $value = $value->{$value_type};
    $obj_value{$name} = {
      type => $value_type,
      value => $value,
    };
  }
  return {$self->{parser}{rule} => \%obj_value};
}

method got_listValue (Any $param = undef) {
  return unless defined $param;
  $param = $param->[0]; # zap first useless layer
  my @values;
  for my $arg (@$param) {
    ($arg) = values %$arg; # zap useless layer
    my ($value_type) = keys %$arg;
    my ($value) = values %$arg;
    push @values, {
      type => $value_type,
      value => $value,
    };
  }
  return {$self->{parser}{rule} => \@values};
}

method got_directive (Any $param = undef) {
  return unless defined $param;
  my %value;
  my $arg = shift @$param;
  $value{name} = $arg;
  if ($arg = shift @$param) {
    %value = (%value, %$arg);
  }
  return {$self->{parser}{rule} => \%value};
}

method got_inputValueDefinition (Any $param = undef) {
  return unless defined $param;
  my %value;
  my $arg = shift @$param;
  $value{name} = $arg;
  while ($arg = shift @$param) {
    %value = (%value, %$arg);
  }
  return {$self->{parser}{rule} => \%value};
}

method got_directiveLocations (Any $param = undef) {
  return unless defined $param;
  return {$self->{parser}{rule} => $param};
}

method got_name (Any $param = undef) {
  return unless defined $param;
  return $param;
}

method got_namedType (Any $param = undef) {
  return unless defined $param;
  return $param;
}

method got_scalarTypeDefinition (Any $param = undef) {
  return unless defined $param;
  my %value;
  my $arg = shift @$param;
  $value{name} = $arg;
  while ($arg = shift @$param) {
    %value = (%value, %$arg);
  }
  return {$self->{parser}{rule} => \%value};
}

method got_enumValueDefinition (Any $param = undef) {
  return unless defined $param;
  my %value;
  my $arg = shift @$param;
  $value{value} = $arg;
  while ($arg = shift @$param) {
    %value = (%value, %$arg);
  }
  return {$self->{parser}{rule} => \%value};
}

method got_defaultValue (Any $param = undef) {
  return unless defined $param;
  ($param) = values %{$param->[0]}; # zap useless layers
  my ($value_type) = keys %$param;
  return {$self->{parser}{rule} => { type => $value_type, default_value => $param->{$value_type} }};
}

1;
