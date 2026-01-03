defmodule ExCius.InvoiceWithAllowanceChargesTest do
  use ExUnit.Case, async: true

  alias ExCius.RequestParams
  alias ExCius.InvoiceTemplateXML

  describe "invoice with document-level allowances and charges" do
    test "generates valid XML with document-level charge (shipping fee)" do
      params = %{
        id: "INV-WITH-SHIPPING",
        issue_datetime: "2025-05-01T12:00:00",
        currency_code: "EUR",
        supplier: %{
          oib: "12345678901",
          registration_name: "Supplier d.o.o.",
          postal_address: %{
            street_name: "Ulica 1",
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
          registration_name: "Customer d.o.o.",
          postal_address: %{
            street_name: "Ulica 2",
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
          tax_amount: "28.75",
          tax_subtotals: [
            %{
              taxable_amount: "115.00",
              tax_amount: "28.75",
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
          tax_exclusive_amount: "115.00",
          tax_inclusive_amount: "143.75",
          payable_amount: "143.75"
        },
        invoice_lines: [
          %{
            id: "1",
            quantity: 1.0,
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
            price: %{
              price_amount: "100.00"
            }
          }
        ],
        allowance_charges: [
          %{
            charge_indicator: true,
            allowance_charge_reason_code: :freight,
            allowance_charge_reason: "Shipping and handling",
            amount: "15.00",
            tax_category: %{
              id: :standard_rate,
              percent: 25,
              tax_scheme_id: :vat
            }
          }
        ]
      }

      assert {:ok, validated_params} = RequestParams.new(params)
      xml = InvoiceTemplateXML.build_xml(validated_params)

      assert xml =~ "<cac:AllowanceCharge>"
      assert xml =~ "<cbc:ChargeIndicator>true</cbc:ChargeIndicator>"
      assert xml =~ "<cbc:AllowanceChargeReasonCode>FI</cbc:AllowanceChargeReasonCode>"
      assert xml =~ "<cbc:AllowanceChargeReason>Shipping and handling</cbc:AllowanceChargeReason>"
      assert xml =~ "<cbc:Amount currencyID=\"EUR\">15.00</cbc:Amount>"
      assert xml =~ "<cac:TaxCategory>"
      assert xml =~ "<cbc:ID>S</cbc:ID>"
    end

    test "generates valid XML with document-level discount" do
      params = %{
        id: "INV-WITH-DISCOUNT",
        issue_datetime: "2025-05-01T12:00:00",
        currency_code: "EUR",
        supplier: %{
          oib: "12345678901",
          registration_name: "Supplier d.o.o.",
          postal_address: %{
            street_name: "Ulica 1",
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
          registration_name: "Customer d.o.o.",
          postal_address: %{
            street_name: "Ulica 2",
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
          tax_amount: "22.50",
          tax_subtotals: [
            %{
              taxable_amount: "90.00",
              tax_amount: "22.50",
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
          tax_exclusive_amount: "90.00",
          tax_inclusive_amount: "112.50",
          payable_amount: "112.50"
        },
        invoice_lines: [
          %{
            id: "1",
            quantity: 1.0,
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
            price: %{
              price_amount: "100.00"
            }
          }
        ],
        allowance_charges: [
          %{
            charge_indicator: false,
            allowance_charge_reason_code: :discount,
            allowance_charge_reason: "Loyalty discount 10%",
            multiplier_factor_numeric: 10,
            base_amount: "100.00",
            amount: "10.00",
            tax_category: %{
              id: :standard_rate,
              percent: 25,
              tax_scheme_id: :vat
            }
          }
        ]
      }

      assert {:ok, validated_params} = RequestParams.new(params)
      xml = InvoiceTemplateXML.build_xml(validated_params)

      assert xml =~ "<cac:AllowanceCharge>"
      assert xml =~ "<cbc:ChargeIndicator>false</cbc:ChargeIndicator>"
      assert xml =~ "<cbc:AllowanceChargeReasonCode>95</cbc:AllowanceChargeReasonCode>"
      assert xml =~ "<cbc:AllowanceChargeReason>Loyalty discount 10%</cbc:AllowanceChargeReason>"
      assert xml =~ "<cbc:MultiplierFactorNumeric>10</cbc:MultiplierFactorNumeric>"
      assert xml =~ "<cbc:Amount currencyID=\"EUR\">10.00</cbc:Amount>"
      assert xml =~ "<cbc:BaseAmount currencyID=\"EUR\">100.00</cbc:BaseAmount>"
    end

    test "generates valid XML with non-taxable charge (Croatian Povratna naknada)" do
      params = %{
        id: "INV-WITH-DEPOSIT",
        issue_datetime: "2025-05-01T12:00:00",
        currency_code: "EUR",
        supplier: %{
          oib: "12345678901",
          registration_name: "Supplier d.o.o.",
          postal_address: %{
            street_name: "Ulica 1",
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
          registration_name: "Customer d.o.o.",
          postal_address: %{
            street_name: "Ulica 2",
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
          tax_exclusive_amount: "100.50",
          tax_inclusive_amount: "125.50",
          payable_amount: "125.50"
        },
        invoice_lines: [
          %{
            id: "1",
            quantity: 1.0,
            unit_code: "piece",
            line_extension_amount: "100.00",
            item: %{
              name: "Beverage",
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
        allowance_charges: [
          %{
            charge_indicator: true,
            allowance_charge_reason_code: :deposit_fee,
            allowance_charge_reason: "Povratna naknada",
            amount: "0.50",
            tax_category: %{
              id: :outside_scope,
              percent: 0,
              tax_scheme_id: :vat,
              tax_exemption_reason: "Povratna naknada - izvan područja primjene PDV-a"
            }
          }
        ]
      }

      assert {:ok, validated_params} = RequestParams.new(params)
      xml = InvoiceTemplateXML.build_xml(validated_params)

      assert xml =~ "<cac:AllowanceCharge>"
      assert xml =~ "<cbc:ChargeIndicator>true</cbc:ChargeIndicator>"
      assert xml =~ "<cbc:AllowanceChargeReason>Povratna naknada</cbc:AllowanceChargeReason>"
      assert xml =~ "<cbc:ID>O</cbc:ID>"
      assert xml =~ "<cbc:Percent>0</cbc:Percent>"

      assert xml =~
               "<cbc:TaxExemptionReason>Povratna naknada - izvan područja primjene PDV-a</cbc:TaxExemptionReason>"
    end

    test "generates valid XML with multiple document-level allowances and charges" do
      params = %{
        id: "INV-MULTI-AC",
        issue_datetime: "2025-05-01T12:00:00",
        currency_code: "EUR",
        supplier: %{
          oib: "12345678901",
          registration_name: "Supplier d.o.o.",
          postal_address: %{
            street_name: "Ulica 1",
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
          registration_name: "Customer d.o.o.",
          postal_address: %{
            street_name: "Ulica 2",
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
          tax_amount: "26.25",
          tax_subtotals: [
            %{
              taxable_amount: "105.00",
              tax_amount: "26.25",
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
          tax_exclusive_amount: "105.00",
          tax_inclusive_amount: "131.25",
          payable_amount: "131.25"
        },
        invoice_lines: [
          %{
            id: "1",
            quantity: 1.0,
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
            price: %{
              price_amount: "100.00"
            }
          }
        ],
        allowance_charges: [
          %{
            charge_indicator: true,
            allowance_charge_reason: "Shipping",
            amount: "15.00",
            tax_category: %{
              id: :standard_rate,
              percent: 25,
              tax_scheme_id: :vat
            }
          },
          %{
            charge_indicator: false,
            allowance_charge_reason: "Discount",
            amount: "10.00",
            tax_category: %{
              id: :standard_rate,
              percent: 25,
              tax_scheme_id: :vat
            }
          }
        ]
      }

      assert {:ok, validated_params} = RequestParams.new(params)
      xml = InvoiceTemplateXML.build_xml(validated_params)

      # Count occurrences of AllowanceCharge
      allowance_charge_count =
        xml
        |> String.split("<cac:AllowanceCharge>")
        |> length()
        |> Kernel.-(1)

      assert allowance_charge_count == 2
      assert xml =~ "Shipping"
      assert xml =~ "Discount"
    end
  end

  describe "invoice with line-level allowances and charges" do
    test "generates valid XML with line-level discount" do
      params = %{
        id: "INV-LINE-DISCOUNT",
        issue_datetime: "2025-05-01T12:00:00",
        currency_code: "EUR",
        supplier: %{
          oib: "12345678901",
          registration_name: "Supplier d.o.o.",
          postal_address: %{
            street_name: "Ulica 1",
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
          registration_name: "Customer d.o.o.",
          postal_address: %{
            street_name: "Ulica 2",
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
          tax_amount: "22.50",
          tax_subtotals: [
            %{
              taxable_amount: "90.00",
              tax_amount: "22.50",
              tax_category: %{
                id: "standard_rate",
                percent: 25,
                tax_scheme_id: "vat"
              }
            }
          ]
        },
        legal_monetary_total: %{
          line_extension_amount: "90.00",
          tax_exclusive_amount: "90.00",
          tax_inclusive_amount: "112.50",
          payable_amount: "112.50"
        },
        invoice_lines: [
          %{
            id: "1",
            quantity: 10.0,
            unit_code: "piece",
            line_extension_amount: "90.00",
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
            price: %{
              price_amount: "10.00"
            },
            allowance_charges: [
              %{
                charge_indicator: false,
                allowance_charge_reason_code: :discount,
                allowance_charge_reason: "Volume discount",
                multiplier_factor_numeric: 10,
                base_amount: "100.00",
                amount: "10.00"
              }
            ]
          }
        ]
      }

      assert {:ok, validated_params} = RequestParams.new(params)
      xml = InvoiceTemplateXML.build_xml(validated_params)

      assert xml =~ "<cac:InvoiceLine>"
      assert xml =~ "<cac:AllowanceCharge>"
      assert xml =~ "<cbc:ChargeIndicator>false</cbc:ChargeIndicator>"
      assert xml =~ "<cbc:AllowanceChargeReason>Volume discount</cbc:AllowanceChargeReason>"
      assert xml =~ "<cbc:MultiplierFactorNumeric>10</cbc:MultiplierFactorNumeric>"

      # Line-level should NOT have TaxCategory within AllowanceCharge
      # Check that TaxCategory appears after TaxScheme for the line item but not inside AllowanceCharge
      # This is a bit tricky to test - we check that within InvoiceLine there's no TaxCategory inside AllowanceCharge

      # Extract the InvoiceLine section
      [_before, invoice_line_section] = String.split(xml, "<cac:InvoiceLine>", parts: 2)

      [invoice_line_content, _after] =
        String.split(invoice_line_section, "</cac:InvoiceLine>", parts: 2)

      # Extract the AllowanceCharge section within the line
      if String.contains?(invoice_line_content, "<cac:AllowanceCharge>") do
        [_before_ac, ac_section] =
          String.split(invoice_line_content, "<cac:AllowanceCharge>", parts: 2)

        [ac_content, _after_ac] = String.split(ac_section, "</cac:AllowanceCharge>", parts: 2)

        # Line-level AllowanceCharge should NOT contain TaxCategory
        refute String.contains?(ac_content, "<cac:TaxCategory>")
      end
    end

    test "generates valid XML with multiple line-level allowances/charges" do
      params = %{
        id: "INV-MULTI-LINE-AC",
        issue_datetime: "2025-05-01T12:00:00",
        currency_code: "EUR",
        supplier: %{
          oib: "12345678901",
          registration_name: "Supplier d.o.o.",
          postal_address: %{
            street_name: "Ulica 1",
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
          registration_name: "Customer d.o.o.",
          postal_address: %{
            street_name: "Ulica 2",
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
          tax_amount: "23.75",
          tax_subtotals: [
            %{
              taxable_amount: "95.00",
              tax_amount: "23.75",
              tax_category: %{
                id: "standard_rate",
                percent: 25,
                tax_scheme_id: "vat"
              }
            }
          ]
        },
        legal_monetary_total: %{
          line_extension_amount: "95.00",
          tax_exclusive_amount: "95.00",
          tax_inclusive_amount: "118.75",
          payable_amount: "118.75"
        },
        invoice_lines: [
          %{
            id: "1",
            quantity: 10.0,
            unit_code: "piece",
            line_extension_amount: "95.00",
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
            price: %{
              price_amount: "10.00"
            },
            allowance_charges: [
              %{
                charge_indicator: false,
                allowance_charge_reason: "Bulk discount",
                amount: "10.00"
              },
              %{
                charge_indicator: true,
                allowance_charge_reason: "Special handling",
                amount: "5.00"
              }
            ]
          }
        ]
      }

      assert {:ok, validated_params} = RequestParams.new(params)
      xml = InvoiceTemplateXML.build_xml(validated_params)

      assert xml =~ "Bulk discount"
      assert xml =~ "Special handling"
    end
  end

  describe "invoice with both document and line level allowances/charges" do
    test "generates valid XML with allowances/charges at both levels" do
      params = %{
        id: "INV-BOTH-LEVELS",
        issue_datetime: "2025-05-01T12:00:00",
        currency_code: "EUR",
        supplier: %{
          oib: "12345678901",
          registration_name: "Supplier d.o.o.",
          postal_address: %{
            street_name: "Ulica 1",
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
          registration_name: "Customer d.o.o.",
          postal_address: %{
            street_name: "Ulica 2",
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
          tax_amount: "26.25",
          tax_subtotals: [
            %{
              taxable_amount: "105.00",
              tax_amount: "26.25",
              tax_category: %{
                id: "standard_rate",
                percent: 25,
                tax_scheme_id: "vat"
              }
            }
          ]
        },
        legal_monetary_total: %{
          line_extension_amount: "90.00",
          tax_exclusive_amount: "105.00",
          tax_inclusive_amount: "131.25",
          payable_amount: "131.25"
        },
        invoice_lines: [
          %{
            id: "1",
            quantity: 10.0,
            unit_code: "piece",
            line_extension_amount: "90.00",
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
            price: %{
              price_amount: "10.00"
            },
            allowance_charges: [
              %{
                charge_indicator: false,
                allowance_charge_reason: "Line item discount",
                amount: "10.00"
              }
            ]
          }
        ],
        allowance_charges: [
          %{
            charge_indicator: true,
            allowance_charge_reason: "Document level shipping",
            amount: "15.00",
            tax_category: %{
              id: :standard_rate,
              percent: 25,
              tax_scheme_id: :vat
            }
          }
        ]
      }

      assert {:ok, validated_params} = RequestParams.new(params)
      xml = InvoiceTemplateXML.build_xml(validated_params)

      assert xml =~ "Document level shipping"
      assert xml =~ "Line item discount"

      # Document level should appear before TaxTotal
      doc_level_pos = :binary.match(xml, "Document level shipping") |> elem(0)
      tax_total_pos = :binary.match(xml, "<cac:TaxTotal>") |> elem(0)
      assert doc_level_pos < tax_total_pos

      # Line level should appear within InvoiceLine
      invoice_line_pos = :binary.match(xml, "<cac:InvoiceLine>") |> elem(0)
      line_discount_pos = :binary.match(xml, "Line item discount") |> elem(0)
      assert line_discount_pos > invoice_line_pos
    end
  end

  describe "validation errors" do
    test "fails when document-level allowance/charge is missing tax_category" do
      params = %{
        id: "INV-INVALID",
        issue_datetime: "2025-05-01T12:00:00",
        currency_code: "EUR",
        supplier: %{
          oib: "12345678901",
          registration_name: "Supplier d.o.o.",
          postal_address: %{
            street_name: "Ulica 1",
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
          registration_name: "Customer d.o.o.",
          postal_address: %{
            street_name: "Ulica 2",
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
            price: %{
              price_amount: "100.00"
            }
          }
        ],
        allowance_charges: [
          %{
            charge_indicator: true,
            amount: "15.00"
            # Missing tax_category!
          }
        ]
      }

      assert {:error, errors} = RequestParams.new(params)
      assert errors[:allowance_charges]
    end

    test "fails when allowance/charge amount is invalid" do
      params = %{
        id: "INV-INVALID-AMOUNT",
        issue_datetime: "2025-05-01T12:00:00",
        currency_code: "EUR",
        supplier: %{
          oib: "12345678901",
          registration_name: "Supplier d.o.o.",
          postal_address: %{
            street_name: "Ulica 1",
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
          registration_name: "Customer d.o.o.",
          postal_address: %{
            street_name: "Ulica 2",
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
            price: %{
              price_amount: "100.00"
            }
          }
        ],
        allowance_charges: [
          %{
            charge_indicator: true,
            amount: "not-a-number",
            tax_category: %{
              id: :standard_rate,
              percent: 25,
              tax_scheme_id: :vat
            }
          }
        ]
      }

      assert {:error, errors} = RequestParams.new(params)
      assert errors[:allowance_charges]
    end
  end
end
