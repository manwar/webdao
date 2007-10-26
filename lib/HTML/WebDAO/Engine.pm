#$Id$

package HTML::WebDAO::Engine;
use Data::Dumper;
use HTML::WebDAO::Container;
use HTML::WebDAO::Lex;
use HTML::WebDAO::Lib::MethodByPath;
use HTML::WebDAO::Lib::RawHTML;
use base qw(HTML::WebDAO::Container);
use Carp;
use strict;
__PACKAGE__->attributes qw( _session __obj __events);

sub _sysinit {
    my ( $self, $ref ) = @_;
    my %hash = @$ref;

    # Setup $init_hash;
    my $my_name = $hash{id} || '';    #shift( @{$ref} );
    unshift(
        @{$ref},
        {
            ref_engine => $self,       #! Setup _engine refernce for childs!
            name_obj   => "$my_name"
        }
    );                                 #! Setup _my_name
                                       #Save session
    _session $self $hash{session};

    #	name_obj=>"applic"});	#! Setup _my_name
    $self->SUPER::_sysinit($ref);

    #!init _runtime variables;
    $self->_set_parent($self);

    #hash "function" -"package"
    $self->__obj( {} );

    #init hash of evens names  -> @Array of pointers of sub in objects
    $self->__events( {} );

}

sub init {
    my ( $self, %opt ) = @_;

    #register default clasess
    $self->register_class(
        'HTML::WebDAO::Lib::RawHTML'      => '_rawhtml_element',
        'HTML::WebDAO::Lib::MethodByPath' => '_method_call'
    );

    #Register by init classes
    if ( ref( my $classes = $opt{register} ) ) {
        $self->register_class(%$classes);
    }
    my $raw_html = $opt{source};
    if ( my $lex = $opt{lexer} ) {
        map { $_->value($self) } @{ $lex->auto };
        my @objs = map { $_->value($self) } @{ $lex->tree };
        $self->_add_childs(@objs);
    }
    else {

        #Create childs from source
        $self->_add_childs( @{ $self->_parse_html($raw_html) } );
    }

}

sub _get_obj_by_path {
    my $self = shift;
    my ( $obj_p, @path ) = @_;
    my $id = shift @path;
    my $res;
    if ( my $obj = $obj_p->_get_obj_by_name($id) ) {
        $res = scalar(@path) ? $self->_get_obj_by_path( $obj, @path ) : $obj;
    }
    return $res;
}

sub __restore_session_attributes {
    my $self = shift;

    #collect paths as index
    my %paths;
    foreach my $object (@_) {
        my @collection = ( $object, @{ $object->_get_childs } );
        $paths{ $_->__path2me } = $_ for @collection;
    }
    my $sess   = $self->_session;
    my $loaded = $sess->_load_attributes_by_path( keys %paths );
    while ( my ( $key, $ref ) = each %$loaded ) {
        next unless exists $paths{$key};
        $paths{$key}->_set_vars($ref);
    }
}

sub __store_session_attributes {
    my $self = shift;

    #collect paths as index
    my %paths;
    foreach my $object (@_) {
        my @collection = ( $object, @{ $object->_get_childs } );
        foreach (@collection) {
            my $attrs = $_->_get_vars;
            next unless $attrs;
            $paths{ $_->__path2me } = $attrs;
        }
    }
    my $sess = $self->_session;
    $sess->_store_attributes_by_path( \%paths );
}

sub response {
    my $self = shift;
    return $self->_session->response_obj;
}

sub Work {
    my $self = shift;
    my $sess = shift;
    my @path = @{ $sess->call_path };

    #    _log1 $self "WOKR: '@path'".Dumper(\@path);
    ####
    my $res = $self->_call_method( \@path, %{ $sess->Params } ) if @path;

    #if not defined $res

    #first prepare response object
    my $response = $sess->response_obj;
    unless ($res) {

        #        $response->print_header();
        $response->print($_) for @{ $self->fetch($sess) };

        #        $response->error404("Url not found:".join "/",@path);
        $response->flush;
        return;    #end
    }

    if ( ref($res) eq 'HASH'
        and ( exists $res->{header} or exists $res->{data} ) )
    {

        #set headers
        if ( exists $res->{header} ) {
            while ( my ( $key, $val ) = each %{ $res->{header} } ) {
                $response->set_header( $key, $val );
            }
        }
        if ( my $call_back = $res->{call_back} ) {
            $response->set_callback($call_back)
              if ref($call_back) eq 'CODE';
        }
        $response->print( $res->{data} ) if exists $res->{data};
        $res = $response;
    }
    if ( UNIVERSAL::isa( $res, 'HTML::WebDAO::Response' ) ) {

        #we gor response !
        $res->flush;
        return;
    }
    unless ( ref($res) ) {
        $response->print($res);
        $response->flush();
        return;
    }
    _log1 $self "Unknown response : $res";
    $response->print($_) for @{ $self->fetch($sess) };
    $response->flush;
}

