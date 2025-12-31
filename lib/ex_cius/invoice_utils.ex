defmodule ExCius.InvoiceUtils do
  @moduledoc """
  Utility functions for working with UBL 2.1 Invoice XML documents.

  Provides functions to:
  - Extract attachments from invoices
  - Detect if an invoice is digitally signed
  """

  import SweetXml

  @doc """
  Checks if the given UBL Invoice XML is digitally signed.

  Returns `true` if the invoice contains a digital signature, `false` otherwise.

  ## Parameters

  - `xml_content` - UBL Invoice XML document as a string

  ## Returns

  - `{:ok, boolean}` - Whether the invoice is signed
  - `{:error, reason}` - If XML parsing fails

  ## Examples

      iex> xml = File.read!("priv/examples/signed_with_pdf.xml")
      iex> ExCius.InvoiceUtils.signed?(xml)
      {:ok, true}

      iex> xml = File.read!("priv/examples/basic_invoice.xml")
      iex> ExCius.InvoiceUtils.signed?(xml)
      {:ok, false}

  """
  def signed?(xml_content) when is_binary(xml_content) do
    try do
      doc = SweetXml.parse(xml_content, quiet: true)

      # Check for the presence of a Signature element in the UBLExtensions
      # The signature is typically found at:
      # Invoice/ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sig:UBLDocumentSignatures/sac:SignatureInformation/Signature
      signature_value =
        doc
        |> xpath(
          ~x"//*[local-name()='UBLDocumentSignatures']//*[local-name()='Signature']/*[local-name()='SignatureValue']/text()"s
        )

      is_signed = signature_value != "" && signature_value != nil

      {:ok, is_signed}
    rescue
      e -> {:error, "XML parsing failed: #{Exception.message(e)}"}
    catch
      :exit, reason -> {:error, "XML parsing failed: #{inspect(reason)}"}
    end
  end

  def signed?(_), do: {:error, "Invalid input: expected XML string"}

  @doc """
  Checks if the given UBL Invoice XML is digitally signed.

  Returns `true` if the invoice contains a digital signature, `false` otherwise.
  Raises an error if XML parsing fails.

  ## Parameters

  - `xml_content` - UBL Invoice XML document as a string

  ## Returns

  - `boolean` - Whether the invoice is signed

  ## Examples

      iex> xml = File.read!("priv/examples/signed_with_pdf.xml")
      iex> ExCius.InvoiceUtils.signed!(xml)
      true

  """
  def signed!(xml_content) when is_binary(xml_content) do
    case signed?(xml_content) do
      {:ok, result} -> result
      {:error, reason} -> raise reason
    end
  end

  @doc """
  Extracts all attachments from the given UBL Invoice XML.

  Returns a list of attachment maps, each containing:
  - `:id` - The document reference ID
  - `:filename` - The filename of the attachment (if provided)
  - `:mime_type` - The MIME type of the attachment
  - `:content` - The Base64-decoded binary content of the attachment

  ## Parameters

  - `xml_content` - UBL Invoice XML document as a string

  ## Returns

  - `{:ok, list}` - List of attachment maps
  - `{:error, reason}` - If XML parsing fails

  ## Examples

      iex> xml = File.read!("priv/examples/signed_with_pdf.xml")
      iex> {:ok, attachments} = ExCius.InvoiceUtils.extract_attachments(xml)
      iex> length(attachments)
      1
      iex> hd(attachments).filename
      "vizualizacija_63-1-1.pdf"
      iex> hd(attachments).mime_type
      "application/pdf"

  """
  def extract_attachments(xml_content) when is_binary(xml_content) do
    try do
      doc = SweetXml.parse(xml_content, quiet: true)

      attachments =
        doc
        |> xpath(~x"//*[local-name()='AdditionalDocumentReference']"l)
        |> Enum.map(&extract_attachment/1)
        |> Enum.filter(& &1)

      {:ok, attachments}
    rescue
      e -> {:error, "XML parsing failed: #{Exception.message(e)}"}
    catch
      :exit, reason -> {:error, "XML parsing failed: #{inspect(reason)}"}
    end
  end

  def extract_attachments(_), do: {:error, "Invalid input: expected XML string"}

  @doc """
  Extracts all attachments from the given UBL Invoice XML.

  Returns a list of attachment maps.
  Raises an error if XML parsing fails.

  ## Parameters

  - `xml_content` - UBL Invoice XML document as a string

  ## Returns

  - `list` - List of attachment maps

  ## Examples

      iex> xml = File.read!("priv/examples/signed_with_pdf.xml")
      iex> attachments = ExCius.InvoiceUtils.extract_attachments!(xml)
      iex> length(attachments)
      1

  """
  def extract_attachments!(xml_content) when is_binary(xml_content) do
    case extract_attachments(xml_content) do
      {:ok, result} -> result
      {:error, reason} -> raise reason
    end
  end

  # Private helpers

  defp extract_attachment(doc_ref) do
    id = doc_ref |> xpath(~x"./*[local-name()='ID']/text()"s)

    embedded_doc =
      doc_ref
      |> xpath(~x"./*[local-name()='Attachment']/*[local-name()='EmbeddedDocumentBinaryObject']"o)

    case embedded_doc do
      nil ->
        # Check for external reference instead
        external_ref = extract_external_reference(doc_ref)

        if external_ref do
          %{
            id: id,
            type: :external,
            uri: external_ref.uri,
            description: external_ref.description
          }
        else
          nil
        end

      _ ->
        content_base64 = embedded_doc |> xpath(~x"./text()"s)
        filename = embedded_doc |> xpath(~x"./@filename"s)
        mime_type = embedded_doc |> xpath(~x"./@mimeCode"s)

        # Decode the base64 content
        content =
          case Base.decode64(content_base64, ignore: :whitespace) do
            {:ok, decoded} -> decoded
            :error -> nil
          end

        if content do
          %{
            id: id,
            type: :embedded,
            filename: if(filename != "", do: filename, else: nil),
            mime_type: if(mime_type != "", do: mime_type, else: nil),
            content: content
          }
        else
          nil
        end
    end
  end

  defp extract_external_reference(doc_ref) do
    uri =
      doc_ref
      |> xpath(
        ~x"./*[local-name()='Attachment']/*[local-name()='ExternalReference']/*[local-name()='URI']/text()"s
      )

    if uri != "" do
      description =
        doc_ref
        |> xpath(~x"./*[local-name()='DocumentDescription']/text()"s)

      %{
        uri: uri,
        description: if(description != "", do: description, else: nil)
      }
    else
      nil
    end
  end
end
