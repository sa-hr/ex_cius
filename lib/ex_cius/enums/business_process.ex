defmodule ExCius.Enums.BusinessProcess do
  @moduledoc """
  Business Process (ProfileID) codes for Croatian e-Invoice (Fiskalizacija 2.0).

  These codes identify the specific business process for the invoice according to
  the Croatian specification (Tablica 4 - Poslovni procesi).

  Reference: Croatian CIUS-2025 Specification, Table 4
  """

  @processes %{
    # P1: Issuing invoices for supplies of goods and services according to
    # purchase orders, based on a contract.
    # (Izdavanje računa za isporuku dobara i usluga prema narudžbenicama, na temelju ugovora)
    p1: "P1",

    # P2: Periodic Invoicing for Supplies of Goods and Services on the Basis of a Contract.
    # (Periodično fakturiranje za isporuke dobara i usluga na temelju ugovora)
    p2: "P2",

    # P3: Issuance of invoices for delivery according to a separate purchase order.
    # (Izdavanje računa za isporuku prema pojedinačnoj narudžbenici)
    p3: "P3",

    # P4: Payment in advance (Prepayment).
    # (Plaćanje unaprijed - Predujam)
    p4: "P4",

    # P5: Payment on the spot (Spot payment).
    # (Plaćanje na licu mjesta - Gotovinski račun)
    p5: "P5",

    # P6: Payment before delivery, based on purchase order.
    # (Plaćanje prije isporuke, na temelju narudžbenice)
    p6: "P6",

    # P7: Issuing invoices with references to the delivery note.
    # (Izdavanje računa s referencom na otpremnicu)
    p7: "P7",

    # P8: Issuing invoices with references to the delivery note and receipt.
    # (Izdavanje računa s referencom na otpremnicu i primku)
    p8: "P8",

    # P9: Credit notes or invoices with negative amounts (including return of empty packaging).
    # (Odobrenja ili računi s negativnim iznosima, uključujući povrat ambalaže)
    p9: "P9",

    # P10: Issuance of a corrective invoice (Cancellation/Correction).
    # (Izdavanje korektivnog računa - Storniranje/Ispravak)
    p10: "P10",

    # P11: Issuance of partial and final invoices.
    # (Izdavanje djelomičnih i konačnih računa)
    p11: "P11",

    # P12: Self-issuance of invoices.
    # (Samofakturiranje)
    p12: "P12",

    # P99: Customer-defined process.
    # (Korisnički definirani proces)
    p99: "P99",

    # Legacy alias for P1 (kept for backwards compatibility)
    billing: "P1"
  }

  @descriptions %{
    p1:
      "Issuing invoices for supplies of goods and services according to purchase orders, based on a contract",
    p2: "Periodic Invoicing for Supplies of Goods and Services on the Basis of a Contract",
    p3: "Issuance of invoices for delivery according to a separate purchase order",
    p4: "Payment in advance (Prepayment)",
    p5: "Payment on the spot (Spot payment)",
    p6: "Payment before delivery, based on purchase order",
    p7: "Issuing invoices with references to the delivery note",
    p8: "Issuing invoices with references to the delivery note and receipt",
    p9: "Credit notes or invoices with negative amounts (including return of empty packaging)",
    p10: "Issuance of a corrective invoice (Cancellation/Correction)",
    p11: "Issuance of partial and final invoices",
    p12: "Self-issuance of invoices",
    p99: "Customer-defined process",
    billing:
      "Issuing invoices for supplies of goods and services according to purchase orders, based on a contract"
  }

  @doc """
  Checks if the given value is a valid business process identifier.

  ## Examples

      iex> ExCius.Enums.BusinessProcess.valid?(:p1)
      true

      iex> ExCius.Enums.BusinessProcess.valid?("P1")
      true

      iex> ExCius.Enums.BusinessProcess.valid?(:invalid)
      false
  """
  def valid?(value) when is_atom(value), do: Map.has_key?(@processes, value)

  def valid?(value) when is_binary(value) do
    Map.has_key?(@processes, String.to_existing_atom(value)) or value in Map.values(@processes)
  rescue
    ArgumentError -> value in Map.values(@processes)
  end

  def valid?(_), do: false

  @doc """
  Returns all valid business process atom keys.
  """
  def values, do: Map.keys(@processes)

  @doc """
  Returns the default business process (:p1).
  """
  def default, do: :p1

  @doc """
  Returns the description for a given business process.

  ## Examples

      iex> ExCius.Enums.BusinessProcess.description(:p1)
      "Issuing invoices for supplies of goods and services according to purchase orders, based on a contract"

      iex> ExCius.Enums.BusinessProcess.description(:p9)
      "Credit notes or invoices with negative amounts (including return of empty packaging)"
  """
  def description(key) when is_atom(key), do: Map.get(@descriptions, key)
  def description(_), do: nil

  # Generate code/1 functions for all processes
  for {atom, code} <- @processes do
    def code(unquote(atom)), do: unquote(code)
    def code(unquote(to_string(atom))), do: unquote(code)
    def code(unquote(code)), do: unquote(code)
  end

  def code(_), do: nil

  # Generate accessor functions for all process types
  for atom <- Map.keys(@processes) do
    def unquote(atom)(), do: unquote(atom)
  end

  @doc """
  Converts a code string to its atom representation.

  ## Examples

      iex> ExCius.Enums.BusinessProcess.from_code("P1")
      :p1

      iex> ExCius.Enums.BusinessProcess.from_code("P10")
      :p10

      iex> ExCius.Enums.BusinessProcess.from_code("INVALID")
      nil
  """
  def from_code("P1"), do: :p1
  def from_code("P2"), do: :p2
  def from_code("P3"), do: :p3
  def from_code("P4"), do: :p4
  def from_code("P5"), do: :p5
  def from_code("P6"), do: :p6
  def from_code("P7"), do: :p7
  def from_code("P8"), do: :p8
  def from_code("P9"), do: :p9
  def from_code("P10"), do: :p10
  def from_code("P11"), do: :p11
  def from_code("P12"), do: :p12
  def from_code("P99"), do: :p99
  def from_code(_), do: nil
end
