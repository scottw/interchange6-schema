package Interchange6::Schema::Populate::Currency;

=head1 NAME

Interchange6::Schema::Populate::Currency

=head1 DESCRIPTION

This module provides population capabilities for the Currency class

=cut

use Moo;
use Locale::Currency;

=head1 METHODS

=head2 records

Returns array reference containing one hash reference per currency,
ready to use with populate schema method.

=cut

sub records {
    my @codes = all_currency_codes();
    my %ignore = map { $_ => 1 } (
        'BOV',   # Mvdol
        'CHE',   # WIR Euro
        'CHW',   # WIR Franc
        'CLF',   # Unidad de Fomento
        'COU',   # Unidad de Valor Real
        'CUC',   # Peso Convertible
        'MXV',   # Mexican Unidad de Inversion (UDI)
        'SVC',   # El Salvador Colon
        'USN',   # US Dollar (Next day)
        'UYI',   # Uruguay Peso en Unidades Indexadas (URUIURUI)
        'XAG',   # Silver
        'XAU',   # Gold
        'XBA',   # Bond Markets Unit European Composite Unit (EURCO)
        'XBB',   # Bond Markets Unit European Monetary Unit (E.M.U.-6)
        'XBC',   # Bond Markets Unit European Unit of Account 9 (E.U.A.-9)
        'XBD',   # Bond Markets Unit European Unit of Account 17 (E.U.A.-17)
        'XDR',   # SDR (Special Drawing Right)
        'XPD',   # Palladium
        'XPT',   # Platinum
        'XSU',   # Sucre
        'XUA',   # ADB Unit of Account
    );

    my @currencies =
      map { +{ iso_code => $_, name => code2currency($_) } }
      grep { !$ignore{$_} } @codes;
    return \@currencies;
}

1;