#fill $self->__events hash event - method
sub RegEvent {
    my ( $self, $ref_obj, $event_name, $ref_sub ) = @_;
    my $ev_hash = $self->__events;
    $ev_hash->{$event_name}->{ scalar($ref_obj) } = {
        ref_obj => $ref_obj,
        ref_sub => $ref_sub
      }
      if ( ref($ref_sub) );
    return 1;
}

sub SendEvent {
    my ( $self, $event_name, @Par ) = @_;
    my $ev_hash = $self->__events;
    unless ( exists( $ev_hash->{$event_name} ) ) {
        _log2 $self "WARN: Event $event_name not exists.";
        return 0;
    }
    foreach my $ref_rec ( keys %{ $ev_hash->{$event_name} } ) {
        my $ref_sub = $ev_hash->{$event_name}->{$ref_rec}->{ref_sub};
        my $ref_obj = $ev_hash->{$event_name}->{$ref_rec}->{ref_obj};
        $ref_obj->$ref_sub( $event_name, @Par );
    }
}

=head3 _createObj(<name>,<class or alias>,@parameters)

create object by <class or alias>.

=cut

sub _createObj {
    my ( $self, $name_obj, $name_func, @par ) = @_;
    if ( my $pack = _pack4name $self $name_func ) {
        my $ref_init_hash = {
            ref_engine => $self->getEngine()
            ,    #! Setup _engine refernce for childs!
            name_obj => $name_obj
        };    #! Setup _my_name
        my $obj_ref =
          $pack->isa('HTML::WebDAO::Element')
          ? eval "'$pack'\-\>new(\$ref_init_hash,\@par)"
          : eval "'$pack'\-\>new(\@par)";
        carp "Error in eval:  _createObj $@" if $@;
        return $obj_ref;
    }
    else { _log1 $self "Not registered alias: $name_func"; return }
}

#sub _parse_html(\@html)
#return \@Objects
sub _parse_html {
    my ( $self, $raw_html ) = @_;
    return [] unless $raw_html;

    #Mac and DOS line endings
    $raw_html =~ s/\r\n?/\n/g;
    my $mass;
    $mass = [ split( /(<WD>.*?<\/WD>)/is, $raw_html ) ];
    my @res;
    foreach my $text (@$mass) {
        my @ref;
        unless ( $text =~ /^<wd/i ) {
            push @ref, $self->_createObj( "none", "_rawhtml_element", \$text )
              ;    #if $text =~ /\s+/;
        }
        else {
            my $lex = new HTML::WebDAO::Lex:: engine => $self;
            @ref = $lex->lex_data($text);    #clean 'empty'

          #        _log3 $self "LEXED:".Dumper([ map {"$_"} @ref])."from $text";

        }
        next unless @ref;
        push @res, @ref;
    }
    return \@res;
}

#Get package for functions name
sub _pack4name {
    my ( $self, $name ) = @_;
    my $ref = $self->__obj;
    return $$ref{$name} if ( exists $$ref{$name} );
}

sub register_class {
    my ( $self, %register ) = @_;
    my $_obj = $self->__obj;
    while ( my ( $class, $alias ) = each %register ) {
        eval " use $class";
        if ($@) {
            _log1 $self "Error register class :$class with $@ ";
            return "Error register class :$class with $@ ";
            next;
        }
        $$_obj{$alias} = $class;
    }
    return;
}

sub _destroy {
    my $self = shift;
    $self->__store_session_attributes( @{ $self->_get_childs } );
    $self->SUPER::_destroy;
    $self->_session(undef);
    $self->__obj(undef);
    $self->__events(undef);
}
1;
