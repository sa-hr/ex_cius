defmodule ExCiusTest do
  use ExUnit.Case
  doctest ExCius

  @valid_invoice_data %{
    id: "TEST-001",
    issue_datetime: "2025-05-01T12:00:00",
    operator_name: "Test Operator",
    operator_oib: "12345678901",
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
          },
          commodity_classification: %{
            item_classification_code: "73211200",
            list_id: "CG"
          }
        },
        price: %{
          price_amount: "100.00"
        }
      }
    ]
  }

  @valid_invoice_with_optionals Map.merge(@valid_invoice_data, %{
                                  due_date: "2025-05-31",
                                  business_process: "billing",
                                  invoice_type_code: "commercial_invoice",
                                  payment_method: %{
                                    payment_means_code: "30",
                                    instruction_note: "Payment instruction",
                                    payment_id: "PAY123",
                                    payee_financial_account_id: "HR1234567890123456789"
                                  },
                                  notes: ["Custom note 1", "Custom note 2"]
                                })

  describe "generate_invoice/1" do
    test "generates valid UBL XML from valid invoice data" do
      {:ok, xml} = ExCius.generate_invoice(@valid_invoice_data)

      assert is_binary(xml)
      assert String.starts_with?(xml, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
      assert String.contains?(xml, "<Invoice xmlns=")
      assert String.contains?(xml, "<cbc:ID>TEST-001</cbc:ID>")
      assert String.contains?(xml, "<cbc:DocumentCurrencyCode>EUR</cbc:DocumentCurrencyCode>")

      # Check mandatory operator notes
      assert String.contains?(xml, "Operater: Test Operator")
      assert String.contains?(xml, "Vrijeme izdavanja:")

      # Check basic structure
      assert String.contains?(xml, "<cac:AccountingSupplierParty>")
      assert String.contains?(xml, "<cac:AccountingCustomerParty>")
      assert String.contains?(xml, "<cac:TaxTotal>")
      assert String.contains?(xml, "<cac:LegalMonetaryTotal>")
      assert String.contains?(xml, "<cac:InvoiceLine>")

      # Ensure proper XML closure
      assert String.ends_with?(String.trim(xml), "</Invoice>")
    end

    test "generates XML with optional fields when provided" do
      {:ok, xml} = ExCius.generate_invoice(@valid_invoice_with_optionals)

      assert String.contains?(xml, "<cbc:DueDate>2025-05-31</cbc:DueDate>")
      assert String.contains?(xml, "<cac:PaymentMeans>")
      assert String.contains?(xml, "<cbc:Note>Custom note 1</cbc:Note>")
      assert String.contains?(xml, "<cbc:Note>Custom note 2</cbc:Note>")
    end

    test "returns validation errors for invalid data" do
      invalid_data = %{id: "TEST", currency_code: "USD"}

      {:error, errors} = ExCius.generate_invoice(invalid_data)

      assert is_map(errors)
      assert Map.has_key?(errors, :operator_name)
      assert Map.has_key?(errors, :issue_datetime)
      assert Map.has_key?(errors, :invoice_lines)
    end

    test "returns validation errors for empty data" do
      {:error, errors} = ExCius.generate_invoice(%{})

      assert is_map(errors)
      assert Map.has_key?(errors, :id)
      assert Map.has_key?(errors, :issue_datetime)
      assert Map.has_key?(errors, :operator_name)
    end

    test "returns error for non-map input" do
      assert {:error, %{input: "must be a map"}} = ExCius.generate_invoice("not a map")
      assert {:error, %{input: "must be a map"}} = ExCius.generate_invoice(123)
      assert {:error, %{input: "must be a map"}} = ExCius.generate_invoice(nil)
    end

    test "handles complex invoice with multiple lines and tax rates" do
      complex_invoice =
        Map.put(@valid_invoice_data, :invoice_lines, [
          %{
            id: "1",
            quantity: 2.0,
            unit_code: "piece",
            line_extension_amount: "100.00",
            item: %{
              name: "Product A",
              classified_tax_category: %{
                id: "standard_rate",
                percent: 25,
                tax_scheme_id: "vat"
              },
              commodity_classification: %{
                item_classification_code: "73211200",
                list_id: "CG"
              }
            },
            price: %{price_amount: "50.00"}
          },
          %{
            id: "2",
            quantity: 1.0,
            unit_code: "piece",
            line_extension_amount: "130.00",
            item: %{
              name: "Product B",
              classified_tax_category: %{
                id: "standard_rate",
                percent: 13,
                tax_scheme_id: "vat"
              },
              commodity_classification: %{
                item_classification_code: "73211200",
                list_id: "CG"
              }
            },
            price: %{price_amount: "130.00"}
          }
        ])

      {:ok, xml} = ExCius.generate_invoice(complex_invoice)

      # Should contain both lines
      # 1 + 2 lines
      assert xml |> String.split("<cac:InvoiceLine>") |> length() == 3
      assert String.contains?(xml, "<cbc:Name>Product A</cbc:Name>")
      assert String.contains?(xml, "<cbc:Name>Product B</cbc:Name>")
    end
  end

  describe "parse_invoice/1" do
    test "returns error for non-string input" do
      assert {:error, "Input must be an XML string"} = ExCius.parse_invoice(123)
      assert {:error, "Input must be an XML string"} = ExCius.parse_invoice(%{})
      assert {:error, "Input must be an XML string"} = ExCius.parse_invoice(nil)
    end

    test "returns error for invalid XML" do
      invalid_xml = "this is not xml"
      {:error, reason} = ExCius.parse_invoice(invalid_xml)
      assert is_binary(reason)
      assert String.contains?(reason, "XML parsing failed")
    end

    test "returns error for malformed XML" do
      malformed_xml = "<?xml version=\"1.0\"?><Invoice><cbc:ID>123</Invoice>"
      {:error, reason} = ExCius.parse_invoice(malformed_xml)
      assert is_binary(reason)
    end

    # Note: These tests were commented out due to the SweetXML parsing issue
    # Uncommenting to see the actual errors

    test "parses valid UBL XML back to invoice data" do
      {:ok, xml} = ExCius.generate_invoice(@valid_invoice_data)
      {:ok, parsed_data} = ExCius.parse_invoice(xml)

      assert parsed_data.id == "TEST-001"
      assert parsed_data.operator_name == "Test Operator"
      assert parsed_data.currency_code == "EUR"
      assert parsed_data.supplier.registration_name == "Test Supplier Ltd"
      assert parsed_data.customer.registration_name == "Test Customer Ltd"
    end

    test "preserves optional fields during parsing" do
      {:ok, xml} = ExCius.generate_invoice(@valid_invoice_with_optionals)
      {:ok, parsed_data} = ExCius.parse_invoice(xml)

      assert parsed_data.due_date == "2025-05-31"
      assert parsed_data.payment_method.payment_means_code == "30"
      assert "Custom note 1" in parsed_data.notes
      assert "Custom note 2" in parsed_data.notes
    end
  end

  describe "validate_invoice/1" do
    test "validates correct invoice data successfully" do
      {:ok, validated_data} = ExCius.validate_invoice(@valid_invoice_data)

      assert validated_data.id == "TEST-001"
      assert validated_data.operator_name == "Test Operator"
      assert validated_data.currency_code == "EUR"
      assert %Date{} = validated_data.issue_date
      assert %Time{} = validated_data.issue_time
    end

    test "validates invoice with optional fields" do
      {:ok, validated_data} = ExCius.validate_invoice(@valid_invoice_with_optionals)

      assert validated_data.due_date == "2025-05-31"
      assert validated_data.payment_method.payment_means_code == "30"
      assert validated_data.notes == ["Custom note 1", "Custom note 2"]
    end

    test "returns validation errors for missing required fields" do
      incomplete_data = %{
        id: "TEST-001",
        currency_code: "EUR"
      }

      {:error, errors} = ExCius.validate_invoice(incomplete_data)

      assert is_map(errors)
      assert Map.has_key?(errors, :issue_datetime)
      assert Map.has_key?(errors, :operator_name)
    end

    test "validates supplier and customer data" do
      invalid_supplier =
        Map.put(@valid_invoice_data, :supplier, %{
          oib: "invalid_oib",
          registration_name: "",
          postal_address: %{},
          party_tax_scheme: %{}
        })

      {:error, errors} = ExCius.validate_invoice(invalid_supplier)

      assert Map.has_key?(errors, :supplier)
    end

    test "validates tax and monetary totals" do
      invalid_tax =
        Map.put(@valid_invoice_data, :tax_total, %{
          tax_amount: "invalid",
          tax_subtotals: []
        })

      {:error, errors} = ExCius.validate_invoice(invalid_tax)

      assert Map.has_key?(errors, :tax_total)
    end

    test "validates invoice lines" do
      invalid_lines =
        Map.put(@valid_invoice_data, :invoice_lines, [
          %{
            id: "",
            quantity: -1,
            unit_code: "invalid",
            item: %{},
            price: %{}
          }
        ])

      {:error, errors} = ExCius.validate_invoice(invalid_lines)

      assert Map.has_key?(errors, :invoice_lines)
    end

    test "returns error for non-map input" do
      assert {:error, %{input: "must be a map"}} = ExCius.validate_invoice("string")
      assert {:error, %{input: "must be a map"}} = ExCius.validate_invoice(123)
      assert {:error, %{input: "must be a map"}} = ExCius.validate_invoice(nil)
    end
  end

  describe "round_trip_test/1" do
    test "returns error for non-map input" do
      assert {:error, "Input must be a map"} = ExCius.round_trip_test("string")
      assert {:error, "Input must be a map"} = ExCius.round_trip_test(123)
      assert {:error, "Input must be a map"} = ExCius.round_trip_test(nil)
    end

    test "returns validation error for invalid input" do
      invalid_data = %{id: "test"}
      {:error, errors} = ExCius.round_trip_test(invalid_data)

      assert is_map(errors)
      assert Map.has_key?(errors, :operator_name)
    end

    # Note: These tests were commented out due to the SweetXML parsing issue
    # Uncommenting to see the actual errors

    test "successfully performs round-trip with valid data" do
      {:ok, {xml, parsed_data}} = ExCius.round_trip_test(@valid_invoice_data)

      assert is_binary(xml)
      assert String.contains?(xml, "TEST-001")

      assert parsed_data.id == "TEST-001"
      assert parsed_data.operator_name == "Test Operator"
      assert parsed_data.currency_code == "EUR"
    end

    test "preserves data integrity through round-trip" do
      {:ok, {_xml, parsed_data}} = ExCius.round_trip_test(@valid_invoice_with_optionals)

      assert parsed_data.due_date == "2025-05-31"
      assert parsed_data.payment_method.payment_means_code == "30"
      assert "Custom note 1" in parsed_data.notes
    end
  end

  describe "version/0" do
    test "returns version string" do
      version = ExCius.version()
      assert is_binary(version)
      assert version =~ ~r/\d+\.\d+\.\d+/ or version == "unknown"
    end
  end

  describe "info/0" do
    test "returns library information" do
      info = ExCius.info()

      assert is_map(info)
      assert info.ubl_version == "2.1"
      assert info.croatian_cius == "2025"
      assert info.supported_currencies == ["EUR"]

      assert is_list(info.mandatory_features)
      assert "operator_notes" in info.mandatory_features
      assert "croatian_date_format" in info.mandatory_features

      assert is_list(info.optional_features)
      assert "payment_means" in info.optional_features
      assert "due_dates" in info.optional_features
    end

    test "info contains valid version" do
      info = ExCius.info()
      assert is_binary(info.library_version)
    end
  end

  describe "integration tests" do
    test "generate_invoice and validate_invoice work together" do
      # First validate
      {:ok, validated_data} = ExCius.validate_invoice(@valid_invoice_data)

      # Then generate - should work since data is valid
      {:ok, xml} = ExCius.generate_invoice(@valid_invoice_data)

      assert String.contains?(xml, validated_data.id)
      assert String.contains?(xml, validated_data.operator_name)
    end

    test "handles various datetime formats" do
      datetime_variants = [
        "2025-05-01T12:00:00",
        "2025-05-01T12:00:00Z",
        "2025-05-01T12:00:00+02:00"
      ]

      Enum.each(datetime_variants, fn datetime ->
        data = Map.put(@valid_invoice_data, :issue_datetime, datetime)
        {:ok, xml} = ExCius.generate_invoice(data)
        assert String.contains?(xml, "<cbc:IssueDate>2025-05-01</cbc:IssueDate>")
        # Time might vary based on timezone parsing, just check time element exists
        assert String.contains?(xml, "<cbc:IssueTime>")
      end)
    end

    test "handles different tax rates correctly" do
      # Test with 13% VAT (reduced rate)
      reduced_vat_data =
        @valid_invoice_data
        |> put_in([:tax_total, :tax_subtotals, Access.at(0), :tax_category, :percent], 13)
        |> put_in([:tax_total, :tax_subtotals, Access.at(0), :tax_amount], "13.00")
        |> put_in([:tax_total, :tax_amount], "13.00")
        |> put_in([:legal_monetary_total, :tax_inclusive_amount], "113.00")
        |> put_in([:legal_monetary_total, :payable_amount], "113.00")
        |> put_in([:invoice_lines, Access.at(0), :item, :classified_tax_category, :percent], 13)

      {:ok, xml} = ExCius.generate_invoice(reduced_vat_data)
      assert String.contains?(xml, "<cbc:Percent>13</cbc:Percent>")
      assert String.contains?(xml, "<cbc:TaxAmount currencyID=\"EUR\">13.00</cbc:TaxAmount>")
    end
  end
end
