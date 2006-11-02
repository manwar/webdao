#$Id: ListEnv.pm,v 1.2 2006/10/11 07:16:04 zag Exp $

package HTML::WebDAO::Comp::ListEnv;
use base qw(HTML::WebDAO::Component);

sub pre_format {
    my $self = shift;
    my @Out  = <<END;
<table border="1" align="center">
END
    return \@Out;
}

sub format {
    my $self = shift;
    my ( $p1, $p2 ) = split( /\|/, shift );
    return "<tr><td>$p1</td><td><b>$p2</b></td></tr>";
}

sub post_format {
    my $self = shift;
    return ["</table>"];
}

sub fetch {
    my $self = shift;
    foreach $var ( sort( keys(%ENV) ) ) {
        $val = $ENV{$var};
        $val =~ s|\n|\\n|g;
        $val =~ s|"|\\"|g;
        push( @Out, "${var}|${val}" );
    }
    return \@Out;
}
1;
