defmodule ExCius.OrderReference do
  @moduledoc """
  Order Reference (BT-13, BT-14) for Croatian e-Invoice (CIUS-2025).

  This module handles references to purchase orders and sales orders:
  - BT-13 (Buyer Order Reference): The buyer's purchase order number
  - BT-14 (Sales Order Reference): The seller's sales order/quotation number

  These fields are independent and can exist in any combination:
  - Both: Buyer sends a purchase order referencing seller's quotation
  - Only BT-13: Direct order from buyer without prior quotation
  - Only BT-14: Buyer accepted quotation but didn't send their own order number
  - Neither: No order reference needed

  The OrderReference maps to UBL 2.1 structure:
  - `cac:OrderReference`
    - `cbc:ID` - Buyer's order reference (BT-13)
    - `cbc:SalesOrderID` - Seller's order/quotation reference (BT-14)

  Reference: EN 16931-1:2017, BT-13 (Purchase order reference) and BT-14 (Sales order reference)
  Croatian CIUS-2025 Specification
  """

  defstruct [:buyer_reference, :sales_order_id]

  @type t :: %__MODULE__{
          buyer_reference: String.t() | nil,
          sales_order_id: String.t() | nil
        }

  @doc """
  Creates a new OrderReference struct.

  ## Parameters

  - `attrs` - A map containing:
    - `:buyer_reference` - BT-13: Buyer's purchase order number (optional)
    - `:sales_order_id` - BT-14: Seller's sales order/quotation number (optional)

  At least one of the fields must be present.

  ## Examples

      iex> ExCius.OrderReference.new(%{
      ...>   buyer_reference: "PO-2025-001",
      ...>   sales_order_id: "QUO-2025-100"
      ...> })
      {:ok, %ExCius.OrderReference{
        buyer_reference: "PO-2025-001",
        sales_order_id: "QUO-2025-100"
      }}

      iex> ExCius.OrderReference.new(%{buyer_reference: "PO-2025-001"})
      {:ok, %ExCius.OrderReference{buyer_reference: "PO-2025-001", sales_order_id: nil}}

      iex> ExCius.OrderReference.new(%{sales_order_id: "QUO-2025-100"})
      {:ok, %ExCius.OrderReference{buyer_reference: nil, sales_order_id: "QUO-2025-100"}}

      iex> ExCius.OrderReference.new(%{})
      {:error, %{order_reference: "at least one of buyer_reference (BT-13) or sales_order_id (BT-14) is required"}}
  """
  def new(attrs) when is_map(attrs) do
    attrs = atomize_keys(attrs)

    buyer_reference = attrs[:buyer_reference]
    sales_order_id = attrs[:sales_order_id]

    with :ok <- validate_at_least_one_present(buyer_reference, sales_order_id),
         :ok <- validate_buyer_reference(buyer_reference),
         :ok <- validate_sales_order_id(sales_order_id) do
      {:ok,
       %__MODULE__{
         buyer_reference: buyer_reference,
         sales_order_id: sales_order_id
       }}
    end
  end

  def new(_), do: {:error, %{order_reference: "must be a map"}}

  @doc """
  Creates a new OrderReference struct, raising on error.

  ## Examples

      iex> ExCius.OrderReference.new!(%{buyer_reference: "PO-2025-001"})
      %ExCius.OrderReference{buyer_reference: "PO-2025-001", sales_order_id: nil}
  """
  def new!(attrs) do
    case new(attrs) do
      {:ok, order_ref} -> order_ref
      {:error, errors} -> raise ArgumentError, "Invalid OrderReference: #{inspect(errors)}"
    end
  end

  @doc """
  Validates order reference data without creating a struct.

  Returns `:ok` if valid, or `{:error, errors}` if invalid.

  ## Examples

      iex> ExCius.OrderReference.validate(%{buyer_reference: "PO-001"})
      :ok

      iex> ExCius.OrderReference.validate(%{sales_order_id: "QUO-001"})
      :ok

      iex> ExCius.OrderReference.validate(%{})
      {:error, %{order_reference: "at least one of buyer_reference (BT-13) or sales_order_id (BT-14) is required"}}
  """
  def validate(attrs) when is_map(attrs) do
    case new(attrs) do
      {:ok, _} -> :ok
      error -> error
    end
  end

  def validate(_), do: {:error, %{order_reference: "must be a map"}}

  @doc """
  Converts an OrderReference struct to a map suitable for XML generation.

  ## Examples

      iex> ref = %ExCius.OrderReference{
      ...>   buyer_reference: "PO-001",
      ...>   sales_order_id: "QUO-001"
      ...> }
      iex> ExCius.OrderReference.to_map(ref)
      %{buyer_reference: "PO-001", sales_order_id: "QUO-001"}
  """
  def to_map(%__MODULE__{} = order_ref) do
    %{
      buyer_reference: order_ref.buyer_reference,
      sales_order_id: order_ref.sales_order_id
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end

  @doc """
  Checks if an order reference should be generated based on provided data.

  Returns `true` if at least one of buyer_reference or sales_order_id is present.

  ## Examples

      iex> ExCius.OrderReference.should_generate?(%{buyer_reference: "PO-001"})
      true

      iex> ExCius.OrderReference.should_generate?(%{})
      false

      iex> ExCius.OrderReference.should_generate?(nil)
      false
  """
  def should_generate?(nil), do: false

  def should_generate?(attrs) when is_map(attrs) and map_size(attrs) == 0, do: false

  def should_generate?(attrs) when is_map(attrs) do
    attrs = atomize_keys(attrs)
    has_value?(attrs[:buyer_reference]) or has_value?(attrs[:sales_order_id])
  end

  def should_generate?(_), do: false

  # Private validation functions

  defp validate_at_least_one_present(buyer_reference, sales_order_id) do
    if has_value?(buyer_reference) or has_value?(sales_order_id) do
      :ok
    else
      {:error,
       %{
         order_reference:
           "at least one of buyer_reference (BT-13) or sales_order_id (BT-14) is required"
       }}
    end
  end

  defp validate_buyer_reference(nil), do: :ok
  defp validate_buyer_reference(value) when is_binary(value) and byte_size(value) > 0, do: :ok
  defp validate_buyer_reference(""), do: :ok

  defp validate_buyer_reference(_) do
    {:error, %{buyer_reference: "must be a non-empty string"}}
  end

  defp validate_sales_order_id(nil), do: :ok
  defp validate_sales_order_id(value) when is_binary(value) and byte_size(value) > 0, do: :ok
  defp validate_sales_order_id(""), do: :ok

  defp validate_sales_order_id(_) do
    {:error, %{sales_order_id: "must be a non-empty string"}}
  end

  defp has_value?(nil), do: false
  defp has_value?(""), do: false
  defp has_value?(value) when is_binary(value), do: true
  defp has_value?(_), do: false

  defp atomize_keys(map) when is_map(map) do
    Map.new(map, fn
      {key, value} when is_binary(key) ->
        atom_key =
          try do
            String.to_existing_atom(key)
          rescue
            ArgumentError -> String.to_atom(key)
          end

        {atom_key, value}

      {key, value} ->
        {key, value}
    end)
  end
end
