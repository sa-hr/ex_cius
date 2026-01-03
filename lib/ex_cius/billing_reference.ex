defmodule ExCius.BillingReference do
  @moduledoc """
  Billing Reference (BG-3) for Croatian e-Invoice (Fiskalizacija 2.0).

  This module handles references to preceding invoices, which is critical for:
  - Corrective Invoices (P10/384) - Must reference the invoice being corrected
  - Credit Notes (381) - Must reference the invoice being credited
  - Debit Notes (383) - Must reference the invoice being debited

  The BillingReference contains an InvoiceDocumentReference with:
  - ID: The number/identifier of the original invoice being referenced
  - IssueDate: The issue date of the original invoice

  Reference: EN 16931-1:2017, Business Group BG-3 (PRECEDING INVOICE REFERENCE)
  Croatian CIUS-2025 Specification
  """

  @enforce_keys [:invoice_document_reference]
  defstruct [:invoice_document_reference]

  @type t :: %__MODULE__{
          invoice_document_reference: invoice_document_reference()
        }

  @type invoice_document_reference :: %{
          required(:id) => String.t(),
          optional(:issue_date) => Date.t() | String.t()
        }

  @doc """
  Creates a new BillingReference struct.

  ## Parameters

  - `attrs` - A map containing:
    - `:invoice_document_reference` - A map with `:id` (required) and `:issue_date` (optional)

  ## Examples

      iex> ExCius.BillingReference.new(%{
      ...>   invoice_document_reference: %{
      ...>     id: "INV-2025-001",
      ...>     issue_date: ~D[2025-01-15]
      ...>   }
      ...> })
      {:ok, %ExCius.BillingReference{
        invoice_document_reference: %{
          id: "INV-2025-001",
          issue_date: ~D[2025-01-15]
        }
      }}

      iex> ExCius.BillingReference.new(%{})
      {:error, %{invoice_document_reference: "is required"}}
  """
  def new(attrs) when is_map(attrs) do
    with {:ok, invoice_doc_ref} <- validate_invoice_document_reference(attrs) do
      {:ok,
       %__MODULE__{
         invoice_document_reference: invoice_doc_ref
       }}
    end
  end

  def new(_), do: {:error, %{billing_reference: "must be a map"}}

  @doc """
  Creates a new BillingReference struct, raising on error.

  ## Examples

      iex> ExCius.BillingReference.new!(%{
      ...>   invoice_document_reference: %{id: "INV-2025-001", issue_date: ~D[2025-01-15]}
      ...> })
      %ExCius.BillingReference{...}
  """
  def new!(attrs) do
    case new(attrs) do
      {:ok, billing_ref} -> billing_ref
      {:error, errors} -> raise ArgumentError, "Invalid BillingReference: #{inspect(errors)}"
    end
  end

  @doc """
  Validates billing reference data without creating a struct.

  Returns `:ok` if valid, or `{:error, errors}` if invalid.

  ## Examples

      iex> ExCius.BillingReference.validate(%{
      ...>   invoice_document_reference: %{id: "INV-001"}
      ...> })
      :ok

      iex> ExCius.BillingReference.validate(%{})
      {:error, %{invoice_document_reference: "is required"}}
  """
  def validate(attrs) when is_map(attrs) do
    case validate_invoice_document_reference(attrs) do
      {:ok, _} -> :ok
      error -> error
    end
  end

  def validate(_), do: {:error, %{billing_reference: "must be a map"}}

  # Private validation functions

  defp validate_invoice_document_reference(%{invoice_document_reference: ref})
       when is_map(ref) do
    with :ok <- validate_document_id(ref),
         {:ok, parsed_date} <- validate_optional_issue_date(ref) do
      {:ok, Map.put(ref, :issue_date, parsed_date)}
    end
  end

  defp validate_invoice_document_reference(%{"invoice_document_reference" => ref})
       when is_map(ref) do
    atomized_ref = atomize_keys(ref)
    validate_invoice_document_reference(%{invoice_document_reference: atomized_ref})
  end

  defp validate_invoice_document_reference(_) do
    {:error, %{invoice_document_reference: "is required"}}
  end

  defp validate_document_id(%{id: id}) when is_binary(id) and byte_size(id) > 0 do
    :ok
  end

  defp validate_document_id(%{id: _}) do
    {:error, %{invoice_document_reference_id: "must be a non-empty string"}}
  end

  defp validate_document_id(_) do
    {:error, %{invoice_document_reference_id: "is required"}}
  end

  defp validate_optional_issue_date(%{issue_date: nil}), do: {:ok, nil}

  defp validate_optional_issue_date(%{issue_date: %Date{} = date}), do: {:ok, date}

  defp validate_optional_issue_date(%{issue_date: date_string}) when is_binary(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> {:ok, date}
      {:error, _} -> {:error, %{invoice_document_reference_issue_date: "must be a valid date"}}
    end
  end

  defp validate_optional_issue_date(%{issue_date: _}) do
    {:error, %{invoice_document_reference_issue_date: "must be a Date or ISO 8601 string"}}
  end

  defp validate_optional_issue_date(_), do: {:ok, nil}

  defp atomize_keys(map) when is_map(map) do
    Map.new(map, fn
      {key, value} when is_binary(key) ->
        {String.to_existing_atom(key), value}

      {key, value} ->
        {key, value}
    end)
  rescue
    ArgumentError -> map
  end

  @doc """
  Converts a BillingReference struct to a map suitable for XML generation.

  ## Examples

      iex> ref = %ExCius.BillingReference{
      ...>   invoice_document_reference: %{id: "INV-001", issue_date: ~D[2025-01-15]}
      ...> }
      iex> ExCius.BillingReference.to_map(ref)
      %{
        invoice_document_reference: %{
          id: "INV-001",
          issue_date: ~D[2025-01-15]
        }
      }
  """
  def to_map(%__MODULE__{} = billing_ref) do
    %{
      invoice_document_reference: billing_ref.invoice_document_reference
    }
  end

  @doc """
  Checks if a billing reference is required for the given invoice type and business process.

  Credit notes (381), corrected invoices (384), and debit notes (383) require billing references.
  Business processes P9 (credit notes) and P10 (corrective invoices) also indicate
  a billing reference is expected.

  ## Examples

      iex> ExCius.BillingReference.required_for_invoice_type?(:credit_note)
      true

      iex> ExCius.BillingReference.required_for_invoice_type?(:corrected_invoice)
      true

      iex> ExCius.BillingReference.required_for_invoice_type?(:commercial_invoice)
      false
  """
  def required_for_invoice_type?(:credit_note), do: true
  def required_for_invoice_type?(:corrected_invoice), do: true
  def required_for_invoice_type?(:debit_note), do: true
  def required_for_invoice_type?("381"), do: true
  def required_for_invoice_type?("383"), do: true
  def required_for_invoice_type?("384"), do: true
  def required_for_invoice_type?(_), do: false

  @doc """
  Checks if a billing reference is required for the given business process.

  ## Examples

      iex> ExCius.BillingReference.required_for_business_process?(:p9)
      true

      iex> ExCius.BillingReference.required_for_business_process?(:p10)
      true

      iex> ExCius.BillingReference.required_for_business_process?(:p1)
      false
  """
  def required_for_business_process?(:p9), do: true
  def required_for_business_process?(:p10), do: true
  def required_for_business_process?("P9"), do: true
  def required_for_business_process?("P10"), do: true
  def required_for_business_process?(_), do: false
end
