# Test alternative parsing approaches to avoid the namespaced xpath issue

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

IO.puts("=== Alternative Parsing Approaches ===")

# Generate XML
{:ok, xml} = ExCius.generate_invoice(valid_invoice_data)
IO.puts("Generated XML successfully")

# Parse with SweetXML
doc = SweetXml.parse(xml, quiet: true)
IO.puts("SweetXML parsing successful")

# Approach 1: Use xmerl directly to extract data
IO.puts("\n1. Testing direct xmerl xpath...")

try do
  # Convert to string for xmerl_xpath
  xml_charlist = String.to_charlist(xml)
  {xmerl_doc, _} = :xmerl_scan.string(xml_charlist)

  # Use xmerl_xpath with proper namespace handling
  namespaces = [
    {"cbc", "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"},
    {"cac", "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"}
  ]

  # Try to extract ID using xmerl_xpath
  id_result = :xmerl_xpath.string('//cbc:ID/text()', xmerl_doc, namespace: namespaces)
  IO.puts("✓ xmerl_xpath ID result: #{inspect(id_result)}")

  if id_result != [] do
    [{:xmlText, _, _, _, id_value, _}] = id_result
    IO.puts("✓ Extracted ID: #{id_value}")
  end
rescue
  e -> IO.puts("✗ xmerl_xpath failed: #{Exception.message(e)}")
end

# Approach 2: Use SweetXML with manual document transformation
IO.puts("\n2. Testing SweetXML with manual doc transformation...")

defmodule AlternativeParser do
  import SweetXml

  def extract_id_alt(doc) do
    # Try different xpath approaches
    approaches = [
      # Without namespace prefix but with namespace declaration
      {~x"//ID/text()"s, []},
      # With local name matching
      {~x"//*[local-name()='ID']/text()"s, []},
      # With namespace and local name
      {~x"//*[namespace-uri()='urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2' and local-name()='ID']/text()"s,
       []}
    ]

    Enum.reduce_while(approaches, nil, fn {xpath_expr, opts}, _acc ->
      try do
        result = doc |> xpath(xpath_expr, opts)

        if result != "" and result != nil do
          IO.puts("✓ Found ID with approach: #{inspect(xpath_expr)} = #{inspect(result)}")
          {:halt, result}
        else
          IO.puts("- Approach #{inspect(xpath_expr)} returned empty")
          {:cont, nil}
        end
      catch
        :exit, reason ->
          IO.puts("- Approach #{inspect(xpath_expr)} failed: #{inspect(reason)}")
          {:cont, nil}
      rescue
        e ->
          IO.puts("- Approach #{inspect(xpath_expr)} exception: #{Exception.message(e)}")
          {:cont, nil}
      end
    end)
  end
end

id_result = AlternativeParser.extract_id_alt(doc)
IO.puts("Alternative extraction result: #{inspect(id_result)}")

# Approach 3: Manual traversal of the document structure
IO.puts("\n3. Testing manual document traversal...")

defmodule ManualTraversal do
  def find_element_by_name(doc, target_name) do
    find_element_recursive(doc, target_name)
  end

  defp find_element_recursive(
         {:xmlElement, name, _prefix, _namespace_info, _ns, _parents, _pos, _attributes, content,
          _tail, _filepath, _form},
         target
       ) do
    # Check if this is our target element
    name_str = Atom.to_string(name)

    if String.contains?(name_str, target) do
      # Extract text content
      extract_text_content(content)
    else
      # Search in children
      Enum.find_value(content, fn child ->
        find_element_recursive(child, target)
      end)
    end
  end

  defp find_element_recursive({:xmlText, _parents, _pos, _lang, text, _type}, _target) do
    # Text nodes don't contain elements
    nil
  end

  defp find_element_recursive(_, _target), do: nil

  defp extract_text_content(content) do
    Enum.find_value(content, fn
      {:xmlText, _parents, _pos, _lang, text, _type} ->
        if is_list(text), do: List.to_string(text), else: text

      _ ->
        nil
    end)
  end
end

manual_id = ManualTraversal.find_element_by_name(doc, "ID")
IO.puts("Manual traversal ID result: #{inspect(manual_id)}")

# Approach 4: Convert back to string and use regex
IO.puts("\n4. Testing regex extraction from XML string...")

# Extract ID using regex
id_regex = ~r/<cbc:ID[^>]*>([^<]+)<\/cbc:ID>/
id_match = Regex.run(id_regex, xml)
regex_id = if id_match, do: Enum.at(id_match, 1), else: nil
IO.puts("Regex extracted ID: #{inspect(regex_id)}")

# Extract currency using regex
currency_regex = ~r/<cbc:DocumentCurrencyCode[^>]*>([^<]+)<\/cbc:DocumentCurrencyCode>/
currency_match = Regex.run(currency_regex, xml)
regex_currency = if currency_match, do: Enum.at(currency_match, 1), else: nil
IO.puts("Regex extracted currency: #{inspect(regex_currency)}")

# Extract operator name from notes using regex
operator_regex = ~r/<cbc:Note[^>]*>Operater: ([^<]+)<\/cbc:Note>/
operator_match = Regex.run(operator_regex, xml)
regex_operator = if operator_match, do: Enum.at(operator_match, 1), else: nil
IO.puts("Regex extracted operator: #{inspect(regex_operator)}")

IO.puts("\n=== Summary ===")
IO.puts("The issue appears to be with SweetXML's namespaced xpath functionality.")
IO.puts("Possible solutions:")
IO.puts("1. Use xmerl directly with proper namespace handling")
IO.puts("2. Use local-name() xpath functions in SweetXML")
IO.puts("3. Use manual document traversal")
IO.puts("4. Use regex extraction as a fallback")
IO.puts("5. Upgrade or downgrade SweetXML version")
