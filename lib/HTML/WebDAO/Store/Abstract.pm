#$Id: Abstract.pm,v 1.1 2006/05/29 15:27:09 zag Exp $

package HTML::WebDAO::Store::Abstract;
use HTML::WebDAO::Base;
use Data::Dumper;
use strict;
@HTML::WebDAO::Store::Abstract::ISA = ('HTML::WebDAO::Base');
sub _init {
    my $self = shift;
    return $self->init(@_);
}
sub init {
    return 1
}
sub load { {} }
sub store { {} }
sub _load_attributes {
    my $self = shift;
    return {}
}
sub _store_attributes {
    my $self = shift;
    return {}
}
sub flush { #$_[0]->_log1("flush")
}

1;
