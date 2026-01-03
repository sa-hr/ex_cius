defmodule ExCius.AllowanceChargeXMLTest do
  use ExUnit.Case, async: true

  alias ExCius.AllowanceChargeXML

  describe "build_document_level_list/2" do
    test "returns empty list for nil" do
      assert AllowanceChargeXML.build_document_level_list(nil, "EUR") == []
    end

    test "returns empty list for empty list" do
      assert AllowanceChargeXML.build_document_level_list([], "EUR") == []
    end

    test "builds XML for a document-level charge with tax category" do
      charges = [
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

      [xml_element] = AllowanceChargeXML.build_document_level_list(charges, "EUR")
      xml_string = XmlBuilder.generate(xml_element)

      assert xml_string =~ "<cac:AllowanceCharge>"
      assert xml_string =~ "<cbc:ChargeIndicator>true</cbc:ChargeIndicator>"
      assert xml_string =~ "<cbc:AllowanceChargeReasonCode>FI</cbc:AllowanceChargeReasonCode>"

      assert xml_string =~
               "<cbc:AllowanceChargeReason>Shipping and handling</cbc:AllowanceChargeReason>"

      assert xml_string =~ "<cbc:Amount currencyID=\"EUR\">15.00</cbc:Amount>"
      assert xml_string =~ "<cac:TaxCategory>"
      assert xml_string =~ "<cbc:ID>S</cbc:ID>"
      assert xml_string =~ "<cbc:Percent>25</cbc:Percent>"
      assert xml_string =~ "<cac:TaxScheme>"
      assert xml_string =~ "<cbc:ID>VAT</cbc:ID>"
    end

    test "builds XML for a document-level discount with percentage" do
      discounts = [
        %{
          charge_indicator: false,
          allowance_charge_reason_code: :discount,
          allowance_charge_reason: "Loyalty discount",
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

      [xml_element] = AllowanceChargeXML.build_document_level_list(discounts, "EUR")
      xml_string = XmlBuilder.generate(xml_element)

      assert xml_string =~ "<cbc:ChargeIndicator>false</cbc:ChargeIndicator>"
      assert xml_string =~ "<cbc:AllowanceChargeReasonCode>95</cbc:AllowanceChargeReasonCode>"

      assert xml_string =~
               "<cbc:AllowanceChargeReason>Loyalty discount</cbc:AllowanceChargeReason>"

      assert xml_string =~ "<cbc:MultiplierFactorNumeric>10</cbc:MultiplierFactorNumeric>"
      assert xml_string =~ "<cbc:Amount currencyID=\"EUR\">10.00</cbc:Amount>"
      assert xml_string =~ "<cbc:BaseAmount currencyID=\"EUR\">100.00</cbc:BaseAmount>"
    end

    test "builds XML for non-taxable charge with exemption reason (Croatian Povratna naknada)" do
      charges = [
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

      [xml_element] = AllowanceChargeXML.build_document_level_list(charges, "EUR")
      xml_string = XmlBuilder.generate(xml_element)

      assert xml_string =~ "<cbc:ChargeIndicator>true</cbc:ChargeIndicator>"
      assert xml_string =~ "<cbc:ID>O</cbc:ID>"
      assert xml_string =~ "<cbc:Percent>0</cbc:Percent>"

      assert xml_string =~
               "<cbc:TaxExemptionReason>Povratna naknada - izvan područja primjene PDV-a</cbc:TaxExemptionReason>"
    end

    test "builds XML with tax exemption reason code" do
      charges = [
        %{
          charge_indicator: true,
          amount: "10.00",
          tax_category: %{
            id: :exempt,
            percent: 0,
            tax_scheme_id: :vat,
            tax_exemption_reason: "Exempt transaction",
            tax_exemption_reason_code: "vatex-eu-e"
          }
        }
      ]

      [xml_element] = AllowanceChargeXML.build_document_level_list(charges, "EUR")
      xml_string = XmlBuilder.generate(xml_element)

      assert xml_string =~ "<cbc:ID>E</cbc:ID>"
      assert xml_string =~ "<cbc:TaxExemptionReason>Exempt transaction</cbc:TaxExemptionReason>"
      assert xml_string =~ "<cbc:TaxExemptionReasonCode>vatex-eu-e</cbc:TaxExemptionReasonCode>"
    end

    test "builds multiple allowances and charges" do
      items = [
        %{
          charge_indicator: true,
          allowance_charge_reason: "Shipping",
          amount: "15.00",
          tax_category: %{id: :standard_rate, percent: 25, tax_scheme_id: :vat}
        },
        %{
          charge_indicator: false,
          allowance_charge_reason: "Discount",
          amount: "20.00",
          tax_category: %{id: :standard_rate, percent: 25, tax_scheme_id: :vat}
        }
      ]

      xml_elements = AllowanceChargeXML.build_document_level_list(items, "EUR")
      assert length(xml_elements) == 2

      [charge, discount] = xml_elements
      charge_xml = XmlBuilder.generate(charge)
      discount_xml = XmlBuilder.generate(discount)

      assert charge_xml =~ "<cbc:ChargeIndicator>true</cbc:ChargeIndicator>"
      assert charge_xml =~ "Shipping"

      assert discount_xml =~ "<cbc:ChargeIndicator>false</cbc:ChargeIndicator>"
      assert discount_xml =~ "Discount"
    end

    test "omits optional fields when not provided" do
      charges = [
        %{
          charge_indicator: true,
          amount: "15.00",
          tax_category: %{
            id: :standard_rate,
            percent: 25,
            tax_scheme_id: :vat
          }
        }
      ]

      [xml_element] = AllowanceChargeXML.build_document_level_list(charges, "EUR")
      xml_string = XmlBuilder.generate(xml_element)

      assert xml_string =~ "<cbc:ChargeIndicator>true</cbc:ChargeIndicator>"
      assert xml_string =~ "<cbc:Amount currencyID=\"EUR\">15.00</cbc:Amount>"
      refute xml_string =~ "<cbc:AllowanceChargeReasonCode>"
      refute xml_string =~ "<cbc:AllowanceChargeReason>"
      refute xml_string =~ "<cbc:MultiplierFactorNumeric>"
      refute xml_string =~ "<cbc:BaseAmount"
    end
  end

  describe "build_line_level_list/2" do
    test "returns empty list for nil" do
      assert AllowanceChargeXML.build_line_level_list(nil, "EUR") == []
    end

    test "returns empty list for empty list" do
      assert AllowanceChargeXML.build_line_level_list([], "EUR") == []
    end

    test "builds XML for line-level discount without tax category" do
      discounts = [
        %{
          charge_indicator: false,
          allowance_charge_reason_code: :discount,
          allowance_charge_reason: "Volume discount",
          multiplier_factor_numeric: 5,
          base_amount: "200.00",
          amount: "10.00"
        }
      ]

      [xml_element] = AllowanceChargeXML.build_line_level_list(discounts, "EUR")
      xml_string = XmlBuilder.generate(xml_element)

      assert xml_string =~ "<cac:AllowanceCharge>"
      assert xml_string =~ "<cbc:ChargeIndicator>false</cbc:ChargeIndicator>"
      assert xml_string =~ "<cbc:AllowanceChargeReasonCode>95</cbc:AllowanceChargeReasonCode>"

      assert xml_string =~
               "<cbc:AllowanceChargeReason>Volume discount</cbc:AllowanceChargeReason>"

      assert xml_string =~ "<cbc:MultiplierFactorNumeric>5</cbc:MultiplierFactorNumeric>"
      assert xml_string =~ "<cbc:Amount currencyID=\"EUR\">10.00</cbc:Amount>"
      assert xml_string =~ "<cbc:BaseAmount currencyID=\"EUR\">200.00</cbc:BaseAmount>"
      # Line-level should NOT have TaxCategory
      refute xml_string =~ "<cac:TaxCategory>"
    end

    test "builds XML for line-level charge without tax category" do
      charges = [
        %{
          charge_indicator: true,
          allowance_charge_reason: "Special handling fee",
          amount: "5.00"
        }
      ]

      [xml_element] = AllowanceChargeXML.build_line_level_list(charges, "EUR")
      xml_string = XmlBuilder.generate(xml_element)

      assert xml_string =~ "<cbc:ChargeIndicator>true</cbc:ChargeIndicator>"

      assert xml_string =~
               "<cbc:AllowanceChargeReason>Special handling fee</cbc:AllowanceChargeReason>"

      assert xml_string =~ "<cbc:Amount currencyID=\"EUR\">5.00</cbc:Amount>"
      refute xml_string =~ "<cac:TaxCategory>"
    end

    test "builds multiple line-level items" do
      items = [
        %{charge_indicator: false, amount: "5.00"},
        %{charge_indicator: true, amount: "2.00"}
      ]

      xml_elements = AllowanceChargeXML.build_line_level_list(items, "EUR")
      assert length(xml_elements) == 2
    end
  end

  describe "build_document_level/2" do
    test "builds a single document-level element" do
      charge = %{
        charge_indicator: true,
        amount: "15.00",
        tax_category: %{
          id: :standard_rate,
          percent: 25,
          tax_scheme_id: :vat
        }
      }

      xml_element = AllowanceChargeXML.build_document_level(charge, "EUR")
      xml_string = XmlBuilder.generate(xml_element)

      assert xml_string =~ "<cac:AllowanceCharge>"
      assert xml_string =~ "<cac:TaxCategory>"
    end
  end

  describe "build_line_level/2" do
    test "builds a single line-level element" do
      discount = %{
        charge_indicator: false,
        amount: "10.00"
      }

      xml_element = AllowanceChargeXML.build_line_level(discount, "EUR")
      xml_string = XmlBuilder.generate(xml_element)

      assert xml_string =~ "<cac:AllowanceCharge>"
      refute xml_string =~ "<cac:TaxCategory>"
    end
  end

  describe "multiplier factor formatting" do
    test "formats integer multiplier factor" do
      charges = [
        %{
          charge_indicator: true,
          multiplier_factor_numeric: 10,
          amount: "10.00",
          tax_category: %{id: :standard_rate, percent: 25, tax_scheme_id: :vat}
        }
      ]

      [xml_element] = AllowanceChargeXML.build_document_level_list(charges, "EUR")
      xml_string = XmlBuilder.generate(xml_element)

      assert xml_string =~ "<cbc:MultiplierFactorNumeric>10</cbc:MultiplierFactorNumeric>"
    end

    test "formats float multiplier factor with decimals" do
      charges = [
        %{
          charge_indicator: true,
          multiplier_factor_numeric: 10.5,
          amount: "10.50",
          tax_category: %{id: :standard_rate, percent: 25, tax_scheme_id: :vat}
        }
      ]

      [xml_element] = AllowanceChargeXML.build_document_level_list(charges, "EUR")
      xml_string = XmlBuilder.generate(xml_element)

      assert xml_string =~ "<cbc:MultiplierFactorNumeric>10.50</cbc:MultiplierFactorNumeric>"
    end
  end

  describe "tax category codes" do
    test "uses correct code for standard_rate" do
      charges = [
        %{
          charge_indicator: true,
          amount: "10.00",
          tax_category: %{id: :standard_rate, percent: 25, tax_scheme_id: :vat}
        }
      ]

      [xml_element] = AllowanceChargeXML.build_document_level_list(charges, "EUR")
      xml_string = XmlBuilder.generate(xml_element)

      assert xml_string =~ "<cbc:ID>S</cbc:ID>"
    end

    test "uses correct code for zero_rate" do
      charges = [
        %{
          charge_indicator: true,
          amount: "10.00",
          tax_category: %{id: :zero_rate, percent: 0, tax_scheme_id: :vat}
        }
      ]

      [xml_element] = AllowanceChargeXML.build_document_level_list(charges, "EUR")
      xml_string = XmlBuilder.generate(xml_element)

      assert xml_string =~ "<cbc:ID>Z</cbc:ID>"
    end

    test "uses correct code for exempt" do
      charges = [
        %{
          charge_indicator: true,
          amount: "10.00",
          tax_category: %{id: :exempt, percent: 0, tax_scheme_id: :vat}
        }
      ]

      [xml_element] = AllowanceChargeXML.build_document_level_list(charges, "EUR")
      xml_string = XmlBuilder.generate(xml_element)

      assert xml_string =~ "<cbc:ID>E</cbc:ID>"
    end

    test "uses correct code for reverse_charge" do
      charges = [
        %{
          charge_indicator: true,
          amount: "10.00",
          tax_category: %{id: :reverse_charge, percent: 0, tax_scheme_id: :vat}
        }
      ]

      [xml_element] = AllowanceChargeXML.build_document_level_list(charges, "EUR")
      xml_string = XmlBuilder.generate(xml_element)

      assert xml_string =~ "<cbc:ID>AE</cbc:ID>"
    end

    test "uses correct code for outside_scope" do
      charges = [
        %{
          charge_indicator: true,
          amount: "10.00",
          tax_category: %{id: :outside_scope, percent: 0, tax_scheme_id: :vat}
        }
      ]

      [xml_element] = AllowanceChargeXML.build_document_level_list(charges, "EUR")
      xml_string = XmlBuilder.generate(xml_element)

      assert xml_string =~ "<cbc:ID>O</cbc:ID>"
    end
  end
end
