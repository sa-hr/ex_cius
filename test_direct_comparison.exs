# Direct comparison test to isolate the parsing issue

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

IO.puts("=== Direct Comparison Test ===")

# Step 1: Generate XML
IO.puts("1. Generating XML...")
{:ok, xml} = ExCius.generate_invoice(valid_invoice_data)
IO.puts("Generated XML successfully. Length: #{String.length(xml)} chars")

# Step 2: Call ExCius.parse_invoice directly
IO.puts("\n2. Testing ExCius.parse_invoice(xml)...")

try do
  result = ExCius.parse_invoice(xml)

  case result do
    {:ok, data} ->
      IO.puts("✓ ExCius.parse_invoice succeeded!")
      IO.puts("Parsed ID: #{data.id}")
      IO.puts("Parsed operator: #{data.operator_name}")

    {:error, reason} ->
      IO.puts("✗ ExCius.parse_invoice failed:")
      IO.puts("Error: #{reason}")
  end
rescue
  e ->
    IO.puts("✗ ExCius.parse_invoice raised exception:")
    IO.puts("Exception: #{Exception.message(e)}")
end

# Step 3: Call InvoiceXmlParser.parse directly
IO.puts("\n3. Testing ExCius.InvoiceXmlParser.parse(xml)...")

try do
  result = ExCius.InvoiceXmlParser.parse(xml)

  case result do
    {:ok, data} ->
      IO.puts("✓ InvoiceXmlParser.parse succeeded!")
      IO.puts("Parsed ID: #{data.id}")
      IO.puts("Parsed operator: #{data.operator_name}")

    {:error, reason} ->
      IO.puts("✗ InvoiceXmlParser.parse failed:")
      IO.puts("Error: #{reason}")
  end
rescue
  e ->
    IO.puts("✗ InvoiceXmlParser.parse raised exception:")
    IO.puts("Exception: #{Exception.message(e)}")
end

# Step 4: Test with a simple truncated version
IO.puts("\n4. Testing with simplified XML...")

simple_xml = """
<?xml version="1.0" encoding="UTF-8"?>
<Invoice xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2"
         xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2">
  <cbc:ID>TEST-001</cbc:ID>
  <cbc:IssueDate>2025-05-01</cbc:IssueDate>
  <cbc:DocumentCurrencyCode>EUR</cbc:DocumentCurrencyCode>
  <cbc:Note>Operater: Test Operator</cbc:Note>
</Invoice>
"""

try do
  result = ExCius.InvoiceXmlParser.parse(simple_xml)

  case result do
    {:ok, data} ->
      IO.puts("✓ Simple XML parse succeeded!")
      IO.puts("Parsed ID: #{data.id}")

    {:error, reason} ->
      IO.puts("✗ Simple XML parse failed:")
      IO.puts("Error: #{reason}")
  end
rescue
  e ->
    IO.puts("✗ Simple XML parse raised exception:")
    IO.puts("Exception: #{Exception.message(e)}")
end

# Step 5: Debug the exact XML content that's failing
IO.puts("\n5. Debugging the exact failing content...")

# Save the XML to a temporary file for inspection
xml_file = "/tmp/debug_invoice.xml"
File.write!(xml_file, xml)
IO.puts("XML written to: #{xml_file}")

# Try reading it back
xml_from_file = File.read!(xml_file)
IO.puts("XML from file matches original: #{xml == xml_from_file}")

# Test parsing the file content
try do
  result = ExCius.InvoiceXmlParser.parse(xml_from_file)

  case result do
    {:ok, data} ->
      IO.puts("✓ XML from file parse succeeded!")

    {:error, reason} ->
      IO.puts("✗ XML from file parse failed:")
      IO.puts("Error: #{reason}")
  end
rescue
  e ->
    IO.puts("✗ XML from file parse raised exception:")
    IO.puts("Exception: #{Exception.message(e)}")
end

IO.puts("\n=== Test Complete ===")
