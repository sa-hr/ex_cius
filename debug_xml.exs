valid_invoice_data = %{
  id: "TEST-001",
  issue_datetime: "2025-05-01T12:00:00",
  operator_name: "Test Operator",
  currency_code: "EUR",
  supplier: %{
    oib: "12345678901",
    registration_name: "Test Supplier Ltd",
    postal_address: %{
      street_name: "Supplier Street 1",
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
    registration_name: "Test Customer Ltd",
    postal_address: %{
      street_name: "Customer Street 2",
      city_name: "Split",
      postal_zone: "21000",
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
        name: "Test Product",
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
  ]
}

IO.puts("Generating XML...")
{:ok, xml} = ExUBL.generate_invoice(valid_invoice_data)

IO.puts("Generated XML:")
IO.puts("Length: #{String.length(xml)}")
IO.puts("First 200 chars:")
IO.puts(String.slice(xml, 0, 200))

IO.puts("\nFirst 10 bytes as integers:")

xml
|> String.to_charlist()
|> Enum.take(10)
|> IO.inspect()

IO.puts("\nTrying to parse...")
result = ExUBL.parse_invoice(xml)
IO.inspect(result, label: "Parse result")
