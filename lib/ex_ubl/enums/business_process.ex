defmodule ExUBL.Enums.BusinessProcess do
  @moduledoc """
  Supported business process (profile) IDs for UBL invoices.
  """

  @processes %{
    billing: "P1"
  }

  def valid?(value) when is_atom(value), do: Map.has_key?(@processes, value)

  def valid?(value) when is_binary(value) do
    Map.has_key?(@processes, String.to_existing_atom(value)) or value in Map.values(@processes)
  rescue
    ArgumentError -> value in Map.values(@processes)
  end

  def valid?(_), do: false

  def values, do: Map.keys(@processes)

  def default, do: :billing

  def code(:billing), do: "P1"
  def code("billing"), do: "P1"
  def code("P1"), do: "P1"

  def billing, do: :billing
end
