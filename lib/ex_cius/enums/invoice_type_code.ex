defmodule ExCius.Enums.InvoiceTypeCode do
  @moduledoc """
  Invoice type codes for Croatian e-Invoice (Fiskalizacija 2.0).

  These codes are based on the UNTDID 1001 subset used in the Croatian specification.
  They identify the type of document being issued.

  Reference: UN/EDIFACT Data Element 1001 - Document name code
  Croatian CIUS-2025 Specification
  """

  @codes %{
    # 380: Commercial Invoice (Standard)
    # Standard invoice for goods and services
    # (Standardni račun - Komercijalni račun)
    commercial_invoice: "380",

    # 381: Credit Note (Odobrenje)
    # Document used to credit a previous invoice, typically for returns or price adjustments
    # (Odobrenje - dokument za umanjenje prethodno izdanog računa)
    credit_note: "381",

    # 383: Debit Note (Terećenje)
    # Document used to debit/charge additional amounts to a previous invoice
    # (Terećenje - dokument za dodatno zaduženje)
    debit_note: "383",

    # 384: Corrected Invoice (Korektivni račun)
    # Invoice issued to correct a previously issued invoice
    # (Korektivni račun - ispravak prethodno izdanog računa)
    corrected_invoice: "384",

    # 386: Prepayment Invoice (Račun za predujam)
    # Invoice issued for advance payment before delivery of goods/services
    # (Račun za predujam - avansni račun)
    prepayment_invoice: "386",

    # Legacy codes kept for backwards compatibility
    self_billed_invoice: "389",
    invoice_information: "751"
  }

  @descriptions %{
    commercial_invoice: "Commercial Invoice (Standard)",
    credit_note: "Credit Note (Odobrenje)",
    debit_note: "Debit Note (Terećenje)",
    corrected_invoice: "Corrected Invoice (Korektivni račun)",
    prepayment_invoice: "Prepayment Invoice (Račun za predujam)",
    self_billed_invoice: "Self-billed Invoice",
    invoice_information: "Invoice Information for Accounting Purposes"
  }

  @doc """
  Checks if the given value is a valid invoice type code.

  ## Examples

      iex> ExCius.Enums.InvoiceTypeCode.valid?(:commercial_invoice)
      true

      iex> ExCius.Enums.InvoiceTypeCode.valid?("380")
      true

      iex> ExCius.Enums.InvoiceTypeCode.valid?(:credit_note)
      true

      iex> ExCius.Enums.InvoiceTypeCode.valid?(:invalid)
      false
  """
  def valid?(value) when is_atom(value), do: Map.has_key?(@codes, value)

  def valid?(value) when is_binary(value) do
    Map.has_key?(@codes, String.to_existing_atom(value)) or value in Map.values(@codes)
  rescue
    ArgumentError -> value in Map.values(@codes)
  end

  def valid?(_), do: false

  @doc """
  Returns all valid invoice type code atom keys.
  """
  def values, do: Map.keys(@codes)

  @doc """
  Returns the default invoice type code (:commercial_invoice).
  """
  def default, do: :commercial_invoice

  @doc """
  Returns the description for a given invoice type code.

  ## Examples

      iex> ExCius.Enums.InvoiceTypeCode.description(:commercial_invoice)
      "Commercial Invoice (Standard)"

      iex> ExCius.Enums.InvoiceTypeCode.description(:credit_note)
      "Credit Note (Odobrenje)"
  """
  def description(key) when is_atom(key), do: Map.get(@descriptions, key)
  def description(_), do: nil

  # Generate code/1 functions for all invoice types
  for {atom, code} <- @codes do
    def code(unquote(atom)), do: unquote(code)
    def code(unquote(to_string(atom))), do: unquote(code)
    def code(unquote(code)), do: unquote(code)
  end

  def code(_), do: nil

  # Generate accessor functions for all invoice types
  for atom <- Map.keys(@codes) do
    def unquote(atom)(), do: unquote(atom)
  end

  @doc """
  Converts a code string to its atom representation.

  ## Examples

      iex> ExCius.Enums.InvoiceTypeCode.from_code("380")
      :commercial_invoice

      iex> ExCius.Enums.InvoiceTypeCode.from_code("381")
      :credit_note

      iex> ExCius.Enums.InvoiceTypeCode.from_code("384")
      :corrected_invoice

      iex> ExCius.Enums.InvoiceTypeCode.from_code("INVALID")
      nil
  """
  def from_code("380"), do: :commercial_invoice
  def from_code("381"), do: :credit_note
  def from_code("383"), do: :debit_note
  def from_code("384"), do: :corrected_invoice
  def from_code("386"), do: :prepayment_invoice
  def from_code("389"), do: :self_billed_invoice
  def from_code("751"), do: :invoice_information
  def from_code(_), do: nil

  @doc """
  Checks if the given invoice type code represents a credit-type document.

  Credit-type documents include credit notes and corrected invoices.

  ## Examples

      iex> ExCius.Enums.InvoiceTypeCode.credit_type?(:credit_note)
      true

      iex> ExCius.Enums.InvoiceTypeCode.credit_type?(:corrected_invoice)
      true

      iex> ExCius.Enums.InvoiceTypeCode.credit_type?(:commercial_invoice)
      false
  """
  def credit_type?(:credit_note), do: true
  def credit_type?(:corrected_invoice), do: true
  def credit_type?("381"), do: true
  def credit_type?("384"), do: true
  def credit_type?(_), do: false

  @doc """
  Checks if the given invoice type code requires a billing reference.

  Credit notes (381), corrected invoices (384), and debit notes (383) typically
  require a reference to the original invoice being credited/corrected.

  ## Examples

      iex> ExCius.Enums.InvoiceTypeCode.requires_billing_reference?(:credit_note)
      true

      iex> ExCius.Enums.InvoiceTypeCode.requires_billing_reference?(:commercial_invoice)
      false
  """
  def requires_billing_reference?(:credit_note), do: true
  def requires_billing_reference?(:corrected_invoice), do: true
  def requires_billing_reference?(:debit_note), do: true
  def requires_billing_reference?("381"), do: true
  def requires_billing_reference?("383"), do: true
  def requires_billing_reference?("384"), do: true
  def requires_billing_reference?(_), do: false
end
