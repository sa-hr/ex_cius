defmodule ExCius.Enums.UnitCode do
  @moduledoc """
  Supported unit codes for UBL invoices (UN/ECE Recommendation 20).

  This module contains the most commonly used unit codes for SMB invoicing,
  covering approximately 99% of business use cases.
  """

  @codes %{
    # Most common counting units
    each: "EA",
    piece: "H87",
    set: "SET",
    pair: "PR",
    dozen: "DZN",
    hundred: "CEN",
    thousand: "MIL",

    # Weight/Mass units
    kilogram: "KGM",
    gram: "GRM",
    tonne: "TNE",
    pound: "LBR",
    ounce: "ONZ",

    # Length/Distance units
    metre: "MTR",
    centimetre: "CMT",
    millimetre: "MMT",
    kilometre: "KMT",
    foot: "FOT",
    inch: "INH",
    yard: "YRD",

    # Area units
    square_metre: "MTK",
    square_centimetre: "CMK",
    square_foot: "FTK",
    square_inch: "INK",

    # Volume units
    cubic_metre: "MTQ",
    litre: "LTR",
    millilitre: "MLT",
    cubic_foot: "FTQ",
    gallon_us: "GLL",
    gallon_uk: "GLI",

    # Time units
    second: "SEC",
    minute: "MIN",
    hour: "HUR",
    day: "DAY",
    week: "WEE",
    month: "MON",
    year: "ANN",

    # Energy/Power units
    kilowatt_hour: "KWH",
    watt: "WTT",
    joule: "JOU",
    kilojoule: "KJO",

    # Rate/Service units
    rate: "A9",
    percent: "P1",

    # Common business/packaging units
    box: "BX",
    case: "CS",
    package: "PK",
    carton: "CT",
    pallet: "PX",
    roll: "RO",
    sheet: "ST",
    bottle: "BO",
    bag: "BG",
    tube: "TU",
    can: "CA",
    jar: "JR"
  }

  def valid?(value) when is_atom(value), do: Map.has_key?(@codes, value)

  def valid?(value) when is_binary(value) do
    Map.has_key?(@codes, String.to_existing_atom(value)) or value in Map.values(@codes)
  rescue
    ArgumentError -> value in Map.values(@codes)
  end

  def valid?(_), do: false

  def values, do: Map.keys(@codes)

  def default, do: :each

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
