defmodule ExCius.InvoiceTemplateXMLTest do
  use ExUnit.Case

  alias ExCius.{InvoiceTemplateXML, RequestParams}

  describe "build_xml/1" do
    test "generates UBL Invoice XML from valid request params" do
      params = %{
        id: "5-P1-1",
        issue_datetime: "2025-05-01T12:00:00",
        operator_name: "Operater1",
        currency_code: "EUR",
        due_date: "2025-05-31",
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

      {:ok, validated_params} = RequestParams.new(params)
      xml = InvoiceTemplateXML.build_xml(validated_params)

      # Basic XML structure checks
      assert String.starts_with?(xml, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
      assert String.contains?(xml, "<Invoice xmlns=")
      assert String.contains?(xml, "<cbc:ID>5-P1-1</cbc:ID>")
      assert String.contains?(xml, "<cbc:IssueDate>2025-05-01</cbc:IssueDate>")
      assert String.contains?(xml, "<cbc:IssueTime>12:00:00</cbc:IssueTime>")
      assert String.contains?(xml, "<cbc:DueDate>2025-05-31</cbc:DueDate>")
      assert String.contains?(xml, "<cbc:InvoiceTypeCode>380</cbc:InvoiceTypeCode>")
      assert String.contains?(xml, "<cbc:DocumentCurrencyCode>EUR</cbc:DocumentCurrencyCode>")

      # Supplier party checks
      assert String.contains?(xml, "<cac:AccountingSupplierParty>")

      assert String.contains?(
               xml,
               "<cbc:EndpointID schemeID=\"9934\">12345678901</cbc:EndpointID>"
             )

      assert String.contains?(
               xml,
               "<cbc:RegistrationName>FINANCIJSKA AGENCIJA</cbc:RegistrationName>"
             )

      assert String.contains?(xml, "<cbc:StreetName>VRTNI PUT 3</cbc:StreetName>")

      # Customer party checks
      assert String.contains?(xml, "<cac:AccountingCustomerParty>")

      assert String.contains?(
               xml,
               "<cbc:EndpointID schemeID=\"9934\">11111111119</cbc:EndpointID>"
             )

      assert String.contains?(xml, "<cbc:RegistrationName>Tvrtka B d.o.o.</cbc:RegistrationName>")

      # Payment means checks
      assert String.contains?(xml, "<cac:PaymentMeans>")
      assert String.contains?(xml, "<cbc:PaymentMeansCode>30</cbc:PaymentMeansCode>")
      assert String.contains?(xml, "<cbc:InstructionNote>Opis plaćanja</cbc:InstructionNote>")

      # Tax total checks
      assert String.contains?(xml, "<cac:TaxTotal>")
      assert String.contains?(xml, "<cbc:TaxAmount currencyID=\"EUR\">25.00</cbc:TaxAmount>")
      assert String.contains?(xml, "<cbc:Percent>25</cbc:Percent>")

      # Legal monetary total checks
      assert String.contains?(xml, "<cac:LegalMonetaryTotal>")

      assert String.contains?(
               xml,
               "<cbc:LineExtensionAmount currencyID=\"EUR\">100.00</cbc:LineExtensionAmount>"
             )

      assert String.contains?(
               xml,
               "<cbc:PayableAmount currencyID=\"EUR\">125.00</cbc:PayableAmount>"
             )

      # Invoice line checks
      assert String.contains?(xml, "<cac:InvoiceLine>")

      assert String.contains?(
               xml,
               "<cbc:InvoicedQuantity unitCode=\"H87\">1.000</cbc:InvoicedQuantity>"
             )

      assert String.contains?(xml, "<cbc:Name>Proizvod</cbc:Name>")

      assert String.contains?(
               xml,
               "<cbc:PriceAmount currencyID=\"EUR\">100.000000</cbc:PriceAmount>"
             )

      # Mandatory operator notes checks (two separate notes)
      assert String.contains?(xml, "<cbc:Note>")
      assert String.contains?(xml, "<cbc:Note>Operater: Operater1</cbc:Note>")

      assert String.contains?(
               xml,
               "<cbc:Note>Vrijeme izdavanja: 01. 05. 2025. u 12:00</cbc:Note>"
             )

      # User notes should also be present
      assert String.contains?(xml, "Napomena o računu")
      assert String.contains?(xml, "Dodatne informacije")

      # Ensure proper XML closing
      assert String.ends_with?(xml, "</Invoice>")
    end

    test "generates XML without optional fields" do
      params = %{
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

      {:ok, validated_params} = RequestParams.new(params)
      xml = InvoiceTemplateXML.build_xml(validated_params)

      # Should not contain optional elements
      refute String.contains?(xml, "<cbc:DueDate>")
      refute String.contains?(xml, "<cac:PaymentMeans>")
      refute String.contains?(xml, "<cac:Contact>")
      refute String.contains?(xml, "<cac:SellerContact>")

      # Should always contain mandatory operator notes (two separate notes)
      assert String.contains?(xml, "<cbc:Note>")
      assert String.contains?(xml, "<cbc:Note>Operater: Operator1</cbc:Note>")
      assert String.contains?(xml, "Vrijeme izdavanja: 01. 05. 2025. u 12:00")

      # Should still have required elements
      assert String.contains?(xml, "<cbc:ID>INV-001</cbc:ID>")
      assert String.contains?(xml, "<cbc:ProfileID>P1</cbc:ProfileID>")
      assert String.contains?(xml, "<cbc:InvoiceTypeCode>380</cbc:InvoiceTypeCode>")
    end

    test "handles multiple invoice lines correctly" do
      params = %{
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

      {:ok, validated_params} = RequestParams.new(params)
      xml = InvoiceTemplateXML.build_xml(validated_params)

      # Should contain both invoice lines
      # 1 + 2 lines
      assert xml |> String.split("<cac:InvoiceLine>") |> length() == 3
      assert String.contains?(xml, "<cbc:Name>Product 1</cbc:Name>")
      assert String.contains?(xml, "<cbc:Name>Product 2</cbc:Name>")

      assert String.contains?(
               xml,
               "<cbc:InvoicedQuantity unitCode=\"H87\">2.000</cbc:InvoicedQuantity>"
             )

      # Should always contain mandatory operator notes (two separate notes)
      assert String.contains?(xml, "<cbc:Note>")
      assert String.contains?(xml, "<cbc:Note>Operater: Operator1</cbc:Note>")
      assert String.contains?(xml, "Vrijeme izdavanja: 01. 05. 2025. u 12:00")
    end
  end
end
