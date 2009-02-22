package WebDAO::Component;
#$Id$

=head1 NAME

WebDAO::Component - Component class

=head1 SYNOPSIS

=head1 DESCRIPTION

WebDAO::Component - Component class

=cut

use WebDAO::Base;
use base qw(WebDAO::Element);
use strict 'vars';
use Data::Dumper;

sub _url_method {
    my $self   = shift;
    my $method = shift;
    my $ref;
    $ref->{path} = join '/' => $self->__path2me, $method;
    my %args = @_;
    $ref->{pars} = \%args if @_;
    my $res;
    $self->SendEvent(
        "_sess_servise",
        {
            funct  => 'geturl',
            par    => $ref,
            result => \$res
        }
    );
    return $res;

}

sub url_method {
    my $self   = shift;
    my $method = shift;
    my @upath  = ();
    push @upath, $self->__path2me if $self->__path2me;
    if ( defined $self->__extra_path ) {
        my $extr = $self->__extra_path;
        $extr = [$extr] unless ( ref($extr) eq 'ARRAY' );
        push @upath, @$extr;
    }
    push @upath, $method if defined $method;
    my $sess = $self->getEngine->_session;
    if ( $sess->set_absolute_url() ) {
        unshift @upath, $sess->Cgi_env->{base_url};
    }

    my $path = join '/' => @upath;
    my $str = '';
    if (@_) {
        my %args = @_;
        my @pars;
        while ( my ( $key, $val ) = each %args ) {
            push @pars, "$key=$val";
        }
        $str .= "?" . join "&" => @pars;
    }
    return $path . $str;
}

sub response {
    my $self = shift;
    return $self->getEngine->response;
}
1;
__DATA__

=head1 SEE ALSO

http://sourceforge.net/projects/webdao

=head1 AUTHOR

Zahatski Aliaksandr, E<lt>zag@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002-2009 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

