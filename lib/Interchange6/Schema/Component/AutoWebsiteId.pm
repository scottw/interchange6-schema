package Interchange6::Schema::Component::AutoWebsiteId;

=head1 NAME

Interchange6::Schema::Component::AutoWebsite

=head1 DESCRIPTION

Result class helper to provide default value for website_id on create.

=cut

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components(qw/DynamicDefault/);

=head1 METHODS

=head2 add_columns

=cut

sub add_columns {
    my ( $self, @cols ) = @_;
    my @columns;

    while ( my $col = shift @cols ) {
        my $info = ref $cols[0] ? shift @cols : {};
        if ( $col eq 'website_id' ) {
            $info->{dynamic_default_on_create} = 'get_website_id';
        }
        push @columns, $col => $info;
    }

    return $self->next::method(@columns);
}

=head2 get_website_id

=cut

sub get_website_id {
    my $self = shift;
    my $schema = $self->result_source->schema;
    if ( $schema->current_website_id && !$schema->superadmin ) {
        return $schema->current_website_id;
    }
}

1;