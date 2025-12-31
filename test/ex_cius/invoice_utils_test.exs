defmodule ExCius.InvoiceUtilsTest do
  use ExUnit.Case, async: true

  alias ExCius.InvoiceUtils

  # Simple unsigned invoice XML for testing
  @unsigned_xml """
  <?xml version="1.0" encoding="UTF-8"?>
  <Invoice xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2" xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2" xmlns:ext="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2" xmlns:sac="urn:oasis:names:specification:ubl:schema:xsd:SignatureAggregateComponents-2" xmlns:sig="urn:oasis:names:specification:ubl:schema:xsd:CommonSignatureComponents-2">
    <ext:UBLExtensions>
      <ext:UBLExtension>
        <ext:ExtensionContent>
          <sig:UBLDocumentSignatures>
            <sac:SignatureInformation></sac:SignatureInformation>
          </sig:UBLDocumentSignatures>
        </ext:ExtensionContent>
      </ext:UBLExtension>
    </ext:UBLExtensions>
    <cbc:ID>TEST-001</cbc:ID>
    <cbc:IssueDate>2025-05-01</cbc:IssueDate>
  </Invoice>
  """

  # Signed invoice XML with a mock signature for testing
  @signed_xml """
  <?xml version="1.0" encoding="UTF-8"?>
  <Invoice xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2" xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2" xmlns:ext="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2" xmlns:sac="urn:oasis:names:specification:ubl:schema:xsd:SignatureAggregateComponents-2" xmlns:sig="urn:oasis:names:specification:ubl:schema:xsd:CommonSignatureComponents-2" xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
    <ext:UBLExtensions>
      <ext:UBLExtension>
        <ext:ExtensionContent>
          <sig:UBLDocumentSignatures>
            <sac:SignatureInformation>
              <ds:Signature Id="signature-1">
                <ds:SignedInfo>
                  <ds:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
                  <ds:SignatureMethod Algorithm="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"/>
                </ds:SignedInfo>
                <ds:SignatureValue>SGVsbG8gV29ybGQh</ds:SignatureValue>
                <ds:KeyInfo>
                  <ds:X509Data>
                    <ds:X509Certificate>MIIC...</ds:X509Certificate>
                  </ds:X509Data>
                </ds:KeyInfo>
              </ds:Signature>
            </sac:SignatureInformation>
          </sig:UBLDocumentSignatures>
        </ext:ExtensionContent>
      </ext:UBLExtension>
    </ext:UBLExtensions>
    <cbc:ID>TEST-002</cbc:ID>
    <cbc:IssueDate>2025-05-01</cbc:IssueDate>
  </Invoice>
  """

  # Invoice XML with embedded attachment
  @xml_with_embedded_attachment """
  <?xml version="1.0" encoding="UTF-8"?>
  <Invoice xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2" xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2">
    <cbc:ID>TEST-003</cbc:ID>
    <cbc:IssueDate>2025-05-01</cbc:IssueDate>
    <cac:AdditionalDocumentReference>
      <cbc:ID>attachment-1</cbc:ID>
      <cac:Attachment>
        <cbc:EmbeddedDocumentBinaryObject mimeCode="application/pdf" filename="test_document.pdf">SGVsbG8gV29ybGQh</cbc:EmbeddedDocumentBinaryObject>
      </cac:Attachment>
    </cac:AdditionalDocumentReference>
  </Invoice>
  """

  # Invoice XML with multiple attachments
  @xml_with_multiple_attachments """
  <?xml version="1.0" encoding="UTF-8"?>
  <Invoice xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2" xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2">
    <cbc:ID>TEST-004</cbc:ID>
    <cbc:IssueDate>2025-05-01</cbc:IssueDate>
    <cac:AdditionalDocumentReference>
      <cbc:ID>doc-1</cbc:ID>
      <cac:Attachment>
        <cbc:EmbeddedDocumentBinaryObject mimeCode="application/pdf" filename="invoice.pdf">UERGLTEuNA==</cbc:EmbeddedDocumentBinaryObject>
      </cac:Attachment>
    </cac:AdditionalDocumentReference>
    <cac:AdditionalDocumentReference>
      <cbc:ID>doc-2</cbc:ID>
      <cac:Attachment>
        <cbc:EmbeddedDocumentBinaryObject mimeCode="image/png" filename="logo.png">iVBORw0KGgo=</cbc:EmbeddedDocumentBinaryObject>
      </cac:Attachment>
    </cac:AdditionalDocumentReference>
  </Invoice>
  """

  # Invoice XML with external reference
  @xml_with_external_reference """
  <?xml version="1.0" encoding="UTF-8"?>
  <Invoice xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2" xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2">
    <cbc:ID>TEST-005</cbc:ID>
    <cbc:IssueDate>2025-05-01</cbc:IssueDate>
    <cac:AdditionalDocumentReference>
      <cbc:ID>external-doc-1</cbc:ID>
      <cbc:DocumentDescription>External specification document</cbc:DocumentDescription>
      <cac:Attachment>
        <cac:ExternalReference>
          <cbc:URI>https://example.com/spec.pdf</cbc:URI>
        </cac:ExternalReference>
      </cac:Attachment>
    </cac:AdditionalDocumentReference>
  </Invoice>
  """

  # Invoice XML without any attachments
  @xml_without_attachments """
  <?xml version="1.0" encoding="UTF-8"?>
  <Invoice xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2" xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2">
    <cbc:ID>TEST-006</cbc:ID>
    <cbc:IssueDate>2025-05-01</cbc:IssueDate>
    <cac:AccountingSupplierParty>
      <cac:Party>
        <cac:PartyLegalEntity>
          <cbc:RegistrationName>Test Company</cbc:RegistrationName>
        </cac:PartyLegalEntity>
      </cac:Party>
    </cac:AccountingSupplierParty>
  </Invoice>
  """

  # Invoice with mixed embedded and external attachments
  @xml_with_mixed_attachments """
  <?xml version="1.0" encoding="UTF-8"?>
  <Invoice xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2" xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2">
    <cbc:ID>TEST-007</cbc:ID>
    <cbc:IssueDate>2025-05-01</cbc:IssueDate>
    <cac:AdditionalDocumentReference>
      <cbc:ID>embedded-doc</cbc:ID>
      <cac:Attachment>
        <cbc:EmbeddedDocumentBinaryObject mimeCode="text/plain" filename="readme.txt">SGVsbG8gV29ybGQh</cbc:EmbeddedDocumentBinaryObject>
      </cac:Attachment>
    </cac:AdditionalDocumentReference>
    <cac:AdditionalDocumentReference>
      <cbc:ID>external-doc</cbc:ID>
      <cbc:DocumentDescription>Terms and Conditions</cbc:DocumentDescription>
      <cac:Attachment>
        <cac:ExternalReference>
          <cbc:URI>https://example.com/terms.pdf</cbc:URI>
        </cac:ExternalReference>
      </cac:Attachment>
    </cac:AdditionalDocumentReference>
  </Invoice>
  """

  describe "signed?/1" do
    test "returns {:ok, false} for unsigned invoice" do
      assert {:ok, false} = InvoiceUtils.signed?(@unsigned_xml)
    end

    test "returns {:ok, true} for signed invoice" do
      assert {:ok, true} = InvoiceUtils.signed?(@signed_xml)
    end

    test "returns {:ok, false} for invoice without UBLExtensions" do
      assert {:ok, false} = InvoiceUtils.signed?(@xml_without_attachments)
    end

    test "returns {:ok, true} for real signed invoice file" do
      xml = File.read!("priv/examples/signed_with_pdf.xml")
      assert {:ok, true} = InvoiceUtils.signed?(xml)
    end

    test "returns {:ok, false} for real unsigned invoice file" do
      xml = File.read!("priv/examples/example_vat25.xml")
      assert {:ok, false} = InvoiceUtils.signed?(xml)
    end

    test "returns error for invalid XML" do
      assert {:error, message} = InvoiceUtils.signed?("this is not xml")
      assert String.contains?(message, "XML parsing failed")
    end

    test "returns error for malformed XML" do
      malformed_xml = "<?xml version=\"1.0\"?><Invoice><cbc:ID>123</Invoice>"
      assert {:error, message} = InvoiceUtils.signed?(malformed_xml)
      assert String.contains?(message, "XML parsing failed")
    end

    test "returns error for non-string input" do
      assert {:error, "Invalid input: expected XML string"} = InvoiceUtils.signed?(123)
      assert {:error, "Invalid input: expected XML string"} = InvoiceUtils.signed?(%{})
      assert {:error, "Invalid input: expected XML string"} = InvoiceUtils.signed?(nil)
      assert {:error, "Invalid input: expected XML string"} = InvoiceUtils.signed?(~c"list")
    end

    test "returns {:ok, false} for empty SignatureValue" do
      xml_with_empty_sig = """
      <?xml version="1.0" encoding="UTF-8"?>
      <Invoice xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2" xmlns:sig="urn:oasis:names:specification:ubl:schema:xsd:CommonSignatureComponents-2" xmlns:sac="urn:oasis:names:specification:ubl:schema:xsd:SignatureAggregateComponents-2" xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
        <sig:UBLDocumentSignatures>
          <sac:SignatureInformation>
            <ds:Signature>
              <ds:SignatureValue></ds:SignatureValue>
            </ds:Signature>
          </sac:SignatureInformation>
        </sig:UBLDocumentSignatures>
      </Invoice>
      """

      assert {:ok, false} = InvoiceUtils.signed?(xml_with_empty_sig)
    end
  end

  describe "signed!/1" do
    test "returns false for unsigned invoice" do
      assert false == InvoiceUtils.signed!(@unsigned_xml)
    end

    test "returns true for signed invoice" do
      assert true == InvoiceUtils.signed!(@signed_xml)
    end

    test "returns true for real signed invoice file" do
      xml = File.read!("priv/examples/signed_with_pdf.xml")
      assert true == InvoiceUtils.signed!(xml)
    end

    test "returns false for real unsigned invoice file" do
      xml = File.read!("priv/examples/example_vat25.xml")
      assert false == InvoiceUtils.signed!(xml)
    end

    test "raises error for invalid XML" do
      assert_raise RuntimeError, ~r/XML parsing failed/, fn ->
        InvoiceUtils.signed!("this is not xml")
      end
    end

    test "raises error for non-string input" do
      assert_raise FunctionClauseError, fn ->
        InvoiceUtils.signed!(123)
      end
    end
  end

  describe "extract_attachments/1" do
    test "extracts embedded attachment with all metadata" do
      assert {:ok, attachments} = InvoiceUtils.extract_attachments(@xml_with_embedded_attachment)
      assert length(attachments) == 1

      [attachment] = attachments
      assert attachment.id == "attachment-1"
      assert attachment.type == :embedded
      assert attachment.filename == "test_document.pdf"
      assert attachment.mime_type == "application/pdf"
      assert attachment.content == "Hello World!"
    end

    test "extracts multiple attachments" do
      assert {:ok, attachments} = InvoiceUtils.extract_attachments(@xml_with_multiple_attachments)
      assert length(attachments) == 2

      [first, second] = attachments
      assert first.id == "doc-1"
      assert first.filename == "invoice.pdf"
      assert first.mime_type == "application/pdf"
      assert first.type == :embedded

      assert second.id == "doc-2"
      assert second.filename == "logo.png"
      assert second.mime_type == "image/png"
      assert second.type == :embedded
    end

    test "extracts external reference" do
      assert {:ok, attachments} = InvoiceUtils.extract_attachments(@xml_with_external_reference)
      assert length(attachments) == 1

      [attachment] = attachments
      assert attachment.id == "external-doc-1"
      assert attachment.type == :external
      assert attachment.uri == "https://example.com/spec.pdf"
      assert attachment.description == "External specification document"
    end

    test "extracts mixed embedded and external attachments" do
      assert {:ok, attachments} = InvoiceUtils.extract_attachments(@xml_with_mixed_attachments)
      assert length(attachments) == 2

      embedded = Enum.find(attachments, &(&1.type == :embedded))
      external = Enum.find(attachments, &(&1.type == :external))

      assert embedded.id == "embedded-doc"
      assert embedded.filename == "readme.txt"
      assert embedded.content == "Hello World!"

      assert external.id == "external-doc"
      assert external.uri == "https://example.com/terms.pdf"
      assert external.description == "Terms and Conditions"
    end

    test "returns empty list for invoice without attachments" do
      assert {:ok, []} = InvoiceUtils.extract_attachments(@xml_without_attachments)
    end

    test "returns empty list for unsigned XML without attachments" do
      assert {:ok, []} = InvoiceUtils.extract_attachments(@unsigned_xml)
    end

    test "extracts attachment from real signed invoice file" do
      xml = File.read!("priv/examples/signed_with_pdf.xml")
      assert {:ok, attachments} = InvoiceUtils.extract_attachments(xml)
      assert length(attachments) == 1

      [attachment] = attachments
      assert attachment.type == :embedded
      assert attachment.filename == "vizualizacija_63-1-1.pdf"
      assert attachment.mime_type == "application/pdf"
      assert is_binary(attachment.content)
      # The content should be a valid decoded binary
      assert byte_size(attachment.content) > 0
    end

    test "returns error for invalid XML" do
      assert {:error, message} = InvoiceUtils.extract_attachments("this is not xml")
      assert String.contains?(message, "XML parsing failed")
    end

    test "returns error for non-string input" do
      assert {:error, "Invalid input: expected XML string"} =
               InvoiceUtils.extract_attachments(123)

      assert {:error, "Invalid input: expected XML string"} =
               InvoiceUtils.extract_attachments(%{})

      assert {:error, "Invalid input: expected XML string"} =
               InvoiceUtils.extract_attachments(nil)
    end

    test "handles attachment without filename attribute" do
      xml = """
      <?xml version="1.0" encoding="UTF-8"?>
      <Invoice xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2" xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2">
        <cac:AdditionalDocumentReference>
          <cbc:ID>no-filename</cbc:ID>
          <cac:Attachment>
            <cbc:EmbeddedDocumentBinaryObject mimeCode="application/pdf">SGVsbG8=</cbc:EmbeddedDocumentBinaryObject>
          </cac:Attachment>
        </cac:AdditionalDocumentReference>
      </Invoice>
      """

      assert {:ok, attachments} = InvoiceUtils.extract_attachments(xml)
      assert length(attachments) == 1

      [attachment] = attachments
      assert attachment.filename == nil
      assert attachment.mime_type == "application/pdf"
    end

    test "handles attachment without mimeCode attribute" do
      xml = """
      <?xml version="1.0" encoding="UTF-8"?>
      <Invoice xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2" xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2">
        <cac:AdditionalDocumentReference>
          <cbc:ID>no-mimetype</cbc:ID>
          <cac:Attachment>
            <cbc:EmbeddedDocumentBinaryObject filename="file.bin">SGVsbG8=</cbc:EmbeddedDocumentBinaryObject>
          </cac:Attachment>
        </cac:AdditionalDocumentReference>
      </Invoice>
      """

      assert {:ok, attachments} = InvoiceUtils.extract_attachments(xml)
      assert length(attachments) == 1

      [attachment] = attachments
      assert attachment.mime_type == nil
      assert attachment.filename == "file.bin"
    end

    test "handles external reference without description" do
      xml = """
      <?xml version="1.0" encoding="UTF-8"?>
      <Invoice xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2" xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2">
        <cac:AdditionalDocumentReference>
          <cbc:ID>ext-no-desc</cbc:ID>
          <cac:Attachment>
            <cac:ExternalReference>
              <cbc:URI>https://example.com/doc.pdf</cbc:URI>
            </cac:ExternalReference>
          </cac:Attachment>
        </cac:AdditionalDocumentReference>
      </Invoice>
      """

      assert {:ok, attachments} = InvoiceUtils.extract_attachments(xml)
      assert length(attachments) == 1

      [attachment] = attachments
      assert attachment.type == :external
      assert attachment.uri == "https://example.com/doc.pdf"
      assert attachment.description == nil
    end

    test "skips document references without attachment content" do
      xml = """
      <?xml version="1.0" encoding="UTF-8"?>
      <Invoice xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2" xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2">
        <cac:AdditionalDocumentReference>
          <cbc:ID>empty-ref</cbc:ID>
        </cac:AdditionalDocumentReference>
        <cac:AdditionalDocumentReference>
          <cbc:ID>valid-ref</cbc:ID>
          <cac:Attachment>
            <cbc:EmbeddedDocumentBinaryObject mimeCode="text/plain">SGVsbG8=</cbc:EmbeddedDocumentBinaryObject>
          </cac:Attachment>
        </cac:AdditionalDocumentReference>
      </Invoice>
      """

      assert {:ok, attachments} = InvoiceUtils.extract_attachments(xml)
      # Should only contain the valid attachment
      assert length(attachments) == 1
      assert hd(attachments).id == "valid-ref"
    end
  end

  describe "extract_attachments!/1" do
    test "extracts attachment successfully" do
      attachments = InvoiceUtils.extract_attachments!(@xml_with_embedded_attachment)
      assert length(attachments) == 1
      assert hd(attachments).filename == "test_document.pdf"
    end

    test "returns empty list for invoice without attachments" do
      assert [] == InvoiceUtils.extract_attachments!(@xml_without_attachments)
    end

    test "extracts attachment from real signed invoice file" do
      xml = File.read!("priv/examples/signed_with_pdf.xml")
      attachments = InvoiceUtils.extract_attachments!(xml)
      assert length(attachments) == 1
      assert hd(attachments).filename == "vizualizacija_63-1-1.pdf"
    end

    test "raises error for invalid XML" do
      assert_raise RuntimeError, ~r/XML parsing failed/, fn ->
        InvoiceUtils.extract_attachments!("this is not xml")
      end
    end

    test "raises error for non-string input" do
      assert_raise FunctionClauseError, fn ->
        InvoiceUtils.extract_attachments!(123)
      end
    end
  end

  describe "integration with ExCius main module" do
    test "ExCius.signed?/1 delegates to InvoiceUtils.signed?/1" do
      assert {:ok, false} = ExCius.signed?(@unsigned_xml)
      assert {:ok, true} = ExCius.signed?(@signed_xml)
    end

    test "ExCius.signed!/1 delegates to InvoiceUtils.signed!/1" do
      assert false == ExCius.signed!(@unsigned_xml)
      assert true == ExCius.signed!(@signed_xml)
    end

    test "ExCius.extract_attachments/1 delegates to InvoiceUtils.extract_attachments/1" do
      assert {:ok, attachments} = ExCius.extract_attachments(@xml_with_embedded_attachment)
      assert length(attachments) == 1
    end

    test "ExCius.extract_attachments!/1 delegates to InvoiceUtils.extract_attachments!/1" do
      attachments = ExCius.extract_attachments!(@xml_with_embedded_attachment)
      assert length(attachments) == 1
    end

    test "ExCius.signed?/1 returns error for non-string input" do
      assert {:error, "Input must be an XML string"} = ExCius.signed?(123)
    end

    test "ExCius.extract_attachments/1 returns error for non-string input" do
      assert {:error, "Input must be an XML string"} = ExCius.extract_attachments(123)
    end
  end

  describe "edge cases" do
    test "handles XML with different namespace prefixes" do
      xml_with_different_prefix = """
      <?xml version="1.0" encoding="UTF-8"?>
      <ubl:Invoice xmlns:ubl="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2" xmlns:agg="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" xmlns:basic="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2">
        <agg:AdditionalDocumentReference>
          <basic:ID>custom-prefix</basic:ID>
          <agg:Attachment>
            <basic:EmbeddedDocumentBinaryObject mimeCode="text/plain" filename="test.txt">SGVsbG8=</basic:EmbeddedDocumentBinaryObject>
          </agg:Attachment>
        </agg:AdditionalDocumentReference>
      </ubl:Invoice>
      """

      assert {:ok, attachments} = InvoiceUtils.extract_attachments(xml_with_different_prefix)
      assert length(attachments) == 1
    end

    test "handles very large base64 content gracefully" do
      # Generate a reasonably large base64 string (about 10KB when decoded)
      large_content = :crypto.strong_rand_bytes(10_000) |> Base.encode64()

      xml = """
      <?xml version="1.0" encoding="UTF-8"?>
      <Invoice xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2" xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2">
        <cac:AdditionalDocumentReference>
          <cbc:ID>large-file</cbc:ID>
          <cac:Attachment>
            <cbc:EmbeddedDocumentBinaryObject mimeCode="application/octet-stream">#{large_content}</cbc:EmbeddedDocumentBinaryObject>
          </cac:Attachment>
        </cac:AdditionalDocumentReference>
      </Invoice>
      """

      assert {:ok, attachments} = InvoiceUtils.extract_attachments(xml)
      assert length(attachments) == 1

      [attachment] = attachments
      assert byte_size(attachment.content) == 10_000
    end

    test "handles whitespace in base64 content" do
      xml = """
      <?xml version="1.0" encoding="UTF-8"?>
      <Invoice xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2" xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2">
        <cac:AdditionalDocumentReference>
          <cbc:ID>whitespace-test</cbc:ID>
          <cac:Attachment>
            <cbc:EmbeddedDocumentBinaryObject mimeCode="text/plain">
              SGVs
              bG8g
              V29y
              bGQh
            </cbc:EmbeddedDocumentBinaryObject>
          </cac:Attachment>
        </cac:AdditionalDocumentReference>
      </Invoice>
      """

      assert {:ok, attachments} = InvoiceUtils.extract_attachments(xml)
      assert length(attachments) == 1
      assert hd(attachments).content == "Hello World!"
    end
  end
end
