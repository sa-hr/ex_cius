defmodule ExCius.Enums.UnitCode do
  @moduledoc """
  Supported unit codes for UBL invoices (UN/ECE Recommendation 20).
  """

  @codes %{
    piece: "H87"
  }

  def valid?(value) when is_atom(value), do: Map.has_key?(@codes, value)

  def valid?(value) when is_binary(value) do
    Map.has_key?(@codes, String.to_existing_atom(value)) or value in Map.values(@codes)
  rescue
    ArgumentError -> value in Map.values(@codes)
  end

  def valid?(_), do: false

  def values, do: Map.keys(@codes)

  def default, do: :piece

  def code(:piece), do: "H87"
  def code("piece"), do: "H87"
  def code("H87"), do: "H87"

  def piece, do: :piece
end
