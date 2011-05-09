package Music::LastFM::Method;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.3');
use Moose;
use Music::LastFM::Meta::EasyAcc;
use MooseX::Types::Moose qw(Str Bool ArrayRef HashRef);
use Music::LastFM::Types::LastFM qw(Metas);
use namespace::autoclean;

has 'name' => ( is => 'ro', isa => Str, required => 1 );

has 'sign_required' =>
    ( is => 'ro', isa => Bool, lazy => 1, builder => '_build_sign', );

sub _build_sign { my $self = shift; return $self->auth_required; }

has 'auth_required' => ( is => 'ro', isa => Bool, default => 0, );
has 'http_method'       => ( is => 'ro', isa => Str,  default => 'GET', );
has 'ignore_top'    => ( is => 'ro', isa => Bool, default => 1, );
has 'agent'        => (
    is        => 'rw',
    weak_ref  => 1,
    lazy      => 1,
    predicate => 'has_agent',
    default   => sub { Music::LastFM::Agent->instance }
);
has 'options' => ( is => 'ro', isa => HashRef, default => sub { {} } );

sub execute {
    my $self    = shift;
    my %options = @_;
    my $resp    = $self->agent->query(
        method  => $self,
        options => $self->options,
        %options
    );
    return $resp->data();
}

__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

Music::LastFM::Method - Object describing a LastFM api method.

=head1 VERSION

This document describes Music::LastFM version 0.0.3

=head1 SYNOPSIS

See L<Music::LastFM>
  
=head1 DESCRIPTION

Support module for Music::LastFM. You should rarely need to use this.

=head1 METHODS

=head2 Constructor

=over

=item new( name => $name )

Create a new methd.  Only required option is name, which is the name of the
API Method.

=back

=head2 Attributes

=over

=item agent set_agent has_agent 

A Music::LastFM::Agent object.  Defaults to Music::LastFM::Agent singleton.

=item auth_required has_auth_required 

Default: false

If set, method requires authentication.

=item http_method has_http_method 

Default: GET

HTTP Protocol method to use.

=item ignore_top has_ignore_top 

Default: true

Ignore the top level on the JSON response tree.  Almost always wanted.


=item name  has_name 

Required. The name of the method call.

=item options has_options 

A hashref of additional options to pass when using this method.

=item sign_required has_sign_required 

Default: false

This request must be signed if true.

=back

=head2 Methods

=over

=item execute

Execute the method using the agent and return the response data

=back

=head1 DIAGNOSTICS

See L<Music::LastFM>.

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


