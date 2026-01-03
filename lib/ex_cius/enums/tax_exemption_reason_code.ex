defmodule ExCius.Enums.TaxExemptionReasonCode do
  @moduledoc """
  Tax exemption reason codes for Croatian e-Invoice (Fiskalizacija 2.0).

  These codes identify the legal basis for tax exemption in Croatia.
  Used in UBL 2.1 TaxCategory elements when the tax category is exempt (E),
  reverse charge (AE), or outside scope (O).

  Reference: Croatian VAT Law (Zakon o PDV-u) and EN 16931 Codelist
  """

  @codes %{
    # VAT reverse charge codes (Article 75 of Croatian VAT Law)
    reverse_charge_construction: "vatex-eu-ae-construction",
    reverse_charge_waste: "vatex-eu-ae-waste",
    reverse_charge_gold: "vatex-eu-ae-gold",
    reverse_charge_greenhouse: "vatex-eu-ae-greenhouse",
    reverse_charge_general: "vatex-eu-ae",

    # Intra-community supply (Article 41 of Croatian VAT Law)
    intra_community_supply: "vatex-eu-ic",

    # Export exemptions (Article 45 of Croatian VAT Law)
    export: "vatex-eu-g",

    # Exempt without right of deduction
    exempt_insurance: "vatex-eu-e-insurance",
    exempt_financial: "vatex-eu-e-financial",
    exempt_medical: "vatex-eu-e-medical",
    exempt_education: "vatex-eu-e-education",
    exempt_cultural: "vatex-eu-e-cultural",
    exempt_sports: "vatex-eu-e-sports",
    exempt_postal: "vatex-eu-e-postal",
    exempt_immovable: "vatex-eu-e-immovable",
    exempt_general: "vatex-eu-e",

    # Outside scope of VAT
    outside_scope: "vatex-eu-o",
    outside_scope_article_15: "vatex-eu-o-15",

    # Croatian specific codes
    hr_small_business: "HR:OssObv",
    hr_margin_scheme: "HR:MarginScheme",
    hr_travel_agents: "HR:TravelAgents",
    hr_second_hand: "HR:SecondHand",
    hr_art_objects: "HR:ArtObjects",
    hr_antiques: "HR:Antiques"
  }

  def valid?(value) when is_atom(value), do: Map.has_key?(@codes, value)

  def valid?(value) when is_binary(value) do
    Map.has_key?(@codes, String.to_existing_atom(value)) or value in Map.values(@codes)
  rescue
    ArgumentError -> value in Map.values(@codes)
  end

  def valid?(_), do: false

  def values, do: Map.keys(@codes)

  def default, do: :exempt_general

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
