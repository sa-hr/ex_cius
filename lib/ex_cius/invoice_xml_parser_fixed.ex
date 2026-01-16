defmodule ExCius.InvoiceXmlParserFixed do
  @moduledoc """
  Fixed version of the InvoiceXmlParser that uses local-name() xpath approach
  to avoid namespace issues with SweetXML.

  This parser extracts invoice data from UBL 2.1 Invoice XML documents
  without relying on namespace prefixes, making it more robust.
  """

  import SweetXml

  @doc """
  Parses UBL 2.1 Invoice XML content and extracts invoice data.

  Uses local-name() xpath functions to avoid namespace issues.

  ## Parameters

  - `xml_content` - UBL Invoice XML document as a string

  ## Returns

  - `{:ok, invoice_data}` - Successfully parsed invoice data as a map
  - `{:error, reason}` - Parsing failed with error description

  ## Examples

      iex> xml = "<?xml version=\\"1.0\\"?>..."
      iex> {:ok, data} = ExCius.InvoiceXmlParserFixed.parse(xml)
      iex> data.id
      "INV-001"

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
      billing_reference: extract_billing_reference(doc),
      supplier: extract_supplier(doc),
      customer: extract_customer(doc),
      payment_method: extract_payment_method(doc),
      allowance_charges: extract_allowance_charges(doc),
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
    |> xpath(~x"//*[local-name()='Invoice']/*[local-name()='ID']/text()"s)
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

  # Extracts BillingReference (BG-3 - PRECEDING INVOICE REFERENCE)
  # Used for credit notes (381), corrected invoices (384), and debit notes (383)
  defp extract_billing_reference(doc) do
    billing_ref_path = "//*[local-name()='BillingReference']"
    invoice_doc_ref_path = "#{billing_ref_path}/*[local-name()='InvoiceDocumentReference']"

    id = doc |> xpath(~x"#{invoice_doc_ref_path}/*[local-name()='ID']/text()"s)

    case id do
      "" ->
        nil

      _ ->
        issue_date =
          case doc |> xpath(~x"#{invoice_doc_ref_path}/*[local-name()='IssueDate']/text()"s) do
            "" -> nil
            date -> date
          end

        %{
          invoice_document_reference:
            %{
              id: id,
              issue_date: issue_date
            }
            |> filter_nil_values()
        }
    end
  end

  defp extract_supplier(doc) do
    supplier_path = "//*[local-name()='AccountingSupplierParty']/*[local-name()='Party']"

    %{
      oib: doc |> xpath(~x"#{supplier_path}/*[local-name()='EndpointID']/text()"s),
      registration_name:
        doc
        |> xpath(
          ~x"#{supplier_path}/*[local-name()='PartyLegalEntity']/*[local-name()='RegistrationName']/text()"s
        ),
      postal_address: extract_postal_address(doc, supplier_path),
      party_tax_scheme: extract_party_tax_scheme(doc, supplier_path),
      contact: extract_contact(doc, supplier_path),
      seller_contact: extract_seller_contact(doc)
    }
    |> filter_nil_values()
  end

  defp extract_customer(doc) do
    customer_path = "//*[local-name()='AccountingCustomerParty']/*[local-name()='Party']"

    %{
      oib: doc |> xpath(~x"#{customer_path}/*[local-name()='EndpointID']/text()"s),
      registration_name:
        doc
        |> xpath(
          ~x"#{customer_path}/*[local-name()='PartyLegalEntity']/*[local-name()='RegistrationName']/text()"s
        ),
      postal_address: extract_postal_address(doc, customer_path),
      party_tax_scheme: extract_party_tax_scheme(doc, customer_path),
      contact: extract_contact(doc, customer_path)
    }
    |> filter_nil_values()
  end

  defp extract_postal_address(doc, party_path) do
    address_path = "#{party_path}/*[local-name()='PostalAddress']"

    %{
      street_name: doc |> xpath(~x"#{address_path}/*[local-name()='StreetName']/text()"s),
      city_name: doc |> xpath(~x"#{address_path}/*[local-name()='CityName']/text()"s),
      postal_zone: doc |> xpath(~x"#{address_path}/*[local-name()='PostalZone']/text()"s),
      country_code:
        doc
        |> xpath(
          ~x"#{address_path}/*[local-name()='Country']/*[local-name()='IdentificationCode']/text()"s
        )
    }
    |> filter_nil_values()
  end

  defp extract_party_tax_scheme(doc, party_path) do
    tax_scheme_path = "#{party_path}/*[local-name()='PartyTaxScheme']"

    company_id =
      doc |> xpath(~x"#{tax_scheme_path}/*[local-name()='CompanyID']/text()"s)

    scheme_id =
      doc
      |> xpath(~x"#{tax_scheme_path}/*[local-name()='TaxScheme']/*[local-name()='ID']/text()"s)

    case {company_id, scheme_id} do
      {"", _} ->
        nil

      {_, ""} ->
        nil

      {cid, sid} ->
        %{
          company_id: cid,
          tax_scheme_id: map_tax_scheme_from_code(sid)
        }
    end
  end

  defp extract_contact(doc, party_path) do
    contact_path = "#{party_path}/*[local-name()='Contact']"

    name = doc |> xpath(~x"#{contact_path}/*[local-name()='Name']/text()"s)
    email = doc |> xpath(~x"#{contact_path}/*[local-name()='ElectronicMail']/text()"s)
    telephone = doc |> xpath(~x"#{contact_path}/*[local-name()='Telephone']/text()"s)

    case {name, email, telephone} do
      {"", "", ""} ->
        nil

      _ ->
        %{
          name: (name != "" && name) || nil,
          email: (email != "" && email) || nil,
          telephone: (telephone != "" && telephone) || nil
        }
        |> filter_nil_values()
    end
  end

  defp extract_seller_contact(doc) do
    seller_path = "//*[local-name()='AccountingSupplierParty']/*[local-name()='SellerContact']"

    id = doc |> xpath(~x"#{seller_path}/*[local-name()='ID']/text()"s)
    name = doc |> xpath(~x"#{seller_path}/*[local-name()='Name']/text()"s)
    telephone = doc |> xpath(~x"#{seller_path}/*[local-name()='Telephone']/text()"s)
    email = doc |> xpath(~x"#{seller_path}/*[local-name()='ElectronicMail']/text()"s)

    case {id, name, telephone, email} do
      {"", "", "", ""} ->
        nil

      _ ->
        %{
          id: (id != "" && id) || nil,
          name: (name != "" && name) || nil,
          telephone: (telephone != "" && telephone) || nil,
          email: (email != "" && email) || nil
        }
        |> filter_nil_values()
    end
  end

  defp extract_payment_method(doc) do
    payment_path = "//*[local-name()='PaymentMeans']"

    code = doc |> xpath(~x"#{payment_path}/*[local-name()='PaymentMeansCode']/text()"s)

    case code do
      "" ->
        nil

      _ ->
        instruction_note =
          doc |> xpath(~x"#{payment_path}/*[local-name()='InstructionNote']/text()"s)

        payment_id =
          doc |> xpath(~x"#{payment_path}/*[local-name()='PaymentID']/text()"s)

        payee_account_id =
          doc
          |> xpath(
            ~x"#{payment_path}/*[local-name()='PayeeFinancialAccount']/*[local-name()='ID']/text()"s
          )

        %{
          payment_means_code: code,
          instruction_note: (instruction_note != "" && instruction_note) || nil,
          payment_id: (payment_id != "" && payment_id) || nil,
          payee_financial_account_id: (payee_account_id != "" && payee_account_id) || nil
        }
        |> filter_nil_values()
    end
  end

  # Extracts document-level AllowanceCharge elements (BG-20/BG-21)
  # These are charges/surcharges or discounts/allowances at the invoice level
  defp extract_allowance_charges(doc) do
    # Only get direct children of Invoice to avoid picking up line-level allowances
    allowance_charges =
      doc
      |> xpath(~x"//*[local-name()='Invoice']/*[local-name()='AllowanceCharge']"l)
      |> Enum.map(&extract_single_allowance_charge/1)

    case allowance_charges do
      [] -> nil
      charges -> charges
    end
  end

  defp extract_single_allowance_charge(ac_node) do
    charge_indicator =
      case ac_node |> xpath(~x"./*[local-name()='ChargeIndicator']/text()"s) do
        "true" -> true
        "false" -> false
        _ -> nil
      end

    amount = ac_node |> xpath(~x"./*[local-name()='Amount']/text()"s)
    reason = extract_optional_text(ac_node, "./*[local-name()='AllowanceChargeReason']/text()")

    reason_code =
      extract_optional_text(ac_node, "./*[local-name()='AllowanceChargeReasonCode']/text()")

    multiplier =
      extract_optional_text(ac_node, "./*[local-name()='MultiplierFactorNumeric']/text()")

    base_amount = extract_optional_text(ac_node, "./*[local-name()='BaseAmount']/text()")

    tax_category = extract_allowance_charge_tax_category(ac_node)

    %{
      charge_indicator: charge_indicator,
      amount: amount,
      allowance_charge_reason: reason,
      allowance_charge_reason_code: reason_code,
      multiplier_factor_numeric: multiplier && parse_number(multiplier),
      base_amount: base_amount,
      tax_category: tax_category
    }
    |> filter_nil_values()
  end

  defp extract_allowance_charge_tax_category(ac_node) do
    category_path = "./*[local-name()='TaxCategory']"

    id = ac_node |> xpath(~x"#{category_path}/*[local-name()='ID']/text()"s)

    case id do
      "" ->
        nil

      _ ->
        percent = ac_node |> xpath(~x"#{category_path}/*[local-name()='Percent']/text()"s)

        scheme_id =
          ac_node
          |> xpath(~x"#{category_path}/*[local-name()='TaxScheme']/*[local-name()='ID']/text()"s)

        exemption_reason =
          extract_optional_text(
            ac_node,
            "#{category_path}/*[local-name()='TaxExemptionReason']/text()"
          )

        %{
          id: map_tax_category_from_code(id),
          percent: parse_number(percent),
          tax_scheme_id: map_tax_scheme_from_code(scheme_id),
          tax_exemption_reason: exemption_reason
        }
        |> filter_nil_values()
    end
  end

  defp extract_tax_total(doc) do
    tax_total_path = "//*[local-name()='TaxTotal']"

    %{
      tax_amount: doc |> xpath(~x"#{tax_total_path}/*[local-name()='TaxAmount']/text()"s),
      tax_subtotals: extract_tax_subtotals(doc)
    }
  end

  defp extract_tax_subtotals(doc) do
    doc
    |> xpath(~x"//*[local-name()='TaxTotal']/*[local-name()='TaxSubtotal']"l)
    |> Enum.map(fn subtotal ->
      %{
        taxable_amount: subtotal |> xpath(~x"./*[local-name()='TaxableAmount']/text()"s),
        tax_amount: subtotal |> xpath(~x"./*[local-name()='TaxAmount']/text()"s),
        tax_category: extract_tax_category(subtotal, "./*[local-name()='TaxCategory']")
      }
    end)
  end

  defp extract_tax_category(doc, category_path) do
    id = doc |> xpath(~x"#{category_path}/*[local-name()='ID']/text()"s)
    percent = doc |> xpath(~x"#{category_path}/*[local-name()='Percent']/text()"s)

    scheme_id =
      doc |> xpath(~x"#{category_path}/*[local-name()='TaxScheme']/*[local-name()='ID']/text()"s)

    exemption_reason =
      case doc |> xpath(~x"#{category_path}/*[local-name()='TaxExemptionReason']/text()"s) do
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
    total_path = "//*[local-name()='LegalMonetaryTotal']"

    %{
      line_extension_amount:
        doc |> xpath(~x"#{total_path}/*[local-name()='LineExtensionAmount']/text()"s),
      tax_exclusive_amount:
        doc |> xpath(~x"#{total_path}/*[local-name()='TaxExclusiveAmount']/text()"s),
      tax_inclusive_amount:
        doc |> xpath(~x"#{total_path}/*[local-name()='TaxInclusiveAmount']/text()"s),
      payable_amount: doc |> xpath(~x"#{total_path}/*[local-name()='PayableAmount']/text()"s)
    }
  end

  defp extract_invoice_lines(doc) do
    doc
    |> xpath(~x"//*[local-name()='InvoiceLine']"l)
    |> Enum.map(fn line ->
      %{
        id: line |> xpath(~x"./*[local-name()='ID']/text()"s),
        quantity: parse_quantity(line |> xpath(~x"./*[local-name()='InvoicedQuantity']/text()"s)),
        unit_code:
          map_unit_code_from_code(
            line
            |> xpath(~x"./*[local-name()='InvoicedQuantity']/@unitCode"s)
          ),
        line_extension_amount: line |> xpath(~x"./*[local-name()='LineExtensionAmount']/text()"s),
        item: extract_item(line),
        price: extract_price(line)
      }
    end)
  end

  defp extract_item(line) do
    item_path = "./*[local-name()='Item']"

    name = line |> xpath(~x"#{item_path}/*[local-name()='Name']/text()"s)
    classification = extract_commodity_classification(line, item_path)
    tax_category = extract_classified_tax_category(line, item_path)

    %{
      name: name,
      commodity_classification: classification,
      classified_tax_category: tax_category
    }
    |> filter_nil_values()
  end

  defp extract_commodity_classification(doc, item_path) do
    classification_path = "#{item_path}/*[local-name()='CommodityClassification']"

    code =
      doc
      |> xpath(~x"#{classification_path}/*[local-name()='ItemClassificationCode']/text()"s)

    list_id =
      doc
      |> xpath(~x"#{classification_path}/*[local-name()='ItemClassificationCode']/@listID"s)

    case {code, list_id} do
      {"", _} -> nil
      {c, ""} -> %{item_classification_code: c}
      {c, lid} -> %{item_classification_code: c, list_id: lid}
    end
  end

  defp extract_classified_tax_category(doc, item_path) do
    category_path = "#{item_path}/*[local-name()='ClassifiedTaxCategory']"

    id = doc |> xpath(~x"#{category_path}/*[local-name()='ID']/text()"s)
    name = extract_optional_text(doc, "#{category_path}/*[local-name()='Name']/text()")
    percent = doc |> xpath(~x"#{category_path}/*[local-name()='Percent']/text()"s)

    scheme_id =
      doc |> xpath(~x"#{category_path}/*[local-name()='TaxScheme']/*[local-name()='ID']/text()"s)

    %{
      id: map_tax_category_from_code(id),
      name: name,
      percent: parse_number(percent),
      tax_scheme_id: map_tax_scheme_from_code(scheme_id)
    }
    |> filter_nil_values()
  end

  defp extract_price(line) do
    price_path = "./*[local-name()='Price']"

    amount = line |> xpath(~x"#{price_path}/*[local-name()='PriceAmount']/text()"s)

    base_quantity =
      extract_optional_text(line, "#{price_path}/*[local-name()='BaseQuantity']/text()")

    unit_code =
      extract_optional_text(line, "#{price_path}/*[local-name()='BaseQuantity']/@unitCode")

    %{
      price_amount: amount,
      base_quantity: base_quantity && parse_quantity(base_quantity),
      unit_code: unit_code && map_unit_code_from_code(unit_code)
    }
    |> filter_nil_values()
  end

  defp extract_user_notes(doc) do
    notes = doc |> xpath(~x"//*[local-name()='Note']/text()"ls)

    # Filter out mandatory Croatian operator notes (generated from seller_contact)
    user_notes =
      Enum.reject(notes, fn note ->
        is_binary(note) &&
          (String.starts_with?(note, "Operater: ") or
             String.starts_with?(note, "OIB operatera: ") or
             String.starts_with?(note, "Vrijeme izdavanja: "))
      end)

    case user_notes do
      [] -> nil
      notes -> notes
    end
  end

  # Mapping functions
  # Map ProfileID codes to atom-friendly names
  defp map_business_process_from_code("P1"), do: "p1"
  defp map_business_process_from_code("P2"), do: "p2"
  defp map_business_process_from_code("P3"), do: "p3"
  defp map_business_process_from_code("P4"), do: "p4"
  defp map_business_process_from_code("P5"), do: "p5"
  defp map_business_process_from_code("P6"), do: "p6"
  defp map_business_process_from_code("P7"), do: "p7"
  defp map_business_process_from_code("P8"), do: "p8"
  defp map_business_process_from_code("P9"), do: "p9"
  defp map_business_process_from_code("P10"), do: "p10"
  defp map_business_process_from_code("P11"), do: "p11"
  defp map_business_process_from_code("P12"), do: "p12"
  defp map_business_process_from_code("P99"), do: "p99"
  defp map_business_process_from_code(code), do: code

  defp map_invoice_type_from_code("380"), do: "commercial_invoice"
  defp map_invoice_type_from_code("381"), do: "credit_note"
  defp map_invoice_type_from_code("383"), do: "debit_note"
  defp map_invoice_type_from_code("384"), do: "corrected_invoice"
  defp map_invoice_type_from_code("386"), do: "prepayment_invoice"
  defp map_invoice_type_from_code("389"), do: "self_billing_invoice"
  defp map_invoice_type_from_code("751"), do: "invoice_information_for_accounting_purposes"
  defp map_invoice_type_from_code(code), do: code

  defp map_tax_category_from_code("S"), do: "standard_rate"
  defp map_tax_category_from_code("Z"), do: "zero_rate"
  defp map_tax_category_from_code("E"), do: "exempt"
  defp map_tax_category_from_code("AE"), do: "vat_reverse_charge"
  defp map_tax_category_from_code("K"), do: "vat_exempt_for_eas"
  defp map_tax_category_from_code("G"), do: "free_export_item"
  defp map_tax_category_from_code("O"), do: "services_outside_scope"
  defp map_tax_category_from_code(code), do: code

  defp map_tax_scheme_from_code("VAT"), do: "vat"
  defp map_tax_scheme_from_code(code), do: code

  defp map_unit_code_from_code("H87"), do: "piece"
  defp map_unit_code_from_code(code), do: code

  # Utility functions
  defp extract_optional_text(doc, xpath_string) do
    # Simple approach: use SweetXML with local-name() for optional text
    case doc |> xpath(~x"#{xpath_string}"s) do
      "" -> nil
      result -> result
    end
  rescue
    _ -> nil
  catch
    _, _ -> nil
  end

  defp parse_number(""), do: nil

  defp parse_number(str) when is_binary(str) do
    case Float.parse(str) do
      {num, ""} -> num
      _ -> str
    end
  end

  defp parse_quantity(""), do: nil

  defp parse_quantity(str) when is_binary(str) do
    case Float.parse(str) do
      {num, ""} -> num
      _ -> 0.0
    end
  end

  # Extracts VAT cash accounting ("Obračun PDV po naplati") from Croatian HRFISK20Data extension
  defp extract_vat_cash_accounting(doc) do
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
    map |> Enum.reject(fn {_k, v} -> is_nil(v) end) |> Map.new()
  end
end
