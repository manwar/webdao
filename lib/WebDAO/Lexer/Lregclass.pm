package WebDAO::Lexer::Lregclass;
#$Id$

=head1 NAME

WebDAO::Lexer::Lregclass - Process regclass tag

=head1 SYNOPSIS

=head1 DESCRIPTION

WebDAO::Lexer::Lregclass - Process regclass tag

=cut

use WebDAO::Lexer::Lbase;
use Data::Dumper;
use base qw( WebDAO::Lexer::Lobject );
use strict;

sub Init {
    my $self = shift;
    my %par  = @_;
    if ( my $context = $par{context} ) {
        push @{ $context->auto }, $self;
    }
    $self->SUPER::Init(@_);
}

sub get_self {
    return undef;
}

sub value {
    my $self = shift;
    my $eng  = shift;
    my $par  = $self->all;
    my ( $class, $alias ) = @$par{qw/class alias/};
    unless ( $class && $alias ) {
        _log1 $self "Syntax error: regclass - not initialized class or alias";
        return;
    }
    if ( my $error_str = $eng->register_class( $class => $alias ) ) {
        _log1 $self $error_str;
    }

}

1;
