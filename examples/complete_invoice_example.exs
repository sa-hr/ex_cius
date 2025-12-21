#!/usr/bin/env elixir

# Complete Invoice Generation Example
#
# This example demonstrates the complete workflow of creating a UBL 2.1 Invoice XML
# from raw input data using the ExUBL library.

Mix.install([
  {:ex_ubl, path: ".."}
])

alias ExUBL.{InvoiceTemplateXML, RequestParams}

# Sample invoice data that matches the structure expected by ExUBL.RequestParams
invoice_data = %{
  # Required invoice identification
  id: "5-P1-1",
  issue_datetime: "2025-05-01T12:00:00",
  operator_name: "Operater1",
  currency_code: "EUR",

  # Optional fields
  due_date: "2025-05-31",
  # defaults to "billing"
  business_process: "billing",
  # defaults to "commercial_invoice"
  invoice_type_code: "commercial_invoice",

  # Supplier information (required)
  supplier: %{
    oib: "12345678901",
    registration_name: "FINANCIJSKA AGENCIJA",
    postal_address: %{
      street_name: "VRTNI PUT 3",
      city_name: "ZAGREB",
      postal_zone: "10000",
      country_code: "HR"
    },
    party_tax_scheme: %{
      company_id: "HR12345678901",
      tax_scheme_id: "vat"
    },
    # Optional contact information
    contact: %{
      name: "IME PREZIME",
      electronic_mail: "ii@mail.hr"
    },
    # Optional seller contact (operator information)
    seller_contact: %{
      id: "51634872748",
      name: "Operater1"
    }
  },

  # Customer information (required)
  customer: %{
    oib: "11111111119",
    registration_name: "Tvrtka B d.o.o.",
    postal_address: %{
      street_name: "Ulica 2",
      city_name: "RIJEKA",
      postal_zone: "51000",
      country_code: "HR"
    },
    party_tax_scheme: %{
      company_id: "HR11111111119",
      tax_scheme_id: "vat"
    }
    # Note: contact information is optional for customer
  },

  # Optional payment information
  payment_method: %{
    # Bank transfer
    payment_means_code: "30",
    instruction_note: "Opis plaćanja",
    payment_id: "HR00 123456",
    payee_financial_account_id: "HRXXXXXXXXXXXXXXXX"
  },

  # Tax calculation (required)
  tax_total: %{
    tax_amount: "25.00",
    tax_subtotals: [
      %{
        taxable_amount: "100.00",
        tax_amount: "25.00",
        tax_category: %{
          # Maps to UBL tax category "S"
          id: "standard_rate",
          percent: 25,
          # Maps to UBL "VAT"
          tax_scheme_id: "vat"
        }
      }
    ]
  },

  # Monetary totals (required)
  legal_monetary_total: %{
    line_extension_amount: "100.00",
    tax_exclusive_amount: "100.00",
    tax_inclusive_amount: "125.00",
    payable_amount: "125.00"
  },

  # Invoice lines (required - at least one)
  invoice_lines: [
    %{
      id: "1",
      quantity: 1.0,
      # Maps to UBL unit code "H87"
      unit_code: "piece",
      line_extension_amount: "100.00",
      item: %{
        name: "Proizvod",
        # Optional commodity classification
        commodity_classification: %{
          item_classification_code: "62.90.90"
        },
        classified_tax_category: %{
          # Maps to UBL "S"
          id: "standard_rate",
          # Optional Croatian tax name
          name: "HR:PDV25",
          percent: 25,
          tax_scheme_id: "vat"
        }
      },
      price: %{
        price_amount: "100.00",
        # Optional base quantity and unit code
        base_quantity: 1.0,
        unit_code: "piece"
      }
    }
  ],

  # Optional free-text notes (in addition to the mandatory operator note)
  notes: [
    "Napomena o računu",
    "Dodatne informacije"
  ]
}

IO.puts(String.duplicate("=", 80))
IO.puts("ExUBL Complete Invoice Generation Example")
IO.puts(String.duplicate("=", 80))
IO.puts("")

IO.puts("Step 1: Validate input parameters...")

case RequestParams.new(invoice_data) do
  {:ok, validated_params} ->
    IO.puts("✓ Parameters validated successfully")
    IO.puts("  Invoice ID: #{validated_params.id}")
    IO.puts("  Issue Date: #{validated_params.issue_date}")
    IO.puts("  Issue Time: #{validated_params.issue_time}")
    IO.puts("  Currency: #{validated_params.currency_code}")
    IO.puts("  Supplier: #{validated_params.supplier.registration_name}")
    IO.puts("  Customer: #{validated_params.customer.registration_name}")
    IO.puts("")

    IO.puts("Step 2: Generate UBL Invoice XML...")
    xml = InvoiceTemplateXML.build_xml(validated_params)

    IO.puts("✓ XML generated successfully")
    IO.puts("  XML length: #{String.length(xml)} characters")
    IO.puts("")

    # Write to file
    output_file = "generated_invoice_example.xml"
    File.write!(output_file, xml)
    IO.puts("✓ XML saved to: #{output_file}")
    IO.puts("")

    # Display first few lines of XML for verification
    IO.puts("Generated XML preview:")
    IO.puts(String.duplicate("-", 40))

    xml
    |> String.split("\n")
    |> Enum.take(10)
    |> Enum.each(&IO.puts("  #{&1}"))

    IO.puts("  ...")
    IO.puts(String.duplicate("-", 40))
    IO.puts("")

    # Verify key elements are present
    IO.puts("Verification checks:")

    checks = [
      {"XML Declaration", String.starts_with?(xml, "<?xml version")},
      {"Invoice Element", String.contains?(xml, "<Invoice xmlns=")},
      {"Invoice ID", String.contains?(xml, "<cbc:ID>5-P1-1</cbc:ID>")},
      {"Supplier Name", String.contains?(xml, "FINANCIJSKA AGENCIJA")},
      {"Customer Name", String.contains?(xml, "Tvrtka B d.o.o.")},
      {"Tax Amount",
       String.contains?(xml, "<cbc:TaxAmount currencyID=\"EUR\">25.00</cbc:TaxAmount>")},
      {"Payment Means", String.contains?(xml, "<cac:PaymentMeans>")},
      {"Invoice Line", String.contains?(xml, "<cac:InvoiceLine>")},
      {"Product Name", String.contains?(xml, "<cbc:Name>Proizvod</cbc:Name>")},
      {"Operator Name Note", String.contains?(xml, "<cbc:Note>Operater: Operater1</cbc:Note>")},
      {"Issue Time Note", String.contains?(xml, "Vrijeme izdavanja:")},
      {"User Notes", String.contains?(xml, "<cbc:Note>Napomena o računu</cbc:Note>")}
    ]

    Enum.each(checks, fn {check_name, result} ->
      status = if result, do: "✓", else: "✗"
      IO.puts("  #{status} #{check_name}")
    end)

    IO.puts("")
    IO.puts(String.duplicate("=", 80))
    IO.puts("Invoice generation completed successfully!")
    IO.puts(String.duplicate("=", 80))

  {:error, errors} ->
    IO.puts("✗ Parameter validation failed!")
    IO.puts("Errors:")

    Enum.each(errors, fn {field, message} ->
      IO.puts("  #{field}: #{message}")
    end)

    System.halt(1)
end
