defmodule ExCius.Enums.InvoiceTypeCode do
  @moduledoc """
  Supported invoice type codes for UBL invoices (UNTDID 1001).
  """

  @codes %{
    commercial_invoice: "380",
    credit_note: "381",
    corrected_invoice: "384",
    self_billed_invoice: "389",
    invoice_information: "751"
  }

  def valid?(value) when is_atom(value), do: Map.has_key?(@codes, value)

  def valid?(value) when is_binary(value) do
    Map.has_key?(@codes, String.to_existing_atom(value)) or value in Map.values(@codes)
  rescue
    ArgumentError -> value in Map.values(@codes)
  end

  def valid?(_), do: false

  def values, do: Map.keys(@codes)

  def default, do: :commercial_invoice

  def code(:commercial_invoice), do: "380"
  def code(:credit_note), do: "381"
  def code(:corrected_invoice), do: "384"
  def code(:self_billed_invoice), do: "389"
  def code(:invoice_information), do: "751"
  def code("commercial_invoice"), do: "380"
  def code("credit_note"), do: "381"
  def code("corrected_invoice"), do: "384"
  def code("self_billed_invoice"), do: "389"
  def code("invoice_information"), do: "751"
  def code("380"), do: "380"
  def code("381"), do: "381"
  def code("384"), do: "384"
  def code("389"), do: "389"
  def code("751"), do: "751"

  def commercial_invoice, do: :commercial_invoice
  def credit_note, do: :credit_note
  def corrected_invoice, do: :corrected_invoice
  def self_billed_invoice, do: :self_billed_invoice
  def invoice_information, do: :invoice_information
end
