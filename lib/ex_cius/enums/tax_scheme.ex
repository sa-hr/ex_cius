defmodule ExCius.Enums.TaxScheme do
  @moduledoc """
  Supported tax scheme IDs for UBL invoices.

  - `:vat` - Standard VAT scheme (generates "VAT")
  - `:fre` - Not in VAT system / VAT exempt supplier (generates "FRE")
  """

  @schemes %{
    vat: "VAT",
    fre: "FRE"
  }

  def valid?(value) when is_atom(value), do: Map.has_key?(@schemes, value)

  def valid?(value) when is_binary(value) do
    Map.has_key?(@schemes, String.to_existing_atom(value)) or value in Map.values(@schemes)
  rescue
    ArgumentError -> value in Map.values(@schemes)
  end

  def valid?(_), do: false

  def values, do: Map.keys(@schemes)

  def default, do: :vat

  def code(:vat), do: "VAT"
  def code("vat"), do: "VAT"
  def code("VAT"), do: "VAT"
  def code(:fre), do: "FRE"
  def code("fre"), do: "FRE"
  def code("FRE"), do: "FRE"

  def vat, do: :vat
  def fre, do: :fre
end
