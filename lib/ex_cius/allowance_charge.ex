defmodule ExCius.AllowanceCharge do
  @moduledoc """
  Handles AllowanceCharge structures for UBL 2.1 invoices.

  AllowanceCharge represents discounts (allowances) or surcharges (charges) that can be
  applied at two levels:

  ## Document Level
  Applied to the entire invoice. These MUST include a TaxCategory because they
  affect the overall tax calculation of the invoice.

  ## Line Item Level
  Applied to individual invoice lines. These SHOULD NOT include a TaxCategory
  because they inherit the tax settings from the line item they belong to.

  ## Structure

  ### Required Fields
  - `:charge_indicator` - Boolean. `false` = Allowance/Discount, `true` = Charge/Surcharge
  - `:amount` - Decimal string. The total amount of the allowance or charge

  ### Optional Fields
  - `:allowance_charge_reason_code` - Code identifying the reason (UNTDID 5189 for allowances, 7161 for charges)
  - `:allowance_charge_reason` - Text description of the allowance or charge
  - `:multiplier_factor_numeric` - Decimal. The percentage (e.g., 10 for 10%)
  - `:base_amount` - Decimal string. The base amount the percentage is applied to

  ### Document Level Only
  - `:tax_category` - Required for document level. Contains:
    - `:id` - Tax category code (e.g., :standard_rate, :exempt, :outside_scope)
    - `:percent` - Tax percentage
    - `:tax_scheme_id` - Tax scheme identifier (e.g., :vat)
    - `:tax_exemption_reason` - (optional) Text reason for exemption (Croatian HR extension)
    - `:tax_exemption_reason_code` - (optional) Code for exemption reason (Croatian HR extension)

  ## Croatian Extensions (Fiskalizacija 2.0)

  For non-taxable document-level charges (e.g., "Povratna naknada" - deposit/return fee),
  the TaxCategory should use `:outside_scope` (O) or `:exempt` (E) with the appropriate
  exemption reason fields populated.

  ## Examples

  ### Document Level Charge (Shipping Fee with VAT)

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

  ### Document Level Charge (Non-taxable Deposit Fee - Croatian)

      %{
        charge_indicator: true,
        allowance_charge_reason_code: :deposit_fee,
        allowance_charge_reason: "Povratna naknada",
        amount: "0.50",
        tax_category: %{
          id: :outside_scope,
          percent: 0,
          tax_scheme_id: :vat,
          tax_exemption_reason: "Povratna naknada - Loss Pot"
        }
      }

  ### Document Level Discount (10% off total)

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

  ### Line Item Level Discount

      %{
        charge_indicator: false,
        allowance_charge_reason_code: :discount,
        allowance_charge_reason: "Volume discount",
        multiplier_factor_numeric: 5,
        base_amount: "200.00",
        amount: "10.00"
      }
  """

  alias ExCius.Enums.{
    AllowanceReasonCode,
    ChargeReasonCode,
    TaxCategory,
    TaxScheme
  }

  @doc """
  Validates a document-level allowance/charge.

  Document-level allowances/charges MUST include a tax_category.

  Returns `{:ok, allowance_charge}` or `{:error, errors}`.
  """
  def validate_document_level(allowance_charge) when is_map(allowance_charge) do
    allowance_charge = atomize_keys(allowance_charge)

    errors =
      []
      |> validate_charge_indicator(allowance_charge)
      |> validate_amount(allowance_charge)
      |> validate_reason_code(allowance_charge)
      |> validate_optional_reason(allowance_charge)
      |> validate_optional_multiplier(allowance_charge)
      |> validate_optional_base_amount(allowance_charge)
      |> validate_required_tax_category(allowance_charge)

    case errors do
      [] -> {:ok, allowance_charge}
      errors -> {:error, Enum.reverse(errors)}
    end
  end

  def validate_document_level(_), do: {:error, ["allowance_charge must be a map"]}

  @doc """
  Validates a line-level allowance/charge.

  Line-level allowances/charges SHOULD NOT include a tax_category.

  Returns `{:ok, allowance_charge}` or `{:error, errors}`.
  """
  def validate_line_level(allowance_charge) when is_map(allowance_charge) do
    allowance_charge = atomize_keys(allowance_charge)

    errors =
      []
      |> validate_charge_indicator(allowance_charge)
      |> validate_amount(allowance_charge)
      |> validate_reason_code(allowance_charge)
      |> validate_optional_reason(allowance_charge)
      |> validate_optional_multiplier(allowance_charge)
      |> validate_optional_base_amount(allowance_charge)
      |> warn_if_tax_category_present(allowance_charge)

    case errors do
      [] -> {:ok, Map.delete(allowance_charge, :tax_category)}
      errors -> {:error, Enum.reverse(errors)}
    end
  end

  def validate_line_level(_), do: {:error, ["allowance_charge must be a map"]}

  @doc """
  Validates a list of document-level allowances/charges.

  Returns `{:ok, allowances_charges}` or `{:error, errors}`.
  """
  def validate_document_level_list(nil), do: {:ok, []}
  def validate_document_level_list([]), do: {:ok, []}

  def validate_document_level_list(list) when is_list(list) do
    results =
      list
      |> Enum.with_index(1)
      |> Enum.map(fn {ac, index} ->
        case validate_document_level(ac) do
          {:ok, validated} -> {:ok, validated}
          {:error, errors} -> {:error, Enum.map(errors, &"allowance_charge[#{index}]: #{&1}")}
        end
      end)

    errors =
      Enum.flat_map(results, fn
        {:error, errs} -> errs
        _ -> []
      end)

    case errors do
      [] -> {:ok, Enum.map(results, fn {:ok, ac} -> ac end)}
      errors -> {:error, errors}
    end
  end

  def validate_document_level_list(_), do: {:error, ["allowance_charges must be a list"]}

  @doc """
  Validates a list of line-level allowances/charges.

  Returns `{:ok, allowances_charges}` or `{:error, errors}`.
  """
  def validate_line_level_list(nil), do: {:ok, []}
  def validate_line_level_list([]), do: {:ok, []}

  def validate_line_level_list(list) when is_list(list) do
    results =
      list
      |> Enum.with_index(1)
      |> Enum.map(fn {ac, index} ->
        case validate_line_level(ac) do
          {:ok, validated} -> {:ok, validated}
          {:error, errors} -> {:error, Enum.map(errors, &"allowance_charge[#{index}]: #{&1}")}
        end
      end)

    errors =
      Enum.flat_map(results, fn
        {:error, errs} -> errs
        _ -> []
      end)

    case errors do
      [] -> {:ok, Enum.map(results, fn {:ok, ac} -> ac end)}
      errors -> {:error, errors}
    end
  end

  def validate_line_level_list(_), do: {:error, ["allowance_charges must be a list"]}

  @doc """
  Checks if the given map represents a charge (surcharge/fee).
  """
  def charge?(%{charge_indicator: true}), do: true
  def charge?(_), do: false

  @doc """
  Checks if the given map represents an allowance (discount).
  """
  def allowance?(%{charge_indicator: false}), do: true
  def allowance?(_), do: false

  # Private validation functions

  defp validate_charge_indicator(errors, %{charge_indicator: value}) when is_boolean(value) do
    errors
  end

  defp validate_charge_indicator(errors, %{charge_indicator: _}) do
    ["charge_indicator must be a boolean (true for charge, false for allowance)" | errors]
  end

  defp validate_charge_indicator(errors, _) do
    ["charge_indicator is required" | errors]
  end

  defp validate_amount(errors, %{amount: amount}) when is_binary(amount) do
    case validate_decimal_string(amount) do
      :ok -> errors
      :error -> ["amount must be a valid decimal string" | errors]
    end
  end

  defp validate_amount(errors, %{amount: _}) do
    ["amount must be a string" | errors]
  end

  defp validate_amount(errors, _) do
    ["amount is required" | errors]
  end

  defp validate_reason_code(errors, %{charge_indicator: true, allowance_charge_reason_code: code}) do
    if code == nil or ChargeReasonCode.valid?(code) do
      errors
    else
      [
        "allowance_charge_reason_code '#{code}' is not a valid charge reason code (UNTDID 7161)"
        | errors
      ]
    end
  end

  defp validate_reason_code(errors, %{charge_indicator: false, allowance_charge_reason_code: code}) do
    if code == nil or AllowanceReasonCode.valid?(code) do
      errors
    else
      [
        "allowance_charge_reason_code '#{code}' is not a valid allowance reason code (UNTDID 5189)"
        | errors
      ]
    end
  end

  defp validate_reason_code(errors, _), do: errors

  defp validate_optional_reason(errors, %{allowance_charge_reason: reason})
       when is_binary(reason) and byte_size(reason) > 0 do
    errors
  end

  defp validate_optional_reason(errors, %{allowance_charge_reason: ""}) do
    ["allowance_charge_reason cannot be an empty string" | errors]
  end

  defp validate_optional_reason(errors, %{allowance_charge_reason: _}) do
    ["allowance_charge_reason must be a non-empty string" | errors]
  end

  defp validate_optional_reason(errors, _), do: errors

  defp validate_optional_multiplier(errors, %{multiplier_factor_numeric: value})
       when is_number(value) and value >= 0 do
    errors
  end

  defp validate_optional_multiplier(errors, %{multiplier_factor_numeric: _}) do
    ["multiplier_factor_numeric must be a non-negative number" | errors]
  end

  defp validate_optional_multiplier(errors, _), do: errors

  defp validate_optional_base_amount(errors, %{base_amount: amount}) when is_binary(amount) do
    case validate_decimal_string(amount) do
      :ok -> errors
      :error -> ["base_amount must be a valid decimal string" | errors]
    end
  end

  defp validate_optional_base_amount(errors, %{base_amount: _}) do
    ["base_amount must be a string" | errors]
  end

  defp validate_optional_base_amount(errors, _), do: errors

  defp validate_required_tax_category(errors, %{tax_category: nil}) do
    ["tax_category is required for document-level allowance/charge" | errors]
  end

  defp validate_required_tax_category(errors, %{tax_category: tax_category})
       when is_map(tax_category) do
    tax_category = atomize_keys(tax_category)

    errors
    |> validate_tax_category_id(tax_category)
    |> validate_tax_category_percent(tax_category)
    |> validate_tax_category_scheme(tax_category)
    |> validate_tax_exemption_fields(tax_category)
  end

  defp validate_required_tax_category(errors, %{tax_category: _}) do
    ["tax_category must be a map" | errors]
  end

  defp validate_required_tax_category(errors, _) do
    ["tax_category is required for document-level allowance/charge" | errors]
  end

  defp validate_tax_category_id(errors, %{id: id}) do
    if TaxCategory.valid?(id) do
      errors
    else
      ["tax_category.id '#{id}' is not a valid tax category" | errors]
    end
  end

  defp validate_tax_category_id(errors, _) do
    ["tax_category.id is required" | errors]
  end

  defp validate_tax_category_percent(errors, %{percent: percent})
       when is_number(percent) and percent >= 0 do
    errors
  end

  defp validate_tax_category_percent(errors, %{percent: _}) do
    ["tax_category.percent must be a non-negative number" | errors]
  end

  defp validate_tax_category_percent(errors, _) do
    ["tax_category.percent is required" | errors]
  end

  defp validate_tax_category_scheme(errors, %{tax_scheme_id: scheme}) do
    if TaxScheme.valid?(scheme) do
      errors
    else
      ["tax_category.tax_scheme_id '#{scheme}' is not a valid tax scheme" | errors]
    end
  end

  defp validate_tax_category_scheme(errors, _) do
    ["tax_category.tax_scheme_id is required" | errors]
  end

  defp validate_tax_exemption_fields(errors, %{id: id} = tax_category) do
    category_code = TaxCategory.code(id)

    # For exempt, reverse charge, or outside scope categories, exemption reason is recommended
    if category_code in ["E", "AE", "O"] do
      case Map.get(tax_category, :tax_exemption_reason) do
        nil -> errors
        reason when is_binary(reason) and byte_size(reason) > 0 -> errors
        "" -> ["tax_category.tax_exemption_reason cannot be empty" | errors]
        _ -> ["tax_category.tax_exemption_reason must be a string" | errors]
      end
    else
      errors
    end
  end

  defp validate_tax_exemption_fields(errors, _), do: errors

  defp warn_if_tax_category_present(errors, %{tax_category: tax_category})
       when not is_nil(tax_category) do
    # We don't add an error, just log a warning and strip it out
    # The calling code in validate_line_level/1 removes tax_category
    errors
  end

  defp warn_if_tax_category_present(errors, _), do: errors

  defp validate_decimal_string(value) do
    case Float.parse(value) do
      {_float, ""} -> :ok
      _ -> :error
    end
  end

  defp atomize_keys(map) when is_map(map) do
    Map.new(map, fn
      {key, value} when is_binary(key) ->
        {String.to_existing_atom(key), maybe_atomize_nested(value)}

      {key, value} when is_atom(key) ->
        {key, maybe_atomize_nested(value)}
    end)
  rescue
    ArgumentError -> map
  end

  defp maybe_atomize_nested(value) when is_map(value), do: atomize_keys(value)
  defp maybe_atomize_nested(value), do: value
end
