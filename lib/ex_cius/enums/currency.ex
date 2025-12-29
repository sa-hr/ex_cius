defmodule ExCius.Enums.Currency do
  @moduledoc """
  Supported currency codes for UBL invoices (ISO 4217).
  """

  @currencies %{
    EUR: "EUR"
  }

  def valid?(value) when is_atom(value), do: Map.has_key?(@currencies, value)

  def valid?(value) when is_binary(value) do
    Map.has_key?(@currencies, String.to_existing_atom(value)) or value in Map.values(@currencies)
  rescue
    ArgumentError -> value in Map.values(@currencies)
  end

  def valid?(_), do: false

  def values, do: Map.keys(@currencies)

  def default, do: :EUR

  def code(:EUR), do: "EUR"
  def code("EUR"), do: "EUR"

  def eur, do: :EUR
end
