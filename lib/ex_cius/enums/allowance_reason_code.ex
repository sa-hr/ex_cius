defmodule ExCius.Enums.AllowanceReasonCode do
  @moduledoc """
  Allowance reason codes based on UNTDID 5189.

  These codes identify the reason for an allowance (discount) being applied.
  Used in UBL 2.1 AllowanceCharge elements when ChargeIndicator is false.

  Reference: UN/EDIFACT Data Element 5189 - Allowance or charge identification code
  """

  @codes %{
    # Common discount reasons
    bonus_for_works_ahead_of_schedule: "41",
    other_bonus: "42",
    manufacturer_consumer_discount: "60",
    due_to_military_status: "62",
    due_to_work_accident: "63",
    special_agreement: "64",
    production_error_discount: "65",
    new_outlet_discount: "66",
    sample_discount: "67",
    end_of_range_discount: "68",
    incoterm_discount: "70",
    point_of_sales_threshold_allowance: "71",
    material_surcharge_deduction: "88",
    discount: "95",
    special_rebate: "100",
    fixed_long_term: "102",
    temporary: "103",
    standard: "104",
    yearly_turnover: "105"
  }

  def valid?(value) when is_atom(value), do: Map.has_key?(@codes, value)

  def valid?(value) when is_binary(value) do
    Map.has_key?(@codes, String.to_existing_atom(value)) or value in Map.values(@codes)
  rescue
    ArgumentError -> value in Map.values(@codes)
  end

  def valid?(_), do: false

  def values, do: Map.keys(@codes)

  def default, do: :discount

  for {atom, code} <- @codes do
    def code(unquote(atom)), do: unquote(code)
    def code(unquote(to_string(atom))), do: unquote(code)
    def code(unquote(code)), do: unquote(code)
  end

  def code(_), do: nil

  for atom <- Map.keys(@codes) do
    def unquote(atom)(), do: unquote(atom)
  end
end
