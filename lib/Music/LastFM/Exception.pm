package Music::LastFM::Exception;
use strict;
use warnings;
use Carp;
use base 'Exception::Class::Base';

1;

package Music::LastFM::Exception::AuthenticationFailure;
use base 'Music::LastFM::Exception';

package Music::LastFM::Exception::ResponseError;
use strict;
use warnings;
use base 'Music::LastFM::Exception';

sub Fields {
    return qw(error_code response_object);
}

sub response_object {
    my $self = shift;
    if (   ( exists $self->{response_object} )
        && ( defined $self->{response_object} ) ) {
        return $self->{response_object};
    }
    return;
}

1;

package Music::LastFM::Exception::ParseError;
use base 'Music::LastFM::Exception::ResponseError';

1;

package Music::LastFM::Exception::LWPError;
use strict;
use warnings;
use base 'Music::LastFM::Exception';

sub description {
    return 'This is an error returned by LWP User Agent';
}

sub Fields {
    return qw(response_object);
}

sub response_object {
    my $self = shift;
    if (   ( exists $self->{response_object} )
        && ( defined $self->{response_object} ) ) {
        return $self->{response_object};
    }
    return;
}

1;

package Music::LastFM::Exception::APIError;
use strict;
use warnings;
use base 'Music::LastFM::Exception::ResponseError';
{
    my %ERRORS = (
        1 => {
            can_retry   => 0,
            is_fatal    => 1,
            message     => "This error does not exist",
            description => "This error does not exist",
        },
        2 => {
            can_retry   => 0,
            is_fatal    => 1,
            message     => "Invalid service",
            description => "This service does not exist",
        },
        3 => {
            can_retry   => 0,
            is_fatal    => 1,
            message     => "Invalid Method",
            description => "No method with that name in this package",
        },
        4 => {
            can_retry => 0,
            is_fatal  => 1,
            message   => "Authentication Failed",
            description =>
                "You do not have permissions to access the service",
        },
        5 => {
            can_retry   => 0,
            is_fatal    => 1,
            message     => "Invalid format",
            description => "This service doesn't exist in that format",
        },
        6 => {
            can_retry   => 0,
            is_fatal    => 0,
            message     => "Invalid parameters",
            description => "Your request is missing a required parameter",
        },
        7 => {
            can_retry   => 0,
            is_fatal    => 1,
            message     => "Invalid resource specified",
            description => "Invalid resource specified",
        },
        8 => {
            can_retry => 1,
            is_fatal  => 0,
            message   => "Operation failed",
            description =>
                "Most likely the backend service failed. Please try again.",
        },
        9 => {
            can_retry   => 0,
            is_fatal    => 0,
            message     => "Invalid session key",
            description => "Please re-authenticate",
        },
        10 => {
            can_retry   => 0,
            is_fatal    => 1,
            message     => "Invalid API key",
            description => "You must be granted a valid key by last.fm",
        },
        11 => {
            can_retry => 1,
            is_fatal  => 0,
            message   => "Service Offline",
            description =>
                "This service is temporarily offline. Try again later.",
        },
        12 => {
            can_retry => 0,
            is_fatal  => 0,
            message   => "Subscribers Only",
            description =>
                "This station is only available to paid last.fm subscribers",
        },
        13 => {
            can_retry   => 0,
            is_fatal    => 1,
            message     => "Invalid method signature supplied",
            description => "Invalid method signature supplied",
        },
        14 => {
            can_retry   => 0,
            is_fatal    => 0,
            message     => "Unauthorized Token",
            description => "This token has not been authorized",
        },
        15 => {
            can_retry   => 0,
            is_fatal    => 0,
            message     => "This item is not available for streaming.",
            description => "This item is not available for streaming.",
        },
        16 => {
            can_retry => 1,
            is_fatal  => 0,
            message =>
                "The service is temporarily unavailable, please try again.",
            description =>
                "The service is temporarily unavailable, please try again.",
        },
        17 => {
            can_retry   => 0,
            is_fatal    => 0,
            message     => "Login: User requires to be logged in",
            description => "Login: User requires to be logged in",
        },
        18 => {
            can_retry => 0,
            is_fatal  => 0,
            message   => "Trial Expired",
            description =>
                "This user has no free radio plays left. Subscription required.",
        },
        19 => {
            can_retry   => 0,
            is_fatal    => 1,
            message     => "This error does not exist",
            description => "This error does not exist",
        },
        20 => {
            can_retry   => 0,
            is_fatal    => 0,
            message     => "Not Enough Content",
            description => "There is not enough content to play this station",
        },
        21 => {
            can_retry => 0,
            is_fatal  => 0,
            message   => "Not Enough Members",
            description =>
                "This group does not have enough members for radio",
        },
        22 => {
            can_retry => 0,
            is_fatal  => 0,
            message   => "Not Enough Fans",
            description =>
                "This artist does not have enough fans for for radio",
        },
        23 => {
            can_retry   => 0,
            is_fatal    => 0,
            message     => "Not Enough Neighbours",
            description => "There are not enough neighbours for radio",
        },
        24 => {
            can_retry => 0,
            is_fatal  => 0,
            message   => "No Peak Radio",
            description =>
                "This user is not allowed to listen to radio during peak usage",
        },
        25 => {
            can_retry   => 0,
            is_fatal    => 0,
            message     => "Radio Not Found",
            description => "Radio station not found",
        },
        26 => {
            can_retry => 0,
            is_fatal  => 1,
            message   => "API Key Suspended",
            description =>
                "This application is not allowed to make requests to the web services",
        },
        27 => {
            can_retry   => 0,
            is_fatal    => 0,
            message     => "Deprecated",
            description => "This type of request is no longer supported",
        },
    );

    sub description {
        return "An error was returned by the LastFM API";
    }

    sub Fields {
        return qw(error_code response_object);
    }

    sub error_code {
        my $self = shift;
        if (   ( exists $self->{error_code} )
            && ( defined $self->{error_code} ) ) {
            return $self->{error_code};
        }
        return;
    }

    sub is_fatal {
        my $self = shift;
        if ( $self->error_code ) {
            return $ERRORS{ $self->error_code }->{is_fatal};
        }
        return;
    }

    sub can_retry {
        my $self = shift;
        if ( $self->error_code ) {
            return $ERRORS{ $self->error_code }->{can_retry};
        }
        return;
    }

    sub long_description {
        my $self = shift;
        if ( $self->error_code ) {
            return $ERRORS{ $self->error_code }->{description};
        }
        return q{};
    }

    sub full_message {
        my $self         = shift;
        my $error_string = 'LastFM API Error Code: ';
        $error_string .= ( $self->error_code ? $self->error_code : 'undef' );
        $error_string .= ' ' . $self->message;
        $error_string .= ' (' . $self->long_description . ')';
        return $error_string;
    }

}

1;
__END__

=head1 NAME

Music::LastFM::Exception - [One line description of module's purpose here]

=head1 VERSION

This document describes Music::LastFM version 0.0.3

=head1 SYNOPSIS

    use Music::LastFM;
  
=head1 DESCRIPTION

Support module for Music::LastFM.

=head1 METHODS

=head2 Constructor

=over

=item new

=head2 Attributes

=head2 Methods

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

See L<Music::LastFM>.

=head1 DEPENDENCIES

See L<Music::LastFM>.

=head1 INCOMPATIBILITIES

See L<Music::LastFM>.

=head1 BUGS AND LIMITATIONS

See L<Music::LastFM>.

=head1 AUTHOR

Edward Allen  C<< <ealleniii_at_cpan_dot_org> >>

=head1 LICENSE

Copyright (c) 2011, Edward Allen C<< <ealleniii_at_cpan_dot_org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.


