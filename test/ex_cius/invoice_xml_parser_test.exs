defmodule ExCius.InvoiceXmlParserTest do
  use ExUnit.Case

  alias ExCius.{InvoiceXmlParserFixed, InvoiceTemplateXML, RequestParams}

  describe "parse/1" do
    test "parses complete UBL Invoice XML with all fields" do
      # First generate XML from known parameters
      original_params = %{
        id: "5-P1-1",
        issue_datetime: "2025-05-01T12:00:00",
        operator_name: "Operater1",
        currency_code: "EUR",
        due_date: "2025-05-31",
        business_process: "billing",
        invoice_type_code: "commercial_invoice",
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
          contact: %{
            name: "IME PREZIME",
            electronic_mail: "ii@mail.hr"
          },
          seller_contact: %{
            id: "51634872748",
            name: "Operater1"
          }
        },
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
        },
        payment_method: %{
          payment_means_code: "30",
          instruction_note: "Opis plaćanja",
          payment_id: "HR00 123456",
          payee_financial_account_id: "HRXXXXXXXXXXXXXXXX"
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
              name: "Proizvod",
              commodity_classification: %{
                item_classification_code: "62.90.90"
              },
              classified_tax_category: %{
                id: "standard_rate",
                name: "HR:PDV25",
                percent: 25,
                tax_scheme_id: "vat"
              }
            },
            price: %{
              price_amount: "100.00",
              base_quantity: 1.0,
              unit_code: "piece"
            }
          }
        ],
        notes: [
          "Napomena o računu",
          "Dodatne informacije"
        ]
      }

      # Generate XML
      {:ok, validated_params} = RequestParams.new(original_params)
      xml = InvoiceTemplateXML.build_xml(validated_params)

      # Parse XML back to parameters
      {:ok, parsed_params} = InvoiceXmlParserFixed.parse(xml)

      # Verify basic invoice data
      assert parsed_params.id == "5-P1-1"
      assert parsed_params.issue_datetime == "2025-05-01T12:00:00"
      assert parsed_params.operator_name == "Operater1"
      assert parsed_params.currency_code == "EUR"
      assert parsed_params.due_date == "2025-05-31"
      assert parsed_params.business_process == "billing"
      assert parsed_params.invoice_type_code == "commercial_invoice"

      # Verify supplier data
      supplier = parsed_params.supplier
      assert supplier.oib == "12345678901"
      assert supplier.registration_name == "FINANCIJSKA AGENCIJA"

      # Verify supplier address
      assert supplier.postal_address.street_name == "VRTNI PUT 3"
      assert supplier.postal_address.city_name == "ZAGREB"
      assert supplier.postal_address.postal_zone == "10000"
      assert supplier.postal_address.country_code == "HR"

      # Verify supplier tax scheme
      assert supplier.party_tax_scheme.company_id == "HR12345678901"
      assert supplier.party_tax_scheme.tax_scheme_id == "vat"

      # Verify supplier contact
      assert supplier.contact.name == "IME PREZIME"
      assert supplier.contact.email == "ii@mail.hr"

      # Verify seller contact
      assert supplier.seller_contact.id == "51634872748"
      assert supplier.seller_contact.name == "Operater1"

      # Verify customer data
      customer = parsed_params.customer
      assert customer.oib == "11111111119"
      assert customer.registration_name == "Tvrtka B d.o.o."

      # Verify customer address
      assert customer.postal_address.street_name == "Ulica 2"
      assert customer.postal_address.city_name == "RIJEKA"
      assert customer.postal_address.postal_zone == "51000"
      assert customer.postal_address.country_code == "HR"

      # Verify customer tax scheme
      assert customer.party_tax_scheme.company_id == "HR11111111119"
      assert customer.party_tax_scheme.tax_scheme_id == "vat"

      # Verify payment method
      payment = parsed_params.payment_method
      assert payment.payment_means_code == "30"
      assert payment.instruction_note == "Opis plaćanja"
      assert payment.payment_id == "HR00 123456"
      assert payment.payee_financial_account_id == "HRXXXXXXXXXXXXXXXX"

      # Verify tax total
      tax_total = parsed_params.tax_total
      assert tax_total.tax_amount == "25.00"
      assert length(tax_total.tax_subtotals) == 1

      subtotal = hd(tax_total.tax_subtotals)
      assert subtotal.taxable_amount == "100.00"
      assert subtotal.tax_amount == "25.00"
      assert subtotal.tax_category.id == "standard_rate"
      assert subtotal.tax_category.percent == 25
      assert subtotal.tax_category.tax_scheme_id == "vat"

      # Verify legal monetary total
      monetary = parsed_params.legal_monetary_total
      assert monetary.line_extension_amount == "100.00"
      assert monetary.tax_exclusive_amount == "100.00"
      assert monetary.tax_inclusive_amount == "125.00"
      assert monetary.payable_amount == "125.00"

      # Verify invoice lines
      assert length(parsed_params.invoice_lines) == 1
      line = hd(parsed_params.invoice_lines)
      assert line.id == "1"
      assert line.quantity == 1.0
      assert line.unit_code == "piece"
      assert line.line_extension_amount == "100.00"

      # Verify item
      item = line.item
      assert item.name == "Proizvod"
      assert item.commodity_classification.item_classification_code == "62.90.90"
      assert item.classified_tax_category.id == "standard_rate"
      assert item.classified_tax_category.name == "HR:PDV25"
      assert item.classified_tax_category.percent == 25
      assert item.classified_tax_category.tax_scheme_id == "vat"

      # Verify price
      price = line.price
      assert price.price_amount == "100.000000"
      assert price.base_quantity == 1.0
      assert price.unit_code == "piece"

      # Verify user notes (excluding mandatory operator notes)
      assert length(parsed_params.notes) == 2
      assert "Napomena o računu" in parsed_params.notes
      assert "Dodatne informacije" in parsed_params.notes
    end

    test "parses minimal UBL Invoice XML without optional fields" do
      original_params = %{
        id: "INV-001",
        issue_datetime: "2025-05-01T12:00:00",
        operator_name: "Operator1",
        currency_code: "EUR",
        supplier: %{
          oib: "12345678901",
          registration_name: "Supplier d.o.o.",
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
          registration_name: "Customer d.o.o.",
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
        ]
      }

      # Generate XML
      {:ok, validated_params} = RequestParams.new(original_params)
      xml = InvoiceTemplateXML.build_xml(validated_params)

      # Parse XML back to parameters
      {:ok, parsed_params} = InvoiceXmlParserFixed.parse(xml)

      # Verify basic data is present
      assert parsed_params.id == "INV-001"
      assert parsed_params.operator_name == "Operator1"
      assert parsed_params.currency_code == "EUR"

      # Verify optional fields are not present
      refute Map.has_key?(parsed_params, :due_date)
      refute Map.has_key?(parsed_params, :payment_method)
      refute Map.has_key?(parsed_params, :notes)
      refute Map.has_key?(parsed_params.supplier, :contact)
      refute Map.has_key?(parsed_params.supplier, :seller_contact)
      refute Map.has_key?(parsed_params.customer, :contact)

      refute Map.has_key?(
               parsed_params.invoice_lines |> hd() |> Map.get(:item),
               :commodity_classification
             )

      refute Map.has_key?(parsed_params.invoice_lines |> hd() |> Map.get(:price), :base_quantity)
    end

    test "handles multiple invoice lines correctly" do
      original_params = %{
        id: "INV-002",
        issue_datetime: "2025-05-01T12:00:00",
        operator_name: "Operator1",
        currency_code: "EUR",
        supplier: %{
          oib: "12345678901",
          registration_name: "Supplier d.o.o.",
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
          registration_name: "Customer d.o.o.",
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
          tax_amount: "50.00",
          tax_subtotals: [
            %{
              taxable_amount: "200.00",
              tax_amount: "50.00",
              tax_category: %{
                id: "standard_rate",
                percent: 25,
                tax_scheme_id: "vat"
              }
            }
          ]
        },
        legal_monetary_total: %{
          line_extension_amount: "200.00",
          tax_exclusive_amount: "200.00",
          tax_inclusive_amount: "250.00",
          payable_amount: "250.00"
        },
        invoice_lines: [
          %{
            id: "1",
            quantity: 1.0,
            unit_code: "piece",
            line_extension_amount: "100.00",
            item: %{
              name: "Product 1",
              classified_tax_category: %{
                id: "standard_rate",
                percent: 25,
                tax_scheme_id: "vat"
              }
            },
            price: %{
              price_amount: "100.00"
            }
          },
          %{
            id: "2",
            quantity: 2.0,
            unit_code: "piece",
            line_extension_amount: "100.00",
            item: %{
              name: "Product 2",
              classified_tax_category: %{
                id: "standard_rate",
                percent: 25,
                tax_scheme_id: "vat"
              }
            },
            price: %{
              price_amount: "50.00"
            }
          }
        ]
      }

      # Generate XML
      {:ok, validated_params} = RequestParams.new(original_params)
      xml = InvoiceTemplateXML.build_xml(validated_params)

      # Parse XML back to parameters
      {:ok, parsed_params} = InvoiceXmlParserFixed.parse(xml)

      # Verify multiple lines are parsed
      assert length(parsed_params.invoice_lines) == 2

      line1 = Enum.find(parsed_params.invoice_lines, &(&1.id == "1"))
      line2 = Enum.find(parsed_params.invoice_lines, &(&1.id == "2"))

      assert line1.item.name == "Product 1"
      assert line1.quantity == 1.0
      assert line1.price.price_amount == "100.000000"

      assert line2.item.name == "Product 2"
      assert line2.quantity == 2.0
      assert line2.price.price_amount == "50.000000"
    end

    test "handles different tax categories and rates" do
      original_params = %{
        id: "INV-003",
        issue_datetime: "2025-05-01T12:00:00",
        operator_name: "Operator1",
        currency_code: "EUR",
        supplier: %{
          oib: "12345678901",
          registration_name: "Supplier d.o.o.",
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
          registration_name: "Customer d.o.o.",
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
          tax_amount: "13.00",
          tax_subtotals: [
            %{
              taxable_amount: "100.00",
              tax_amount: "13.00",
              tax_category: %{
                id: "standard_rate",
                percent: 13,
                tax_scheme_id: "vat"
              }
            }
          ]
        },
        legal_monetary_total: %{
          line_extension_amount: "100.00",
          tax_exclusive_amount: "100.00",
          tax_inclusive_amount: "113.00",
          payable_amount: "113.00"
        },
        invoice_lines: [
          %{
            id: "1",
            quantity: 1.0,
            unit_code: "piece",
            line_extension_amount: "100.00",
            item: %{
              name: "Reduced Rate Product",
              classified_tax_category: %{
                id: "standard_rate",
                percent: 13,
                tax_scheme_id: "vat"
              }
            },
            price: %{
              price_amount: "100.00"
            }
          }
        ]
      }

      # Generate XML
      {:ok, validated_params} = RequestParams.new(original_params)
      xml = InvoiceTemplateXML.build_xml(validated_params)

      # Parse XML back to parameters
      {:ok, parsed_params} = InvoiceXmlParserFixed.parse(xml)

      # Verify tax rate is preserved
      tax_category = parsed_params.tax_total.tax_subtotals |> hd() |> Map.get(:tax_category)
      assert tax_category.percent == 13
      assert tax_category.id == "standard_rate"

      line_tax_category =
        parsed_params.invoice_lines |> hd() |> Map.get(:item) |> Map.get(:classified_tax_category)

      assert line_tax_category.percent == 13
    end

    test "round-trip parsing preserves data integrity" do
      # Test that parsing and re-generating XML produces equivalent results
      original_params = %{
        id: "ROUND-TRIP-TEST",
        issue_datetime: "2025-12-21T09:49:00",
        operator_name: "Test Operator",
        currency_code: "EUR",
        due_date: "2025-12-31",
        supplier: %{
          oib: "98765432109",
          registration_name: "Test Supplier Ltd",
          postal_address: %{
            street_name: "Test Street 123",
            city_name: "Test City",
            postal_zone: "12345",
            country_code: "HR"
          },
          party_tax_scheme: %{
            company_id: "HR98765432109",
            tax_scheme_id: "vat"
          }
        },
        customer: %{
          oib: "19876543210",
          registration_name: "Test Customer Inc",
          postal_address: %{
            street_name: "Customer Ave 456",
            city_name: "Customer Town",
            postal_zone: "67890",
            country_code: "HR"
          },
          party_tax_scheme: %{
            company_id: "HR19876543210",
            tax_scheme_id: "vat"
          }
        },
        tax_total: %{
          tax_amount: "12.50",
          tax_subtotals: [
            %{
              taxable_amount: "50.00",
              tax_amount: "12.50",
              tax_category: %{
                id: "standard_rate",
                percent: 25,
                tax_scheme_id: "vat"
              }
            }
          ]
        },
        legal_monetary_total: %{
          line_extension_amount: "50.00",
          tax_exclusive_amount: "50.00",
          tax_inclusive_amount: "62.50",
          payable_amount: "62.50"
        },
        invoice_lines: [
          %{
            id: "RT1",
            quantity: 0.5,
            unit_code: "piece",
            line_extension_amount: "50.00",
            item: %{
              name: "Round Trip Test Item",
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
        notes: [
          "Test note 1",
          "Test note 2"
        ]
      }

      # First round: original -> XML -> parsed
      {:ok, validated_params1} = RequestParams.new(original_params)
      xml1 = InvoiceTemplateXML.build_xml(validated_params1)
      {:ok, parsed_params1} = InvoiceXmlParserFixed.parse(xml1)

      # Second round: parsed -> XML -> parsed again
      {:ok, validated_params2} = RequestParams.new(parsed_params1)
      xml2 = InvoiceTemplateXML.build_xml(validated_params2)
      {:ok, parsed_params2} = InvoiceXmlParserFixed.parse(xml2)

      # Key data should be identical after round-trip
      assert parsed_params1.id == parsed_params2.id
      assert parsed_params1.operator_name == parsed_params2.operator_name
      assert parsed_params1.currency_code == parsed_params2.currency_code
      assert parsed_params1.supplier.oib == parsed_params2.supplier.oib

      assert parsed_params1.customer.registration_name ==
               parsed_params2.customer.registration_name

      assert parsed_params1.tax_total.tax_amount == parsed_params2.tax_total.tax_amount
      assert length(parsed_params1.invoice_lines) == length(parsed_params2.invoice_lines)
    end

    test "handles invalid XML gracefully" do
      invalid_xml = "not valid xml"
      assert {:error, _reason} = InvoiceXmlParserFixed.parse(invalid_xml)
    end

    test "handles non-string input gracefully" do
      assert {:error, "Invalid input: expected XML string"} = InvoiceXmlParserFixed.parse(123)
      assert {:error, "Invalid input: expected XML string"} = InvoiceXmlParserFixed.parse(%{})
    end

    test "parses example VAT 25% XML file" do
      # Read the example XML file
      example_xml = File.read!("priv/examples/example_vat25.xml")

      {:ok, parsed_params} = InvoiceXmlParserFixed.parse(example_xml)

      # Verify basic structure matches the example
      assert parsed_params.id == "5-P1-1"
      assert parsed_params.issue_datetime == "2025-05-01T12:00:00"
      assert parsed_params.currency_code == "EUR"
      assert parsed_params.due_date == "2025-05-31"

      # Verify supplier from example
      assert parsed_params.supplier.oib == "12345678901"
      assert parsed_params.supplier.registration_name == "FINANCIJSKA AGENCIJA"
      assert parsed_params.supplier.postal_address.street_name == "VRTNI PUT 3"
      assert parsed_params.supplier.postal_address.city_name == "ZAGREB"

      # Verify customer from example
      assert parsed_params.customer.oib == "11111111119"
      assert parsed_params.customer.registration_name == "Tvrtka B d.o.o."
      assert parsed_params.customer.postal_address.street_name == "Ulica 2"
      assert parsed_params.customer.postal_address.city_name == "RIJEKA"

      # Verify tax data
      assert parsed_params.tax_total.tax_amount == "25.00"
      subtotal = hd(parsed_params.tax_total.tax_subtotals)
      assert subtotal.taxable_amount == "100.00"
      assert subtotal.tax_amount == "25.00"
      assert subtotal.tax_category.percent == 25

      # Verify invoice line
      assert length(parsed_params.invoice_lines) == 1
      line = hd(parsed_params.invoice_lines)
      assert line.id == "1"
      assert line.quantity == 1.0
      assert line.item.name == "Proizvod"

      # Note: The example XML doesn't have operator notes, so operator_name will be nil
      # The operator name is extracted from the operator note in the XML
      # If not found as a note, it won't be present in parsed params
      assert !Map.has_key?(parsed_params, :operator_name) || is_nil(parsed_params.operator_name)
    end
  end
end
