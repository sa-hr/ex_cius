defmodule ExCius.AllowanceChargeXML do
  @moduledoc """
  Builds UBL 2.1 AllowanceCharge XML elements.

  This module generates XML elements for both document-level and line-level
  allowances and charges according to the UBL 2.1 specification and
  Croatian CIUS-2025 requirements.

  ## Document Level AllowanceCharge

  Document-level allowances/charges appear directly under the Invoice element
  and MUST include a TaxCategory element because they affect the overall
  tax calculation.

  ## Line Level AllowanceCharge

  Line-level allowances/charges appear within InvoiceLine elements and
  SHOULD NOT include a TaxCategory element (they inherit tax from the line).

  ## XML Structure

  ```xml
  <cac:AllowanceCharge>
    <cbc:ChargeIndicator>false</cbc:ChargeIndicator>
    <cbc:AllowanceChargeReasonCode>95</cbc:AllowanceChargeReasonCode>
    <cbc:AllowanceChargeReason>Discount</cbc:AllowanceChargeReason>
    <cbc:MultiplierFactorNumeric>10</cbc:MultiplierFactorNumeric>
    <cbc:Amount currencyID="EUR">10.00</cbc:Amount>
    <cbc:BaseAmount currencyID="EUR">100.00</cbc:BaseAmount>
    <!-- Document level only: -->
    <cac:TaxCategory>
      <cbc:ID>S</cbc:ID>
      <cbc:Percent>25</cbc:Percent>
      <cac:TaxScheme>
        <cbc:ID>VAT</cbc:ID>
      </cac:TaxScheme>
    </cac:TaxCategory>
  </cac:AllowanceCharge>
  ```
  """

  import XmlBuilder

  alias ExCius.Enums.{
    AllowanceReasonCode,
    ChargeReasonCode,
    TaxCategory,
    TaxScheme
  }

  @doc """
  Builds XML elements for a list of document-level allowances/charges.

  Returns a list of `cac:AllowanceCharge` XML elements with TaxCategory included.

  ## Parameters

  - `allowances_charges` - List of validated allowance/charge maps
  - `currency_id` - The currency code (e.g., "EUR")

  ## Example

      iex> ExCius.AllowanceChargeXML.build_document_level_list([
      ...>   %{
      ...>     charge_indicator: true,
      ...>     allowance_charge_reason_code: :freight,
      ...>     allowance_charge_reason: "Shipping",
      ...>     amount: "15.00",
      ...>     tax_category: %{id: :standard_rate, percent: 25, tax_scheme_id: :vat}
      ...>   }
      ...> ], "EUR")
  """
  def build_document_level_list(nil, _currency_id), do: []
  def build_document_level_list([], _currency_id), do: []

  def build_document_level_list(allowances_charges, currency_id)
      when is_list(allowances_charges) do
    Enum.map(allowances_charges, &build_document_level(&1, currency_id))
  end

  @doc """
  Builds a single document-level AllowanceCharge XML element.

  Document-level allowances/charges include TaxCategory.
  """
  def build_document_level(allowance_charge, currency_id) do
    element(
      "cac:AllowanceCharge",
      [
        build_charge_indicator(allowance_charge),
        build_reason_code(allowance_charge),
        build_reason(allowance_charge),
        build_multiplier_factor(allowance_charge),
        build_amount(allowance_charge, currency_id),
        build_base_amount(allowance_charge, currency_id),
        build_tax_category(allowance_charge.tax_category)
      ]
      |> Enum.reject(&is_nil/1)
    )
  end

  @doc """
  Builds XML elements for a list of line-level allowances/charges.

  Returns a list of `cac:AllowanceCharge` XML elements WITHOUT TaxCategory.

  ## Parameters

  - `allowances_charges` - List of validated allowance/charge maps
  - `currency_id` - The currency code (e.g., "EUR")
  """
  def build_line_level_list(nil, _currency_id), do: []
  def build_line_level_list([], _currency_id), do: []

  def build_line_level_list(allowances_charges, currency_id) when is_list(allowances_charges) do
    Enum.map(allowances_charges, &build_line_level(&1, currency_id))
  end

  @doc """
  Builds a single line-level AllowanceCharge XML element.

  Line-level allowances/charges do NOT include TaxCategory.
  """
  def build_line_level(allowance_charge, currency_id) do
    element(
      "cac:AllowanceCharge",
      [
        build_charge_indicator(allowance_charge),
        build_reason_code(allowance_charge),
        build_reason(allowance_charge),
        build_multiplier_factor(allowance_charge),
        build_amount(allowance_charge, currency_id),
        build_base_amount(allowance_charge, currency_id)
      ]
      |> Enum.reject(&is_nil/1)
    )
  end

  # Private helper functions

  defp build_charge_indicator(%{charge_indicator: true}) do
    element("cbc:ChargeIndicator", "true")
  end

  defp build_charge_indicator(%{charge_indicator: false}) do
    element("cbc:ChargeIndicator", "false")
  end

  defp build_reason_code(%{charge_indicator: true, allowance_charge_reason_code: code})
       when not is_nil(code) do
    element("cbc:AllowanceChargeReasonCode", ChargeReasonCode.code(code))
  end

  defp build_reason_code(%{charge_indicator: false, allowance_charge_reason_code: code})
       when not is_nil(code) do
    element("cbc:AllowanceChargeReasonCode", AllowanceReasonCode.code(code))
  end

  defp build_reason_code(_), do: nil

  defp build_reason(%{allowance_charge_reason: reason})
       when is_binary(reason) and byte_size(reason) > 0 do
    element("cbc:AllowanceChargeReason", reason)
  end

  defp build_reason(_), do: nil

  defp build_multiplier_factor(%{multiplier_factor_numeric: factor})
       when is_number(factor) do
    element("cbc:MultiplierFactorNumeric", format_decimal(factor))
  end

  defp build_multiplier_factor(_), do: nil

  defp build_amount(%{amount: amount}, currency_id) do
    element("cbc:Amount", [currencyID: currency_id], amount)
  end

  defp build_base_amount(%{base_amount: base_amount}, currency_id)
       when is_binary(base_amount) do
    element("cbc:BaseAmount", [currencyID: currency_id], base_amount)
  end

  defp build_base_amount(_, _), do: nil

  defp build_tax_category(tax_category) when is_map(tax_category) do
    category_id = TaxCategory.code(tax_category.id)
    scheme_id = TaxScheme.code(tax_category.tax_scheme_id)

    element(
      "cac:TaxCategory",
      [
        element("cbc:ID", category_id),
        element("cbc:Percent", tax_category.percent),
        build_tax_exemption_reason(Map.get(tax_category, :tax_exemption_reason)),
        build_tax_exemption_reason_code(Map.get(tax_category, :tax_exemption_reason_code)),
        element("cac:TaxScheme", [
          element("cbc:ID", scheme_id)
        ])
      ]
      |> Enum.reject(&is_nil/1)
    )
  end

  defp build_tax_category(_), do: nil

  defp build_tax_exemption_reason(nil), do: nil
  defp build_tax_exemption_reason(""), do: nil

  defp build_tax_exemption_reason(reason) when is_binary(reason) do
    element("cbc:TaxExemptionReason", reason)
  end

  defp build_tax_exemption_reason(_), do: nil

  defp build_tax_exemption_reason_code(nil), do: nil
  defp build_tax_exemption_reason_code(""), do: nil

  defp build_tax_exemption_reason_code(code) when is_binary(code) do
    element("cbc:TaxExemptionReasonCode", code)
  end

  defp build_tax_exemption_reason_code(code) when is_atom(code) do
    # Try to get the code from the enum
    case ExCius.Enums.TaxExemptionReasonCode.code(code) do
      nil -> nil
      resolved_code -> element("cbc:TaxExemptionReasonCode", resolved_code)
    end
  end

  defp build_tax_exemption_reason_code(_), do: nil

  defp format_decimal(value) when is_float(value) do
    :erlang.float_to_binary(value, decimals: 2)
  end

  defp format_decimal(value) when is_integer(value) do
    Integer.to_string(value)
  end

  defp format_decimal(value), do: to_string(value)
end
