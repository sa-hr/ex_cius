defmodule ExCius.InvoiceXmlParser do
  @moduledoc """
  Parses UBL 2.1 Invoice XML documents back to the parameter structure used by ExCius.RequestParams.

  This module provides the reverse transformation of ExCius.InvoiceTemplateXML, taking
  a UBL Invoice XML document and extracting the data into the same parameter structure
  that can be validated and used by the ExCius system.

  ## Features

  - Parses complete UBL 2.1 Invoice XML documents
  - Extracts all invoice data including supplier, customer, tax, and line information
  - Handles optional fields gracefully
  - Converts UBL enum values back to internal representations
  - Parses mandatory operator notes back to operator_name
  - Supports Croatian CIUS-2025 compliant invoices

  ## Usage

      xml_content = File.read!("invoice.xml")
      {:ok, params} = ExCius.InvoiceXmlParser.parse(xml_content)

      # The params can now be used with RequestParams
      {:ok, validated_params} = ExCius.RequestParams.new(params)

  ## Supported Elements

  - Invoice identification and dates
  - Supplier and customer party information
  - Tax calculations and categories
  - Payment terms and methods
  - Invoice lines with items and pricing
  - Notes (including operator notes and user notes)
  """

  import SweetXml

  @doc """
  Parses a UBL Invoice XML document and returns parameter structure.

  Takes a UBL 2.1 Invoice XML document as a string and extracts all the
  invoice data into the parameter structure expected by ExCius.RequestParams.

  ## Parameters

  - `xml_content` - The UBL Invoice XML document as a string

  ## Returns

  - `{:ok, params}` - Successfully parsed parameters map
  - `{:error, reason}` - Parsing failed with error reason

  ## Examples

      iex> xml = "<?xml version=\\"1.0\\"?>..."
      iex> {:ok, params} = ExCius.InvoiceXmlParser.parse(xml)
      iex> params.id
      "5-P1-1"

  """
  def parse(xml_content) when is_binary(xml_content) do
    try do
      doc = SweetXml.parse(xml_content, quiet: true)
      params = extract_invoice_data(doc)
      {:ok, params}
    rescue
      e -> {:error, "XML parsing failed: #{Exception.message(e)}"}
    catch
      :exit, reason -> {:error, "XML parsing failed: #{inspect(reason)}"}
    end
  end

  def parse(_), do: {:error, "Invalid input: expected XML string"}

  defp extract_invoice_data(doc) do
    %{
      id: extract_id(doc),
      issue_datetime: extract_issue_datetime(doc),
      due_date: extract_due_date(doc),
      delivery_date: extract_delivery_date(doc),
      invoice_period_start: extract_invoice_period_start(doc),
      invoice_period_end: extract_invoice_period_end(doc),
      currency_code: extract_currency_code(doc),
      business_process: extract_business_process(doc),
      invoice_type_code: extract_invoice_type_code(doc),
      supplier: extract_supplier(doc),
      customer: extract_customer(doc),
      payment_method: extract_payment_method(doc),
      tax_total: extract_tax_total(doc),
      legal_monetary_total: extract_legal_monetary_total(doc),
      invoice_lines: extract_invoice_lines(doc),
      notes: extract_user_notes(doc),
      vat_cash_accounting: extract_vat_cash_accounting(doc)
    }
    |> filter_nil_values()
  end

  defp extract_id(doc) do
    doc
    |> xpath(~x"//Invoice/*[local-name()='ID']/text()"s)
  end

  defp extract_issue_datetime(doc) do
    date = doc |> xpath(~x"//*[local-name()='IssueDate']/text()"s)
    time = doc |> xpath(~x"//*[local-name()='IssueTime']/text()"s)

    case {date, time} do
      {"", _} -> nil
      {_, ""} -> nil
      {d, t} -> "#{d}T#{t}"
    end
  end

  defp extract_due_date(doc) do
    case doc |> xpath(~x"//*[local-name()='DueDate']/text()"s) do
      "" -> nil
      date -> date
    end
  end

  defp extract_delivery_date(doc) do
    case doc
         |> xpath(~x"//*[local-name()='Delivery']/*[local-name()='ActualDeliveryDate']/text()"s) do
      "" -> nil
      date -> date
    end
  end

  defp extract_invoice_period_start(doc) do
    case doc
         |> xpath(~x"//*[local-name()='InvoicePeriod']/*[local-name()='StartDate']/text()"s) do
      "" -> nil
      date -> date
    end
  end

  defp extract_invoice_period_end(doc) do
    case doc
         |> xpath(~x"//*[local-name()='InvoicePeriod']/*[local-name()='EndDate']/text()"s) do
      "" -> nil
      date -> date
    end
  end

  defp extract_currency_code(doc) do
    doc |> xpath(~x"//*[local-name()='DocumentCurrencyCode']/text()"s)
  end

  defp extract_business_process(doc) do
    profile_id = doc |> xpath(~x"//*[local-name()='ProfileID']/text()"s)
    map_business_process_from_code(profile_id)
  end

  defp extract_invoice_type_code(doc) do
    type_code = doc |> xpath(~x"//*[local-name()='InvoiceTypeCode']/text()"s)
    map_invoice_type_from_code(type_code)
  end

  defp extract_supplier(doc) do
    supplier_xpath = "//cac:AccountingSupplierParty/cac:Party"

    ns = [
      cbc: "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2",
      cac: "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
    ]

    %{
      oib: doc |> xpath(~x"#{supplier_xpath}/cbc:EndpointID/text()"s, namespaces: ns),
      registration_name:
        doc
        |> xpath(~x"#{supplier_xpath}/cac:PartyLegalEntity/cbc:RegistrationName/text()"s,
          namespaces: ns
        ),
      postal_address: extract_postal_address(doc, supplier_xpath),
      party_tax_scheme: extract_party_tax_scheme(doc, supplier_xpath),
      contact: extract_contact(doc, supplier_xpath),
      seller_contact: extract_seller_contact(doc)
    }
    |> filter_nil_values()
  end

  defp extract_customer(doc) do
    customer_xpath = "//cac:AccountingCustomerParty/cac:Party"

    ns = [
      cbc: "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2",
      cac: "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
    ]

    %{
      oib: doc |> xpath(~x"#{customer_xpath}/cbc:EndpointID/text()"s, namespaces: ns),
      registration_name:
        doc
        |> xpath(~x"#{customer_xpath}/cac:PartyLegalEntity/cbc:RegistrationName/text()"s,
          namespaces: ns
        ),
      postal_address: extract_postal_address(doc, customer_xpath),
      party_tax_scheme: extract_party_tax_scheme(doc, customer_xpath),
      contact: extract_contact(doc, customer_xpath)
    }
    |> filter_nil_values()
  end

  defp extract_postal_address(doc, party_xpath) do
    address_xpath = "#{party_xpath}/cac:PostalAddress"

    ns = [
      cbc: "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2",
      cac: "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
    ]

    %{
      street_name: doc |> xpath(~x"#{address_xpath}/cbc:StreetName/text()"s, namespaces: ns),
      city_name: doc |> xpath(~x"#{address_xpath}/cbc:CityName/text()"s, namespaces: ns),
      postal_zone: doc |> xpath(~x"#{address_xpath}/cbc:PostalZone/text()"s, namespaces: ns),
      country_code:
        doc
        |> xpath(~x"#{address_xpath}/cac:Country/cbc:IdentificationCode/text()"s,
          namespaces: ns
        )
    }
  end

  defp extract_party_tax_scheme(doc, party_xpath) do
    tax_scheme_xpath = "#{party_xpath}/cac:PartyTaxScheme"

    ns = [
      cbc: "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2",
      cac: "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
    ]

    company_id =
      doc |> xpath(~x"#{tax_scheme_xpath}/cbc:CompanyID/text()"s, namespaces: ns)

    scheme_id =
      doc |> xpath(~x"#{tax_scheme_xpath}/cac:TaxScheme/cbc:ID/text()"s, namespaces: ns)

    %{
      company_id: company_id,
      tax_scheme_id: map_tax_scheme_from_code(scheme_id)
    }
  end

  defp extract_contact(doc, party_xpath) do
    contact_xpath = "#{party_xpath}/cac:Contact"

    ns = [
      cbc: "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2",
      cac: "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
    ]

    name = doc |> xpath(~x"#{contact_xpath}/cbc:Name/text()"s, namespaces: ns)
    email = doc |> xpath(~x"#{contact_xpath}/cbc:ElectronicMail/text()"s, namespaces: ns)

    case {name, email} do
      {"", ""} ->
        nil

      _ ->
        %{
          name: if(name == "", do: nil, else: name),
          electronic_mail: if(email == "", do: nil, else: email)
        }
        |> filter_nil_values()
    end
  end

  defp extract_seller_contact(doc) do
    seller_xpath = "//cac:AccountingSupplierParty/cac:SellerContact"

    ns = [
      cbc: "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2",
      cac: "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
    ]

    id = doc |> xpath(~x"#{seller_xpath}/cbc:ID/text()"s, namespaces: ns)
    name = doc |> xpath(~x"#{seller_xpath}/cbc:Name/text()"s, namespaces: ns)

    case {id, name} do
      {"", ""} ->
        nil

      _ ->
        %{
          id: if(id == "", do: nil, else: id),
          name: if(name == "", do: nil, else: name)
        }
        |> filter_nil_values()
    end
  end

  defp extract_payment_method(doc) do
    payment_xpath = "//cac:PaymentMeans"

    ns = [
      cbc: "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2",
      cac: "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
    ]

    code = doc |> xpath(~x"#{payment_xpath}/cbc:PaymentMeansCode/text()"s, namespaces: ns)

    case code do
      "" ->
        nil

      _ ->
        %{
          payment_means_code: code,
          instruction_note:
            extract_optional_text(doc, "#{payment_xpath}/cbc:InstructionNote/text()"),
          payment_id: extract_optional_text(doc, "#{payment_xpath}/cbc:PaymentID/text()"),
          payee_financial_account_id:
            doc
            |> xpath(~x"#{payment_xpath}/cac:PayeeFinancialAccount/cbc:ID/text()"s,
              namespaces: ns
            )
        }
        |> filter_nil_values()
    end
  end

  defp extract_tax_total(doc) do
    tax_total_xpath = "//cac:TaxTotal"

    ns = [
      cbc: "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2",
      cac: "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
    ]

    %{
      tax_amount: doc |> xpath(~x"#{tax_total_xpath}/cbc:TaxAmount/text()"s, namespaces: ns),
      tax_subtotals: extract_tax_subtotals(doc)
    }
  end

  defp extract_tax_subtotals(doc) do
    ns = [
      cbc: "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2",
      cac: "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
    ]

    doc
    |> xpath(~x"//cac:TaxTotal/cac:TaxSubtotal"l, namespaces: ns)
    |> Enum.map(fn subtotal ->
      %{
        taxable_amount: subtotal |> xpath(~x"./cbc:TaxableAmount/text()"s, namespaces: ns),
        tax_amount: subtotal |> xpath(~x"./cbc:TaxAmount/text()"s, namespaces: ns),
        tax_category: extract_tax_category(subtotal, "./cac:TaxCategory")
      }
    end)
  end

  defp extract_tax_category(doc, category_xpath) do
    ns = [
      cbc: "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2",
      cac: "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
    ]

    id = doc |> xpath(~x"#{category_xpath}/cbc:ID/text()"s, namespaces: ns)
    percent = doc |> xpath(~x"#{category_xpath}/cbc:Percent/text()"s, namespaces: ns)
    scheme_id = doc |> xpath(~x"#{category_xpath}/cac:TaxScheme/cbc:ID/text()"s, namespaces: ns)

    exemption_reason =
      case doc |> xpath(~x"#{category_xpath}/cbc:TaxExemptionReason/text()"s, namespaces: ns) do
        "" -> nil
        reason -> reason
      end

    %{
      id: map_tax_category_from_code(id),
      percent: parse_number(percent),
      tax_scheme_id: map_tax_scheme_from_code(scheme_id),
      tax_exemption_reason: exemption_reason
    }
    |> filter_nil_values()
  end

  defp extract_legal_monetary_total(doc) do
    total_xpath = "//cac:LegalMonetaryTotal"

    ns = [
      cbc: "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2",
      cac: "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
    ]

    %{
      line_extension_amount:
        doc |> xpath(~x"#{total_xpath}/cbc:LineExtensionAmount/text()"s, namespaces: ns),
      tax_exclusive_amount:
        doc |> xpath(~x"#{total_xpath}/cbc:TaxExclusiveAmount/text()"s, namespaces: ns),
      tax_inclusive_amount:
        doc |> xpath(~x"#{total_xpath}/cbc:TaxInclusiveAmount/text()"s, namespaces: ns),
      allowance_total_amount:
        extract_optional_text(doc, "#{total_xpath}/cbc:AllowanceTotalAmount/text()"),
      prepaid_amount: extract_optional_text(doc, "#{total_xpath}/cbc:PrepaidAmount/text()"),
      payable_amount: doc |> xpath(~x"#{total_xpath}/cbc:PayableAmount/text()"s, namespaces: ns)
    }
    |> filter_nil_values()
  end

  defp extract_invoice_lines(doc) do
    ns = [
      cbc: "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2",
      cac: "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
    ]

    doc
    |> xpath(~x"//cac:InvoiceLine"l, namespaces: ns)
    |> Enum.map(fn line ->
      %{
        id: line |> xpath(~x"./cbc:ID/text()"s, namespaces: ns),
        quantity:
          parse_quantity(line |> xpath(~x"./cbc:InvoicedQuantity/text()"s, namespaces: ns)),
        unit_code:
          map_unit_code_from_code(
            line
            |> xpath(~x"./cbc:InvoicedQuantity/@unitCode"s, namespaces: ns)
          ),
        line_extension_amount:
          line |> xpath(~x"./cbc:LineExtensionAmount/text()"s, namespaces: ns),
        item: extract_item(line),
        price: extract_price(line)
      }
    end)
  end

  defp extract_item(line) do
    item_xpath = "./cac:Item"

    ns = [
      cbc: "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2",
      cac: "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
    ]

    name = line |> xpath(~x"#{item_xpath}/cbc:Name/text()"s, namespaces: ns)
    classification = extract_commodity_classification(line, item_xpath)
    tax_category = extract_classified_tax_category(line, item_xpath)

    %{
      name: name,
      commodity_classification: classification,
      classified_tax_category: tax_category
    }
    |> filter_nil_values()
  end

  defp extract_commodity_classification(doc, item_xpath) do
    classification_xpath = "#{item_xpath}/cac:CommodityClassification"

    ns = [
      cbc: "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2",
      cac: "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
    ]

    code =
      doc
      |> xpath(~x"#{classification_xpath}/cbc:ItemClassificationCode/text()"s,
        namespaces: ns
      )

    list_id =
      doc
      |> xpath(~x"#{classification_xpath}/cbc:ItemClassificationCode/@listID"s,
        namespaces: ns
      )

    case {code, list_id} do
      {"", _} -> nil
      {c, ""} -> %{item_classification_code: c}
      {c, lid} -> %{item_classification_code: c, list_id: lid}
    end
  end

  defp extract_classified_tax_category(doc, item_xpath) do
    category_xpath = "#{item_xpath}/cac:ClassifiedTaxCategory"

    ns = [
      cbc: "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2",
      cac: "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
    ]

    id = doc |> xpath(~x"#{category_xpath}/cbc:ID/text()"s, namespaces: ns)
    name = extract_optional_text(doc, "#{category_xpath}/cbc:Name/text()")
    percent = doc |> xpath(~x"#{category_xpath}/cbc:Percent/text()"s, namespaces: ns)
    scheme_id = doc |> xpath(~x"#{category_xpath}/cac:TaxScheme/cbc:ID/text()"s, namespaces: ns)

    %{
      id: map_tax_category_from_code(id),
      name: name,
      percent: parse_number(percent),
      tax_scheme_id: map_tax_scheme_from_code(scheme_id)
    }
    |> filter_nil_values()
  end

  defp extract_price(line) do
    price_xpath = "./cac:Price"

    ns = [
      cbc: "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2",
      cac: "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
    ]

    amount = line |> xpath(~x"#{price_xpath}/cbc:PriceAmount/text()"s, namespaces: ns)
    base_quantity = extract_optional_text(line, "#{price_xpath}/cbc:BaseQuantity/text()")
    unit_code = extract_optional_text(line, "#{price_xpath}/cbc:BaseQuantity/@unitCode")

    %{
      price_amount: amount,
      base_quantity: if(base_quantity, do: parse_quantity(base_quantity), else: nil),
      unit_code: if(unit_code, do: map_unit_code_from_code(unit_code), else: nil)
    }
    |> filter_nil_values()
  end

  defp extract_user_notes(doc) do
    ns = [cbc: "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"]
    all_notes = doc |> xpath(~x"//cbc:Note/text()"ls, namespaces: ns)

    # Filter out mandatory operator notes
    # Filter out mandatory Croatian operator notes (generated from seller_contact)
    user_notes =
      Enum.reject(all_notes, fn note ->
        String.starts_with?(note, "Operater: ") or
          String.starts_with?(note, "OIB operatera: ") or
          String.starts_with?(note, "Vrijeme izdavanja: ")
      end)

    case user_notes do
      [] -> nil
      notes -> notes
    end
  end

  # Enum mapping functions
  defp map_business_process_from_code("P1"), do: "billing"
  defp map_business_process_from_code(code), do: code

  defp map_invoice_type_from_code("380"), do: "commercial_invoice"
  defp map_invoice_type_from_code("381"), do: "credit_note"
  defp map_invoice_type_from_code("384"), do: "corrected_invoice"
  defp map_invoice_type_from_code("389"), do: "self_billed_invoice"
  defp map_invoice_type_from_code("751"), do: "invoice_information"
  defp map_invoice_type_from_code(code), do: code

  defp map_tax_category_from_code("S"), do: "standard_rate"
  defp map_tax_category_from_code("Z"), do: "zero_rate"
  defp map_tax_category_from_code("E"), do: "exempt"
  defp map_tax_category_from_code("AE"), do: "reverse_charge"
  defp map_tax_category_from_code("K"), do: "intra_community"
  defp map_tax_category_from_code("G"), do: "export"
  defp map_tax_category_from_code("O"), do: "outside_scope"
  defp map_tax_category_from_code(code), do: code

  defp map_tax_scheme_from_code("VAT"), do: "vat"
  defp map_tax_scheme_from_code(code), do: code

  defp map_unit_code_from_code("H87"), do: "piece"
  defp map_unit_code_from_code(code), do: code

  # Helper functions
  defp extract_optional_text(doc, xpath_string) when is_binary(xpath_string) do
    ns = [
      cbc: "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2",
      cac: "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
    ]

    case doc |> xpath(~x"#{xpath_string}"s, namespaces: ns) do
      "" -> nil
      text -> text
    end
  end

  defp parse_number(""), do: nil

  defp parse_number(str) when is_binary(str) do
    case Float.parse(str) do
      {num, ""} -> num
      {num, _} -> num
      :error -> str
    end
  end

  defp parse_quantity(""), do: nil

  defp parse_quantity(str) when is_binary(str) do
    case Float.parse(str) do
      {num, ""} -> num
      {num, _} -> num
      :error -> str
    end
  end

  # Extracts VAT cash accounting ("Obračun PDV po naplati") from Croatian HRFISK20Data extension
  defp extract_vat_cash_accounting(doc) do
    # Try to extract HRObracunPDVPoNaplati from UBL extensions using local-name() for namespace independence
    value =
      doc
      |> xpath(
        ~x"//*[local-name()='HRFISK20Data']/*[local-name()='HRObracunPDVPoNaplati']/text()"s
      )

    case value do
      "" -> nil
      text -> text
    end
  end

  defp filter_nil_values(map) when is_map(map) do
    map
    |> Enum.reject(fn {_k, v} -> is_nil(v) or v == "" end)
    |> Map.new()
  end
end
