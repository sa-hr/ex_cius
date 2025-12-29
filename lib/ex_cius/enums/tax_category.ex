defmodule ExCius.Enums.TaxCategory do
  @moduledoc """
  Supported tax category IDs for UBL invoices (EN16931).

  Regarding Croatian VAT rates of 13% and 5%, these are considered reduced rates.
  In UBL, they fall under the 'S' (Standard) category. You should use
  `:standard_rate` and provide the appropriate `percent` value (13 or 5)
  when constructing the invoice.
  """

  @categories %{
    standard_rate: "S",
    zero_rate: "Z",
    exempt: "E",
    reverse_charge: "AE",
    intra_community: "K",
    export: "G",
    outside_scope: "O"
  }

  def valid?(value) when is_atom(value), do: Map.has_key?(@categories, value)

  def valid?(value) when is_binary(value) do
    Map.has_key?(@categories, String.to_existing_atom(value)) or value in Map.values(@categories)
  rescue
    ArgumentError -> value in Map.values(@categories)
  end

  def valid?(_), do: false

  def values, do: Map.keys(@categories)

  def default, do: :standard_rate

  for {atom, code} <- @categories do
    def code(unquote(atom)), do: unquote(code)
    def code(unquote(to_string(atom))), do: unquote(code)
    def code(unquote(code)), do: unquote(code)
  end

  def code(_), do: nil

  for atom <- Map.keys(@categories) do
    def unquote(atom)(), do: unquote(atom)
  end
end
