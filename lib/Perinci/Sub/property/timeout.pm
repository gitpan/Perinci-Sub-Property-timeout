package Perinci::Sub::property::timeout;

use 5.010;
use strict;
use warnings;

use Perinci::Util qw(declare_property);

our $VERSION = '0.02'; # VERSION

declare_property(
    name => 'timeout',
    type => 'function',
    schema => ['int*' => {min=>0}],
    wrapper => {
        meta => {
            # highest, we need to disable alarm right after call
            prio    => 1,
            convert => 1,
        },
        handler => sub {
            my ($self, %args) = @_;
            my $v    = int($args{new} // $args{value} // 0);
            my $meta = $args{meta};

            return unless $v > 0;

            $self->select_section('before_call');
            $self->push_lines(
                'local $SIG{ALRM} = sub { die "Timed out\n" };',
                "alarm($v);");

            $self->select_section('after_call');
            $self->push_lines('alarm(0);');

            $self->select_section('after_eval');
            $self->_errif(504, "\"Timed out ($v sec(s))\"",
                          '$eval_err =~ /\ATimed out\b/');
        },
    },
);

1;
# ABSTRACT: Specify function execution time limit


__END__
=pod

=head1 NAME

Perinci::Sub::property::timeout - Specify function execution time limit

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 # in function metadata
 timeout => 5,

=head1 DESCRIPTION

This property specifies function execution time limit, in seconds. The default
is 0, which means unlimited.

This property's wrapper implementation uses C<alarm()> (C<ualarm()> replacement,
for subsecond granularity, will be considered upon demand). If limit is reached,
a 504 (timeout) status is returned.

=head1 SEE ALSO

L<Perinci>

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

