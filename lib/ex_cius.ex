defmodule ExCius do
  @moduledoc """
  ExCius - A library for creating and parsing UBL 2.1 invoices compliant with Croatian e-Invoice (CIUS-2025) specification.
  """

  alias ExCius.{RequestParams, InvoiceTemplateXML}

  def generate_invoice(invoice_data) when is_map(invoice_data) do
    case RequestParams.new(invoice_data) do
      {:ok, validated_params} ->
        xml = InvoiceTemplateXML.build_xml(validated_params)
        {:ok, xml}

      {:error, errors} ->
        {:error, errors}
    end
  end

  def generate_invoice(_), do: {:error, %{input: "must be a map"}}

  def parse_invoice(xml) when is_binary(xml) do
    ExCius.InvoiceXmlParserFixed.parse(xml)
  end

  def parse_invoice(_), do: {:error, "Input must be an XML string"}

  def validate_invoice(invoice_data) when is_map(invoice_data) do
    RequestParams.new(invoice_data)
  end

  def validate_invoice(_), do: {:error, %{input: "must be a map"}}

  def round_trip_test(invoice_data) when is_map(invoice_data) do
    with {:ok, xml} <- generate_invoice(invoice_data),
         {:ok, parsed_data} <- parse_invoice(xml) do
      {:ok, {xml, parsed_data}}
    else
      error -> error
    end
  end

  def round_trip_test(_), do: {:error, "Input must be a map"}

  def version do
    case Application.spec(:ex_cius, :vsn) do
      nil -> "unknown"
      vsn -> List.to_string(vsn)
    end
  end

  def info do
    %{
      library_version: version(),
      ubl_version: "2.1",
      croatian_cius: "2025",
      supported_currencies: ["EUR"],
      mandatory_features: [
        "operator_notes",
        "croatian_date_format",
        "ubl_extensions",
        "party_tax_schemes"
      ],
      optional_features: [
        "payment_means",
        "due_dates",
        "contact_information",
        "commodity_classification",
        "user_notes"
      ]
    }
  end
end
