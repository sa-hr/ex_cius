defmodule ExCius.InvoiceTemplateXML do
  import XmlBuilder

  alias ExCius.Enums.{
    BusinessProcess,
    InvoiceTypeCode,
    TaxCategory,
    TaxScheme,
    UnitCode
  }

  @moduledoc """
  Generates UBL 2.1 Invoice XML documents from validated request parameters.

  This module takes validated parameters from `ExCius.RequestParams` and transforms
  them into a complete UBL 2.1 Invoice XML document that complies with the Croatian
  e-Invoice (CIUS-2025) specification.

  ## Features

  - Generates valid UBL 2.1 Invoice XML
  - Complies with Croatian CIUS-2025 specification
  - Supports all required and optional invoice elements
  - Proper namespace declarations and XML structure
  - Automatic formatting for monetary amounts and quantities
  - Mandatory operator notes per Croatian specification with operator name, OIB, and proper date formatting
  - Embedded document attachments (PDF visualization, images, etc.) via AdditionalDocumentReference

  ## Usage

      # Create invoice parameters
      params = %{
        id: "INV-001",
        issue_datetime: "2025-05-01T12:00:00",
        currency_code: "EUR",
        supplier: %{
          oib: "12345678901",
          registration_name: "Company d.o.o.",
          postal_address: %{...},
          party_tax_scheme: %{...},
          seller_contact: %{
            id: "12345678901",    # Operator's OIB (HR-BT-5)
            name: "Operator1"     # Operator's name (HR-BT-4)
          }
        },
        customer: %{...},
        tax_total: %{...},
        legal_monetary_total: %{...},
        invoice_lines: [...],
        attachments: [                     # Optional embedded documents
          %{
            id: "1",
            filename: "invoice.pdf",
            mime_code: "application/pdf",
            content: "BASE64_ENCODED_CONTENT"
          }
        ]
      }

      # Validate parameters
      {:ok, validated_params} = ExCius.RequestParams.new(params)

      # Generate XML
      xml = ExCius.InvoiceTemplateXML.build_xml(validated_params)

  The generated XML includes:
  - UBL Extensions for signatures
  - Croatian customization and profile IDs
  - Complete supplier and customer party information
  - Tax calculations and categories
  - Payment terms and methods (optional)
  - Multiple invoice lines support
  - Proper XML namespaces and schema locations
  - Mandatory operator and issue time notes
  - Embedded document attachments (AdditionalDocumentReference with EmbeddedDocumentBinaryObject)

  ## XML Structure

  The generated XML follows this structure:
  - XML declaration
  - Invoice root element with all namespaces
  - UBL Extensions
  - Invoice identification and dates
  - Notes (operator and user notes)
  - Document currency code
  - Additional document references (embedded attachments)
  - Supplier party (AccountingSupplierParty)
  - Customer party (AccountingCustomerParty)
  - Payment means (optional)
  - Tax totals and subtotals
  - Legal monetary totals
  - Invoice lines with items and pricing

  ## Embedded Attachments

  Attachments (like PDF visualizations of the invoice) can be embedded directly in the XML
  using the `AdditionalDocumentReference` element with an `EmbeddedDocumentBinaryObject`.
  The content must be base64-encoded. Supported MIME types include:
  - `application/pdf`
  - `image/png`, `image/jpeg`, `image/gif`
  - `text/csv`, `application/xml`, `text/xml`
  - `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`
  - `application/vnd.oasis.opendocument.spreadsheet`
  """

  @doc """
  Generates UBL Invoice XML from validated request parameters.

  Takes the output from ExCius.RequestParams.new/1 and generates
  a complete UBL 2.1 Invoice XML document as a string.

  ## Parameters

  - `params` - Validated parameters map from ExCius.RequestParams.new/1

  ## Returns

  Returns the complete XML document as a string, including XML declaration.

  ## Examples

      iex> invoice_data = %{
      ...>   id: "5-P1-1",
      ...>   issue_datetime: "2025-05-01T12:00:00",
      ...>   currency_code: "EUR",
      ...>   supplier: %{
      ...>     oib: "12345678901",
      ...>     registration_name: "Test Supplier",
      ...>     postal_address: %{...},
      ...>     party_tax_scheme: %{...},
      ...>     seller_contact: %{id: "12345678901", name: "Operator1"}
      ...>   },
      ...>   customer: %{...},
      ...>   tax_total: %{...},
      ...>   legal_monetary_total: %{...},
      ...>   invoice_lines: [...]
      ...> }
      iex> {:ok, params} = ExCius.RequestParams.new(invoice_data)
      iex> xml = ExCius.InvoiceTemplateXML.build_xml(params)
      iex> String.starts_with?(xml, "<?xml version=")
      true
      iex> String.contains?(xml, "<Invoice xmlns=")
      true

  The generated XML will be a complete UBL 2.1 Invoice document with all
  required elements properly formatted and namespace-qualified.
  """
  def build_xml(params) do
    invoice_element = build_invoice(params)

    xml_content = XmlBuilder.generate(invoice_element)
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" <> xml_content
  end

  defp build_invoice(params) do
    element(
      :Invoice,
      [
        xmlns: "urn:oasis:names:specification:ubl:schema:xsd:Invoice-2",
        "xmlns:cac": "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2",
        "xmlns:cbc": "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2",
        "xmlns:cct": "urn:un:unece:uncefact:data:specification:CoreComponentTypeSchemaModule:2",
        "xmlns:ext": "urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2",
        "xmlns:hrextac": "urn:mfin.gov.hr:schema:xsd:HRExtensionAggregateComponents-1",
        "xmlns:p3": "urn:oasis:names:specification:ubl:schema:xsd:UnqualifiedDataTypes-2",
        "xmlns:sac":
          "urn:oasis:names:specification:ubl:schema:xsd:SignatureAggregateComponents-2",
        "xmlns:sig": "urn:oasis:names:specification:ubl:schema:xsd:CommonSignatureComponents-2",
        "xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance",
        "xsi:schemaLocation":
          "urn:oasis:names:specification:ubl:schema:xsd:Invoice-2 ../xsd/ubl/maindoc/UBL-Invoice-2.1.xsd "
      ],
      [
        build_ubl_extensions(params),
        build_customization_id(),
        build_profile_id(params),
        build_id(params),
        build_issue_date(params),
        build_issue_time(params),
        build_due_date(params),
        build_invoice_type_code(params),
        build_notes(params),
        build_document_currency_code(params),
        build_additional_document_references(params),
        build_accounting_supplier_party(params),
        build_accounting_customer_party(params),
        build_delivery(params),
        build_payment_means(params),
        build_tax_total(params),
        build_legal_monetary_total(params),
        build_invoice_lines(params)
      ]
      |> Enum.reject(&is_nil/1)
    )
  end

  defp build_ubl_extensions(params) do
    extensions =
      [
        build_vat_cash_accounting_extension(params),
        element("ext:UBLExtension", [
          element("ext:ExtensionContent", [
            element("sig:UBLDocumentSignatures", [
              element("sac:SignatureInformation", [])
            ])
          ])
        ])
      ]
      |> Enum.reject(&is_nil/1)

    element("ext:UBLExtensions", extensions)
  end

  # Builds the HRFISK20Data extension for VAT cash accounting ("Obračun PDV po naplati")
  # This is a Croatian-specific extension required when the supplier uses cash accounting for VAT.
  defp build_vat_cash_accounting_extension(%{vat_cash_accounting: value})
       when value in [true, "true", "Obračun po naplaćenoj naknadi"] do
    element("ext:UBLExtension", [
      element("ext:ExtensionContent", [
        element("hrextac:HRFISK20Data", [
          element("hrextac:HRObracunPDVPoNaplati", "Obračun po naplaćenoj naknadi")
        ])
      ])
    ])
  end

  defp build_vat_cash_accounting_extension(%{vat_cash_accounting: value})
       when is_binary(value) and byte_size(value) > 0 do
    element("ext:UBLExtension", [
      element("ext:ExtensionContent", [
        element("hrextac:HRFISK20Data", [
          element("hrextac:HRObracunPDVPoNaplati", value)
        ])
      ])
    ])
  end

  defp build_vat_cash_accounting_extension(_), do: nil

  # Builds AdditionalDocumentReference elements for embedded attachments.
  # Each attachment is embedded as a base64-encoded binary object within the invoice XML.
  # This is commonly used to embed PDF visualizations of the invoice.
  defp build_additional_document_references(%{attachments: nil}), do: nil
  defp build_additional_document_references(%{attachments: []}), do: nil

  defp build_additional_document_references(%{attachments: attachments})
       when is_list(attachments) do
    Enum.map(attachments, &build_additional_document_reference/1)
  end

  defp build_additional_document_references(_), do: nil

  defp build_additional_document_reference(attachment) do
    element("cac:AdditionalDocumentReference", [
      element("cbc:ID", attachment.id),
      element("cac:Attachment", [
        element(
          "cbc:EmbeddedDocumentBinaryObject",
          %{filename: attachment.filename, mimeCode: attachment.mime_code},
          attachment.content
        )
      ])
    ])
  end

  defp build_customization_id do
    element(
      "cbc:CustomizationID",
      "urn:cen.eu:en16931:2017#compliant#urn:mfin.gov.hr:cius-2025:1.0#conformant#urn:mfin.gov.hr:ext-2025:1.0"
    )
  end

  defp build_profile_id(params) do
    business_process = Map.get(params, :business_process, BusinessProcess.default())
    profile_code = BusinessProcess.code(business_process)
    element("cbc:ProfileID", profile_code)
  end

  defp build_id(params) do
    element("cbc:ID", params.id)
  end

  defp build_issue_date(params) do
    date_string = Date.to_iso8601(params.issue_date)
    element("cbc:IssueDate", date_string)
  end

  defp build_issue_time(params) do
    time_string = Time.to_iso8601(params.issue_time)
    element("cbc:IssueTime", time_string)
  end

  defp build_due_date(params) do
    case Map.get(params, :due_date) do
      %Date{} = date ->
        element("cbc:DueDate", Date.to_iso8601(date))

      date_string when is_binary(date_string) ->
        case Date.from_iso8601(date_string) do
          {:ok, date} -> element("cbc:DueDate", Date.to_iso8601(date))
          {:error, _} -> element("cbc:DueDate", date_string)
        end

      nil ->
        nil
    end
  end

  defp build_invoice_type_code(params) do
    invoice_type = Map.get(params, :invoice_type_code, InvoiceTypeCode.default())
    type_code = InvoiceTypeCode.code(invoice_type)
    element("cbc:InvoiceTypeCode", type_code)
  end

  defp build_document_currency_code(params) do
    element("cbc:DocumentCurrencyCode", params.currency_code)
  end

  defp build_notes(params) do
    # Generate mandatory operator note per Croatian specification
    operator_note = build_operator_note(params)

    # Get user-provided notes
    user_notes =
      case Map.get(params, :notes) do
        notes when is_list(notes) and length(notes) > 0 ->
          Enum.map(notes, fn note ->
            element("cbc:Note", note)
          end)

        _ ->
          []
      end

    # Combine operator notes with user notes
    operator_note ++ user_notes
  end

  defp build_operator_note(params) do
    issue_datetime = DateTime.new!(params.issue_date, params.issue_time)
    formatted_datetime = format_croatian_datetime(issue_datetime)
    seller_contact = params.supplier.seller_contact

    [
      element("cbc:Note", "Operater: #{seller_contact.name}"),
      element("cbc:Note", "OIB operatera: #{seller_contact.id}"),
      element("cbc:Note", "Vrijeme izdavanja: #{formatted_datetime}")
    ]
  end

  defp format_croatian_datetime(datetime) do
    # Format datetime in Croatian format: "01. 05. 2025. u 12:00"
    Calendar.strftime(datetime, "%d. %m. %Y. u %H:%M")
  end

  defp build_accounting_supplier_party(params) do
    supplier = params.supplier

    element(
      "cac:AccountingSupplierParty",
      [
        element(
          "cac:Party",
          [
            build_endpoint_id(supplier.oib),
            build_party_identification(supplier.oib),
            build_postal_address(supplier.postal_address),
            build_party_tax_scheme(supplier.party_tax_scheme),
            build_party_legal_entity(supplier.registration_name),
            build_contact(Map.get(supplier, :contact))
          ]
          |> Enum.reject(&is_nil/1)
        ),
        build_seller_contact(Map.get(supplier, :seller_contact))
      ]
      |> Enum.reject(&is_nil/1)
    )
  end

  defp build_accounting_customer_party(params) do
    customer = params.customer

    element("cac:AccountingCustomerParty", [
      element(
        "cac:Party",
        [
          build_endpoint_id(customer.oib),
          build_party_identification(customer.oib),
          build_postal_address(customer.postal_address),
          build_party_tax_scheme(customer.party_tax_scheme),
          build_party_legal_entity(customer.registration_name),
          build_contact(Map.get(customer, :contact))
        ]
        |> Enum.reject(&is_nil/1)
      )
    ])
  end

  defp build_endpoint_id(oib) do
    element("cbc:EndpointID", [schemeID: "9934"], oib)
  end

  defp build_party_identification(oib) do
    element("cac:PartyIdentification", [
      element("cbc:ID", "9934:#{oib}")
    ])
  end

  defp build_postal_address(address) do
    element("cac:PostalAddress", [
      element("cbc:StreetName", address.street_name),
      element("cbc:CityName", address.city_name),
      element("cbc:PostalZone", address.postal_zone),
      element("cac:Country", [
        element("cbc:IdentificationCode", address.country_code)
      ])
    ])
  end

  defp build_party_tax_scheme(tax_scheme) do
    scheme_id = TaxScheme.code(tax_scheme.tax_scheme_id)

    element("cac:PartyTaxScheme", [
      element("cbc:CompanyID", tax_scheme.company_id),
      element("cac:TaxScheme", [
        element("cbc:ID", scheme_id)
      ])
    ])
  end

  defp build_party_legal_entity(registration_name) do
    element("cac:PartyLegalEntity", [
      element("cbc:RegistrationName", registration_name)
    ])
  end

  defp build_contact(nil), do: nil

  defp build_contact(contact) do
    element(
      "cac:Contact",
      [
        build_contact_field("cbc:Name", Map.get(contact, :name)),
        build_contact_field("cbc:ElectronicMail", Map.get(contact, :electronic_mail))
      ]
      |> Enum.reject(&is_nil/1)
    )
  end

  defp build_contact_field(_element, nil), do: nil

  defp build_contact_field(element_name, value) do
    element(element_name, value)
  end

  defp build_seller_contact(nil), do: nil

  defp build_seller_contact(seller_contact) do
    element(
      "cac:SellerContact",
      [
        build_contact_field("cbc:ID", Map.get(seller_contact, :id)),
        build_contact_field("cbc:Name", Map.get(seller_contact, :name))
      ]
      |> Enum.reject(&is_nil/1)
    )
  end

  # Builds the Delivery element with ActualDeliveryDate
  defp build_delivery(%{delivery_date: nil}), do: nil

  defp build_delivery(%{delivery_date: %Date{} = date}) do
    element("cac:Delivery", [
      element("cbc:ActualDeliveryDate", Date.to_iso8601(date))
    ])
  end

  defp build_delivery(%{delivery_date: date}) when is_binary(date) do
    element("cac:Delivery", [
      element("cbc:ActualDeliveryDate", date)
    ])
  end

  defp build_delivery(_), do: nil

  defp build_payment_means(params) do
    case Map.get(params, :payment_method) do
      nil ->
        nil

      payment_method ->
        element(
          "cac:PaymentMeans",
          [
            element("cbc:PaymentMeansCode", payment_method.payment_means_code),
            build_payment_field(
              "cbc:InstructionNote",
              Map.get(payment_method, :instruction_note)
            ),
            build_payment_field("cbc:PaymentID", Map.get(payment_method, :payment_id)),
            element("cac:PayeeFinancialAccount", [
              element("cbc:ID", payment_method.payee_financial_account_id)
            ])
          ]
          |> Enum.reject(&is_nil/1)
        )
    end
  end

  defp build_payment_field(_element, nil), do: nil

  defp build_payment_field(element_name, value) do
    element(element_name, value)
  end

  defp build_tax_total(params) do
    tax_total = params.tax_total
    currency_id = params.currency_code

    element(
      "cac:TaxTotal",
      [
        element("cbc:TaxAmount", [currencyID: currency_id], tax_total.tax_amount),
        build_tax_subtotals(tax_total.tax_subtotals, currency_id)
      ]
      |> List.flatten()
    )
  end

  defp build_tax_subtotals(subtotals, currency_id) do
    Enum.map(subtotals, fn subtotal ->
      element("cac:TaxSubtotal", [
        element("cbc:TaxableAmount", [currencyID: currency_id], subtotal.taxable_amount),
        element("cbc:TaxAmount", [currencyID: currency_id], subtotal.tax_amount),
        build_tax_category(subtotal.tax_category)
      ])
    end)
  end

  defp build_tax_category(tax_category) do
    category_id = TaxCategory.code(tax_category.id)
    scheme_id = TaxScheme.code(tax_category.tax_scheme_id)

    element(
      "cac:TaxCategory",
      [
        element("cbc:ID", category_id),
        element("cbc:Percent", tax_category.percent),
        build_tax_exemption_reason(Map.get(tax_category, :tax_exemption_reason)),
        element("cac:TaxScheme", [
          element("cbc:ID", scheme_id)
        ])
      ]
      |> Enum.reject(&is_nil/1)
    )
  end

  defp build_tax_exemption_reason(nil), do: nil
  defp build_tax_exemption_reason(""), do: nil

  defp build_tax_exemption_reason(reason) when is_binary(reason) do
    element("cbc:TaxExemptionReason", reason)
  end

  defp build_legal_monetary_total(params) do
    total = params.legal_monetary_total
    currency_id = params.currency_code

    element("cac:LegalMonetaryTotal", [
      element("cbc:LineExtensionAmount", [currencyID: currency_id], total.line_extension_amount),
      element("cbc:TaxExclusiveAmount", [currencyID: currency_id], total.tax_exclusive_amount),
      element("cbc:TaxInclusiveAmount", [currencyID: currency_id], total.tax_inclusive_amount),
      element("cbc:PayableAmount", [currencyID: currency_id], total.payable_amount)
    ])
  end

  defp build_invoice_lines(params) do
    currency_id = params.currency_code

    Enum.map(params.invoice_lines, fn line ->
      element("cac:InvoiceLine", [
        element("cbc:ID", line.id),
        build_invoiced_quantity(line),
        element("cbc:LineExtensionAmount", [currencyID: currency_id], line.line_extension_amount),
        build_item(line.item, currency_id),
        build_price(line.price, currency_id)
      ])
    end)
  end

  defp build_invoiced_quantity(line) do
    unit_code = UnitCode.code(line.unit_code)
    quantity = format_quantity(line.quantity)
    element("cbc:InvoicedQuantity", [unitCode: unit_code], quantity)
  end

  defp build_item(item, _currency_id) do
    element(
      "cac:Item",
      [
        element("cbc:Name", item.name),
        build_commodity_classification(Map.get(item, :commodity_classification)),
        build_classified_tax_category(item.classified_tax_category)
      ]
      |> Enum.reject(&is_nil/1)
    )
  end

  defp build_commodity_classification(nil), do: nil

  defp build_commodity_classification(classification) do
    element("cac:CommodityClassification", [
      element(
        "cbc:ItemClassificationCode",
        [listID: "CG"],
        classification.item_classification_code
      )
    ])
  end

  defp build_classified_tax_category(tax_category) do
    category_id = TaxCategory.code(tax_category.id)
    scheme_id = TaxScheme.code(tax_category.tax_scheme_id)
    # Use explicitly provided name, or auto-generate Croatian tax name from percent
    tax_name = Map.get(tax_category, :name) || croatian_tax_name(tax_category.percent)

    element(
      "cac:ClassifiedTaxCategory",
      [
        element("cbc:ID", category_id),
        build_tax_category_name(tax_name),
        element("cbc:Percent", tax_category.percent),
        element("cac:TaxScheme", [
          element("cbc:ID", scheme_id)
        ])
      ]
      |> Enum.reject(&is_nil/1)
    )
  end

  defp build_tax_category_name(nil), do: nil

  defp build_tax_category_name(name) do
    element("cbc:Name", name)
  end

  # Auto-generates Croatian tax category name based on VAT percentage
  # HR:Z for 0%, HR:PDV5 for 5%, HR:PDV13 for 13%, HR:PDV25 for 25%
  defp croatian_tax_name(percent) when percent == 0, do: "HR:Z"
  defp croatian_tax_name(percent) when percent == 5, do: "HR:PDV5"
  defp croatian_tax_name(percent) when percent == 13, do: "HR:PDV13"
  defp croatian_tax_name(percent) when percent == 25, do: "HR:PDV25"
  defp croatian_tax_name(_), do: nil

  defp build_price(price, currency_id) do
    element(
      "cac:Price",
      [
        element(
          "cbc:PriceAmount",
          [currencyID: currency_id],
          format_price_amount(price.price_amount)
        ),
        build_base_quantity(Map.get(price, :base_quantity), Map.get(price, :unit_code))
      ]
      |> Enum.reject(&is_nil/1)
    )
  end

  defp build_base_quantity(nil, _), do: nil

  defp build_base_quantity(quantity, unit_code) do
    unit_code_value = if unit_code, do: UnitCode.code(unit_code), else: "H87"
    quantity_formatted = format_quantity(quantity)
    element("cbc:BaseQuantity", [unitCode: unit_code_value], quantity_formatted)
  end

  defp format_quantity(quantity) when is_float(quantity) do
    :erlang.float_to_binary(quantity, [{:decimals, 3}])
  end

  defp format_quantity(quantity) when is_integer(quantity) do
    "#{quantity}.000"
  end

  defp format_quantity(quantity) when is_binary(quantity) do
    case Float.parse(quantity) do
      {float_val, ""} -> format_quantity(float_val)
      _ -> quantity
    end
  end

  defp format_price_amount(amount) when is_binary(amount) do
    case Float.parse(amount) do
      {float_val, ""} -> :erlang.float_to_binary(float_val, [{:decimals, 6}])
      _ -> amount
    end
  end

  defp format_price_amount(amount) when is_float(amount) do
    :erlang.float_to_binary(amount, [{:decimals, 6}])
  end

  defp format_price_amount(amount) when is_integer(amount) do
    "#{amount}.000000"
  end
end
