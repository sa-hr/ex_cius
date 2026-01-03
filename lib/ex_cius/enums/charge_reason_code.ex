defmodule ExCius.Enums.ChargeReasonCode do
  @moduledoc """
  Charge reason codes based on UNTDID 7161.

  These codes identify the reason for a charge (surcharge/fee) being applied.
  Used in UBL 2.1 AllowanceCharge elements when ChargeIndicator is true.

  Reference: UN/EDIFACT Data Element 7161 - Special services identification code
  """

  @codes %{
    # Common charge reasons
    advertising: "AA",
    telecommunication: "AAA",
    technical_modification: "AAC",
    job_order_administration: "AAD",
    warehousing: "AAF",
    engineering_change: "AAH",
    acceptance: "AAI",
    packing: "ABK",
    miscellaneous: "ABL",
    additional_packaging: "ABN",
    inspection: "ABO",
    security: "ABZ",
    freight_service: "ACA",
    installation: "ACF",
    lighting: "ACV",
    cleaning: "ADC",
    marking_labelling: "ADI",
    certificate_of_origin: "ADQ",
    testing: "ADS",
    transportation: "ADT",
    handling: "ADW",
    customs_duties: "CAC",
    cash_discount: "CAD",
    cash_on_delivery: "CAE",
    insurance: "CAI",
    transfer: "CAJ",
    loading: "CAL",
    packaging: "CAM",
    dangerous_goods_fee: "DAD",
    delivery: "DL",
    environmental_protection: "EAA",
    fixed_special_allowance: "FC",
    freight: "FI",
    financing: "FN",
    handling_commission: "HD",
    in_transit: "IN",
    invoice_entry_support: "IS",
    minimum_order_minimum_billing: "MAC",
    pick_up: "NAA",
    pre_carriage: "PC",
    discount: "RAA",
    special_handling: "SH",
    export_packing: "TAB",
    reclamation_fee: "TAC",
    deposit_fee: "ABB",
    recycling_fee: "ABF",
    # Croatian specific - Povratna naknada (deposit/return fee)
    return_handling: "RAH"
  }

  def valid?(value) when is_atom(value), do: Map.has_key?(@codes, value)

  def valid?(value) when is_binary(value) do
    Map.has_key?(@codes, String.to_existing_atom(value)) or value in Map.values(@codes)
  rescue
    ArgumentError -> value in Map.values(@codes)
  end

  def valid?(_), do: false

  def values, do: Map.keys(@codes)

  def default, do: :miscellaneous

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
