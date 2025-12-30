defmodule ExCius.InvoiceTemplateXMLTest do
  use ExUnit.Case

  alias ExCius.{InvoiceTemplateXML, RequestParams}

  describe "build_xml/1" do
    test "generates UBL Invoice XML from valid request params" do
      params = %{
        id: "5-P1-1",
        issue_datetime: "2025-05-01T12:00:00",
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
              name: "Managed bookkeeping services",
              classified_tax_category: %{
                id: "standard_rate",
                percent: 25,
                tax_scheme_id: "vat"
              },
              commodity_classification: %{
                item_classification_code: "82990000",
                list_id: "CG"
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

      assert String.contains?(xml, "<cbc:Name>Managed bookkeeping services</cbc:Name>")

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
        id: "INV-003",
        issue_datetime: "2025-07-01T16:00:00",
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
          },
          seller_contact: %{
            id: "33333333333",
            name: "Operater3"
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

      {:ok, validated_params} = RequestParams.new(params)
      xml = InvoiceTemplateXML.build_xml(validated_params)

      # Should not contain optional elements
      refute String.contains?(xml, "<cbc:DueDate>")
      refute String.contains?(xml, "<cac:PaymentMeans>")
      refute String.contains?(xml, "<cac:Contact>")
      assert String.contains?(xml, "<cac:SellerContact>")

      # Should always contain mandatory operator notes (two separate notes)
      assert String.contains?(xml, "<cbc:Note>")
      assert String.contains?(xml, "<cbc:Note>Operater: Operater3</cbc:Note>")
      assert String.contains?(xml, "Vrijeme izdavanja: 01. 07. 2025. u 16:00")

      # Should still have required elements
      assert String.contains?(xml, "<cbc:ID>INV-003</cbc:ID>")
      assert String.contains?(xml, "<cbc:ProfileID>P1</cbc:ProfileID>")
      assert String.contains?(xml, "<cbc:InvoiceTypeCode>380</cbc:InvoiceTypeCode>")
    end

    test "handles multiple invoice lines correctly" do
      params = %{
        id: "INV-002",
        issue_datetime: "2025-06-01T14:30:00",
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
          },
          seller_contact: %{
            id: "11111111119",
            name: "Operater2"
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
              },
              commodity_classification: %{
                item_classification_code: "73211200",
                list_id: "CG"
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
              },
              commodity_classification: %{
                item_classification_code: "73211200",
                list_id: "CG"
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
      assert String.contains?(xml, "<cbc:Note>Operater: Operater2</cbc:Note>")
      assert String.contains?(xml, "Vrijeme izdavanja: 01. 06. 2025. u 14:30")
    end

    test "generates XML with embedded PDF attachment" do
      base64_content = Base.encode64("PDF content here")

      params = %{
        id: "INV-ATTACH-001",
        issue_datetime: "2025-05-01T12:00:00",
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
          },
          seller_contact: %{
            id: "12345678901",
            name: "Operator1"
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
        ],
        attachments: [
          %{
            id: "1",
            filename: "INV-ATTACH-001.pdf",
            mime_code: "application/pdf",
            content: base64_content
          }
        ]
      }

      {:ok, validated_params} = RequestParams.new(params)
      xml = InvoiceTemplateXML.build_xml(validated_params)

      # Check AdditionalDocumentReference structure
      assert String.contains?(xml, "<cac:AdditionalDocumentReference>")
      assert String.contains?(xml, "<cbc:ID>1</cbc:ID>")
      assert String.contains?(xml, "<cac:Attachment>")
      assert String.contains?(xml, "<cbc:EmbeddedDocumentBinaryObject")
      assert String.contains?(xml, "filename=\"INV-ATTACH-001.pdf\"")
      assert String.contains?(xml, "mimeCode=\"application/pdf\"")
      assert String.contains?(xml, base64_content)
      assert String.contains?(xml, "</cbc:EmbeddedDocumentBinaryObject>")
      assert String.contains?(xml, "</cac:Attachment>")
      assert String.contains?(xml, "</cac:AdditionalDocumentReference>")
    end

    test "generates XML with multiple attachments" do
      pdf_content = Base.encode64("PDF content")
      image_content = Base.encode64("PNG content")

      params = %{
        id: "INV-MULTI-001",
        issue_datetime: "2025-05-01T12:00:00",
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
          },
          seller_contact: %{
            id: "12345678901",
            name: "Operator1"
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
        ],
        attachments: [
          %{
            id: "1",
            filename: "invoice.pdf",
            mime_code: "application/pdf",
            content: pdf_content
          },
          %{
            id: "2",
            filename: "logo.png",
            mime_code: "image/png",
            content: image_content
          }
        ]
      }

      {:ok, validated_params} = RequestParams.new(params)
      xml = InvoiceTemplateXML.build_xml(validated_params)

      # Should have two AdditionalDocumentReference elements
      assert xml |> String.split("<cac:AdditionalDocumentReference>") |> length() == 3

      # Check both attachments
      assert String.contains?(xml, "filename=\"invoice.pdf\"")
      assert String.contains?(xml, "mimeCode=\"application/pdf\"")
      assert String.contains?(xml, "filename=\"logo.png\"")
      assert String.contains?(xml, "mimeCode=\"image/png\"")
    end

    test "generates XML without attachments when not provided" do
      params = %{
        id: "INV-NO-ATTACH",
        issue_datetime: "2025-05-01T12:00:00",
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
          },
          seller_contact: %{
            id: "12345678901",
            name: "Operator1"
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

      {:ok, validated_params} = RequestParams.new(params)
      xml = InvoiceTemplateXML.build_xml(validated_params)

      # Should NOT contain AdditionalDocumentReference
      refute String.contains?(xml, "<cac:AdditionalDocumentReference>")
      refute String.contains?(xml, "<cbc:EmbeddedDocumentBinaryObject")
    end

    test "generates XML with VAT cash accounting (Obračun PDV po naplati) when true" do
      params = %{
        id: "VAT-CASH-1",
        issue_datetime: "2025-12-01T12:00:00",
        currency_code: "EUR",
        vat_cash_accounting: true,
        supplier: %{
          oib: "12345678901",
          registration_name: "TVRTKA A d.o.o.",
          postal_address: %{
            street_name: "Ulica 1",
            city_name: "ZAGREB",
            postal_zone: "10000",
            country_code: "HR"
          },
          party_tax_scheme: %{
            company_id: "HR12345678901",
            tax_scheme_id: "vat"
          },
          seller_contact: %{
            id: "12345678901",
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
              classified_tax_category: %{
                id: "standard_rate",
                percent: 25,
                tax_scheme_id: "vat"
              },
              commodity_classification: %{
                item_classification_code: "62.20.20",
                list_id: "CG"
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

      # Should contain HRFISK20Data extension with HRObracunPDVPoNaplati
      assert String.contains?(xml, "<hrextac:HRFISK20Data>")

      assert String.contains?(
               xml,
               "<hrextac:HRObracunPDVPoNaplati>Obračun po naplaćenoj naknadi</hrextac:HRObracunPDVPoNaplati>"
             )

      # Should have correct namespace
      assert String.contains?(
               xml,
               "xmlns:hrextac=\"urn:mfin.gov.hr:schema:xsd:HRExtensionAggregateComponents-1\""
             )
    end

    test "generates XML with custom VAT cash accounting text" do
      params = %{
        id: "VAT-CASH-2",
        issue_datetime: "2025-12-01T12:00:00",
        currency_code: "EUR",
        vat_cash_accounting: "Custom cash accounting note",
        supplier: %{
          oib: "12345678901",
          registration_name: "TVRTKA A d.o.o.",
          postal_address: %{
            street_name: "Ulica 1",
            city_name: "ZAGREB",
            postal_zone: "10000",
            country_code: "HR"
          },
          party_tax_scheme: %{
            company_id: "HR12345678901",
            tax_scheme_id: "vat"
          },
          seller_contact: %{
            id: "12345678901",
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
              classified_tax_category: %{
                id: "standard_rate",
                percent: 25,
                tax_scheme_id: "vat"
              },
              commodity_classification: %{
                item_classification_code: "62.20.20",
                list_id: "CG"
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

      # Should contain custom text
      assert String.contains?(
               xml,
               "<hrextac:HRObracunPDVPoNaplati>Custom cash accounting note</hrextac:HRObracunPDVPoNaplati>"
             )
    end

    test "generates XML with delivery date (ActualDeliveryDate)" do
      params = %{
        id: "DELIVERY-TEST",
        issue_datetime: "2025-12-01T12:00:00",
        currency_code: "EUR",
        delivery_date: "2025-09-25",
        supplier: %{
          oib: "12345678901",
          registration_name: "TVRTKA A d.o.o.",
          postal_address: %{
            street_name: "Ulica 1",
            city_name: "ZAGREB",
            postal_zone: "10000",
            country_code: "HR"
          },
          party_tax_scheme: %{
            company_id: "HR12345678901",
            tax_scheme_id: "vat"
          },
          seller_contact: %{
            id: "12345678901",
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
              classified_tax_category: %{
                id: "standard_rate",
                percent: 25,
                tax_scheme_id: "vat"
              },
              commodity_classification: %{
                item_classification_code: "62.20.20",
                list_id: "CG"
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

      # Should contain Delivery element with ActualDeliveryDate
      assert String.contains?(xml, "<cac:Delivery>")
      assert String.contains?(xml, "<cbc:ActualDeliveryDate>2025-09-25</cbc:ActualDeliveryDate>")
    end

    test "generates XML with reverse charge (AE) and TaxExemptionReason" do
      params = %{
        id: "REVERSE-CHARGE-TEST",
        issue_datetime: "2025-12-01T12:00:00",
        currency_code: "EUR",
        delivery_date: "2025-09-25",
        supplier: %{
          oib: "12345678901",
          registration_name: "TVRTKA A d.o.o.",
          postal_address: %{
            street_name: "Ulica 1",
            city_name: "ZAGREB",
            postal_zone: "10000",
            country_code: "HR"
          },
          party_tax_scheme: %{
            company_id: "HR12345678901",
            tax_scheme_id: "vat"
          },
          seller_contact: %{
            id: "12345678901",
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
        tax_total: %{
          tax_amount: "0.00",
          tax_subtotals: [
            %{
              taxable_amount: "100.00",
              tax_amount: "0.00",
              tax_category: %{
                id: "reverse_charge",
                percent: 0,
                tax_scheme_id: "vat",
                tax_exemption_reason:
                  "Prijenos porezne obveze čl. 75. st. 3. t. c) Zakona o PDV-u"
              }
            }
          ]
        },
        legal_monetary_total: %{
          line_extension_amount: "100.00",
          tax_exclusive_amount: "100.00",
          tax_inclusive_amount: "100.00",
          payable_amount: "100.00"
        },
        invoice_lines: [
          %{
            id: "1",
            quantity: 1.0,
            unit_code: "piece",
            line_extension_amount: "100.00",
            item: %{
              name: "Proizvod",
              classified_tax_category: %{
                id: "reverse_charge",
                name: "HR:AE",
                percent: 0,
                tax_scheme_id: "vat"
              },
              commodity_classification: %{
                item_classification_code: "62.20.20",
                list_id: "CG"
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

      # Should contain AE tax category with exemption reason
      assert String.contains?(xml, "<cbc:ID>AE</cbc:ID>")
      assert String.contains?(xml, "<cbc:TaxExemptionReason>Prijenos porezne obveze")
    end

    test "auto-generates Croatian tax category name based on percent" do
      # Test that HR:PDV25 is automatically generated for 25% VAT
      params = %{
        id: "TAX-NAME-AUTO",
        issue_datetime: "2025-12-01T12:00:00",
        currency_code: "EUR",
        supplier: %{
          oib: "12345678901",
          registration_name: "TVRTKA A d.o.o.",
          postal_address: %{
            street_name: "Ulica 1",
            city_name: "ZAGREB",
            postal_zone: "10000",
            country_code: "HR"
          },
          party_tax_scheme: %{
            company_id: "HR12345678901",
            tax_scheme_id: "vat"
          },
          seller_contact: %{
            id: "12345678901",
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
              classified_tax_category: %{
                id: "standard_rate",
                percent: 25,
                tax_scheme_id: "vat"
                # Note: no :name provided - should auto-generate HR:PDV25
              },
              commodity_classification: %{
                item_classification_code: "62.20.20",
                list_id: "CG"
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

      # Should auto-generate HR:PDV25 for 25% VAT
      assert String.contains?(xml, "<cbc:Name>HR:PDV25</cbc:Name>")
    end

    test "auto-generates correct Croatian tax names for all rates" do
      # Helper to build params with specific tax percent
      build_params = fn percent ->
        %{
          id: "TAX-NAME-#{percent}",
          issue_datetime: "2025-12-01T12:00:00",
          currency_code: "EUR",
          supplier: %{
            oib: "12345678901",
            registration_name: "TVRTKA A d.o.o.",
            postal_address: %{
              street_name: "Ulica 1",
              city_name: "ZAGREB",
              postal_zone: "10000",
              country_code: "HR"
            },
            party_tax_scheme: %{company_id: "HR12345678901", tax_scheme_id: "vat"},
            seller_contact: %{id: "12345678901", name: "Operater1"}
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
            party_tax_scheme: %{company_id: "HR11111111119", tax_scheme_id: "vat"}
          },
          tax_total: %{
            tax_amount: "0.00",
            tax_subtotals: [
              %{
                taxable_amount: "100.00",
                tax_amount: "0.00",
                tax_category: %{id: "standard_rate", percent: percent, tax_scheme_id: "vat"}
              }
            ]
          },
          legal_monetary_total: %{
            line_extension_amount: "100.00",
            tax_exclusive_amount: "100.00",
            tax_inclusive_amount: "100.00",
            payable_amount: "100.00"
          },
          invoice_lines: [
            %{
              id: "1",
              quantity: 1.0,
              unit_code: "piece",
              line_extension_amount: "100.00",
              item: %{
                name: "Proizvod",
                classified_tax_category: %{
                  id: "standard_rate",
                  percent: percent,
                  tax_scheme_id: "vat"
                },
                commodity_classification: %{item_classification_code: "62.20.20", list_id: "CG"}
              },
              price: %{price_amount: "100.00"}
            }
          ]
        }
      end

      # Test all Croatian VAT rates
      test_cases = [
        {0, "HR:Z"},
        {5, "HR:PDV5"},
        {13, "HR:PDV13"},
        {25, "HR:PDV25"}
      ]

      for {percent, expected_name} <- test_cases do
        {:ok, validated_params} = RequestParams.new(build_params.(percent))
        xml = InvoiceTemplateXML.build_xml(validated_params)

        assert String.contains?(xml, "<cbc:Name>#{expected_name}</cbc:Name>"),
               "Expected #{expected_name} for #{percent}% VAT"
      end
    end

    test "generates XML with HR tax extension for exempt invoices" do
      params = %{
        id: "EXEMPT-HR-EXT",
        issue_datetime: "2025-12-01T12:00:00",
        currency_code: "EUR",
        delivery_date: "2025-09-25",
        hr_tax_extension: true,
        out_of_scope_amount: "0.00",
        supplier: %{
          oib: "12345678901",
          registration_name: "TVRTKA A d.o.o.",
          postal_address: %{
            street_name: "Ulica 1",
            city_name: "ZAGREB",
            postal_zone: "10000",
            country_code: "HR"
          },
          party_tax_scheme: %{
            company_id: "HR12345678901",
            tax_scheme_id: "vat"
          },
          seller_contact: %{
            id: "12345678901",
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
        tax_total: %{
          tax_amount: "0.00",
          tax_subtotals: [
            %{
              taxable_amount: "100.00",
              tax_amount: "0.00",
              tax_category: %{
                id: "exempt",
                percent: 0,
                tax_scheme_id: "vat",
                tax_exemption_reason: "Oslobođeno PDV čl..."
              }
            }
          ]
        },
        legal_monetary_total: %{
          line_extension_amount: "100.00",
          tax_exclusive_amount: "100.00",
          tax_inclusive_amount: "100.00",
          payable_amount: "100.00"
        },
        invoice_lines: [
          %{
            id: "1",
            quantity: 1.0,
            unit_code: "piece",
            line_extension_amount: "100.00",
            item: %{
              name: "Proizvod",
              classified_tax_category: %{
                id: "exempt",
                percent: 0,
                tax_scheme_id: "vat",
                tax_exemption_reason: "Oslobođeno PDV čl..."
              },
              commodity_classification: %{
                item_classification_code: "62.20.20",
                list_id: "CG"
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

      # Should contain HRFISK20Data with HRTaxTotal
      assert String.contains?(xml, "<hrextac:HRFISK20Data>")
      assert String.contains?(xml, "<hrextac:HRTaxTotal>")
      assert String.contains?(xml, "<hrextac:HRTaxSubtotal>")
      assert String.contains?(xml, "<hrextac:HRTaxCategory>")
      assert String.contains?(xml, "<cbc:Name>HR:E</cbc:Name>")

      assert String.contains?(
               xml,
               "<cbc:TaxExemptionReason>Oslobođeno PDV čl...</cbc:TaxExemptionReason>"
             )

      assert String.contains?(xml, "<hrextac:HRTaxScheme>")

      # Should contain HRLegalMonetaryTotal
      assert String.contains?(xml, "<hrextac:HRLegalMonetaryTotal>")
      assert String.contains?(xml, "<hrextac:OutOfScopeOfVATAmount")
    end

    test "generates XML for not-in-VAT-system supplier with FRE tax scheme" do
      params = %{
        id: "NOT-IN-VAT",
        issue_datetime: "2025-12-01T12:00:00",
        currency_code: "EUR",
        delivery_date: "2025-09-25",
        hr_tax_extension: true,
        supplier: %{
          oib: "12345678901",
          registration_name: "TVRTKA A d.o.o.",
          postal_address: %{
            street_name: "Ulica 1",
            city_name: "ZAGREB",
            postal_zone: "10000",
            country_code: "HR"
          },
          party_tax_scheme: %{
            company_id: "12345678901",
            tax_scheme_id: "fre"
          },
          seller_contact: %{
            id: "12345678901",
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
        tax_total: %{
          tax_amount: "0.00",
          tax_subtotals: [
            %{
              taxable_amount: "100.00",
              tax_amount: "0.00",
              tax_category: %{
                id: "exempt",
                percent: 0,
                tax_scheme_id: "vat",
                tax_exemption_reason: "Nije u sustavu PDV čl..."
              }
            }
          ]
        },
        legal_monetary_total: %{
          line_extension_amount: "100.00",
          tax_exclusive_amount: "100.00",
          tax_inclusive_amount: "100.00",
          payable_amount: "100.00"
        },
        invoice_lines: [
          %{
            id: "1",
            quantity: 1.0,
            unit_code: "piece",
            line_extension_amount: "100.00",
            item: %{
              name: "Proizvod",
              classified_tax_category: %{
                id: "exempt",
                percent: 0,
                tax_scheme_id: "vat",
                tax_exemption_reason: "Nije u sustavu PDV čl..."
              },
              commodity_classification: %{
                item_classification_code: "62.20.20",
                list_id: "CG"
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

      # Should have FRE tax scheme for supplier
      assert String.contains?(xml, "<cbc:ID>FRE</cbc:ID>")

      # Should contain HR extension
      assert String.contains?(xml, "<hrextac:HRFISK20Data>")

      assert String.contains?(
               xml,
               "<cbc:TaxExemptionReason>Nije u sustavu PDV čl...</cbc:TaxExemptionReason>"
             )
    end

    test "generates XML without VAT cash accounting extension when not provided" do
      params = %{
        id: "NO-VAT-CASH",
        issue_datetime: "2025-12-01T12:00:00",
        currency_code: "EUR",
        supplier: %{
          oib: "12345678901",
          registration_name: "TVRTKA A d.o.o.",
          postal_address: %{
            street_name: "Ulica 1",
            city_name: "ZAGREB",
            postal_zone: "10000",
            country_code: "HR"
          },
          party_tax_scheme: %{
            company_id: "HR12345678901",
            tax_scheme_id: "vat"
          },
          seller_contact: %{
            id: "12345678901",
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
              classified_tax_category: %{
                id: "standard_rate",
                percent: 25,
                tax_scheme_id: "vat"
              },
              commodity_classification: %{
                item_classification_code: "62.20.20",
                list_id: "CG"
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

      # Should NOT contain HRFISK20Data extension
      refute String.contains?(xml, "<hrextac:HRFISK20Data>")
      refute String.contains?(xml, "<hrextac:HRObracunPDVPoNaplati>")
    end
  end
end
