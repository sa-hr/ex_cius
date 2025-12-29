# Test the actual generated XML content to debug parsing issues

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
{:ok, xml} = ExCius.generate_invoice(valid_invoice_data)

IO.puts("Generated XML full content:")
IO.puts(xml)
IO.puts("\n" <> String.duplicate("=", 80) <> "\n")

# Check for any unusual characters
IO.puts("XML byte inspection (first 50 bytes):")
xml_bytes = :binary.bin_to_list(xml, 0, min(50, byte_size(xml)))
IO.inspect(xml_bytes, limit: :infinity)

# Try parsing with different approaches
IO.puts("\nTesting different parsing approaches...")

# 1. Direct SweetXML parse
IO.puts("1. Testing SweetXML.parse directly:")

try do
  doc = SweetXml.parse(xml, quiet: true)
  IO.puts("✓ SweetXML.parse succeeded")
rescue
  e -> IO.puts("✗ SweetXML.parse failed: #{Exception.message(e)}")
catch
  :exit, reason -> IO.puts("✗ SweetXML.parse failed with exit: #{inspect(reason)}")
end

# 2. Test with SweetXML parse with dtd: :none
IO.puts("\n2. Testing SweetXML.parse with dtd: :none:")

try do
  doc = SweetXml.parse(xml, dtd: :none, quiet: true)
  IO.puts("✓ SweetXML.parse with dtd: :none succeeded")
rescue
  e -> IO.puts("✗ SweetXML.parse with dtd: :none failed: #{Exception.message(e)}")
catch
  :exit, reason ->
    IO.puts("✗ SweetXML.parse with dtd: :none failed with exit: #{inspect(reason)}")
end

# 3. Test with raw xmerl
IO.puts("\n3. Testing raw :xmerl_scan:")

try do
  {doc, _} = :xmerl_scan.string(String.to_charlist(xml))
  IO.puts("✓ :xmerl_scan.string succeeded")
rescue
  e -> IO.puts("✗ :xmerl_scan.string failed: #{Exception.message(e)}")
catch
  :exit, reason -> IO.puts("✗ :xmerl_scan.string failed with exit: #{inspect(reason)}")
end

# 4. Test parsing just the first 500 characters to see if it's a length issue
IO.puts("\n4. Testing truncated XML (first 500 chars):")
truncated_xml = String.slice(xml, 0, 500) <> "</Invoice>"

try do
  doc = SweetXml.parse(truncated_xml, quiet: true)
  IO.puts("✓ Truncated XML parse succeeded")
rescue
  e -> IO.puts("✗ Truncated XML parse failed: #{Exception.message(e)}")
catch
  :exit, reason -> IO.puts("✗ Truncated XML parse failed with exit: #{inspect(reason)}")
end

# 5. Check for BOM or encoding issues
IO.puts("\n5. Checking for BOM or encoding issues:")

if String.starts_with?(xml, <<0xEF, 0xBB, 0xBF>>) do
  IO.puts("Found UTF-8 BOM")
else
  IO.puts("No UTF-8 BOM found")
end

# Check if valid UTF-8
case :unicode.characters_to_binary(xml, :utf8, :utf8) do
  ^xml -> IO.puts("XML is valid UTF-8")
  {:error, _, _} -> IO.puts("XML contains invalid UTF-8 sequences")
  {:incomplete, _, _} -> IO.puts("XML contains incomplete UTF-8 sequences")
end
