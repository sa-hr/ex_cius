# ExUBL

An Elixir library for generating UBL 2.1 (Universal Business Language) invoices compliant with the Croatian e-Invoice specification (CIUS-2025).

## Features

- Generate UBL 2.1 compliant XML invoices
- Croatian e-Invoice (e-Račun) support
- Comprehensive input validation
- Support for VAT calculations and tax categories

## Installation

Add `ex_ubl` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_ubl, "~> 0.1.0"}
  ]
end
```

## Usage

```elixir
params = %{
  id: "INV-001",
  issue_datetime: "2025-05-01T12:00:00",
  operator_name: "Operator1",
  currency_code: "EUR",
  supplier: %{
    oib: "12345678901",
    registration_name: "Company A d.o.o.",
    postal_address: %{
      street_name: "Street 1",
      city_name: "Zagreb",
      postal_zone: "10000",
      country_code: "HR"
    },
    party_tax_scheme: %{
      company_id: "HR12345678901",
      tax_scheme_id: "vat"
    }
  },
  customer: %{
    oib: "11111111119",
    registration_name: "Company B d.o.o.",
    postal_address: %{
      street_name: "Street 2",
      city_name: "Rijeka",
      postal_zone: "51000",
      country_code: "HR"
    },
    party_tax_scheme: %{
      company_id: "HR11111111119",
      tax_scheme_id: "vat"
    }
  },
  tax_total: %{
    tax_amount: "25.00",
    tax_subtotals: [
      %{
        taxable_amount: "100.00",
        tax_amount: "25.00",
        tax_category: %{
          id: "standard_rate",
          percent: 25,
          tax_scheme_id: "vat"
        }
      }
    ]
  },
  legal_monetary_total: %{
    line_extension_amount: "100.00",
    tax_exclusive_amount: "100.00",
    tax_inclusive_amount: "125.00",
    payable_amount: "125.00"
  },
  invoice_lines: [
    %{
      id: "1",
      quantity: 1.0,
      unit_code: "piece",
      line_extension_amount: "100.00",
      item: %{
        name: "Product",
        classified_tax_category: %{
          id: "standard_rate",
          percent: 25,
          tax_scheme_id: "vat"
        }
      },
      price: %{
        price_amount: "100.00"
      }
    }
  ],
  notes: ["Payment due within 30 days"]
}

{:ok, validated_params} = ExUBL.RequestParams.new(params)
```

## Supported Enums

### Invoice Type Codes
- `:commercial_invoice` (380)
- `:credit_note` (381)
- `:corrected_invoice` (384)
- `:self_billed_invoice` (389)
- `:invoice_information` (751)

### Tax Categories
- `:standard_rate` (S)
- `:zero_rate` (Z)
- `:exempt` (E)
- `:reverse_charge` (AE)
- `:intra_community` (K)
- `:export` (G)
- `:outside_scope` (O)

Note: The reduced Croatian VAT rates of 13% and 5% should use the `:standard_rate` category with the appropriate percentage.

### Tax Schemes
- `:vat` (VAT)

### Unit Codes
- `:piece` (H87)

### Business Process
- `:billing` (P1)

### Currency
- `:EUR` (EUR)

## License

Copyright (C) 2025 Pametno računovodstvo d.o.o.

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

See the [LICENSE](LICENSE) file for details.