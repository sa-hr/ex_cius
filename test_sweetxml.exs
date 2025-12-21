# Simple test to isolate SweetXML parsing issue
IO.puts("Testing SweetXML parsing...")

xml_content = """
<?xml version="1.0" encoding="UTF-8"?>
<Invoice xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2">
  <cbc:ID>TEST-001</cbc:ID>
</Invoice>
"""

IO.puts("XML to parse:")
IO.puts(xml_content)
IO.puts("")

# Test basic SweetXML parsing
try do
  doc = SweetXml.parse(xml_content, quiet: true)
  IO.puts("✓ SweetXML.parse succeeded")
  IO.inspect(doc, label: "Parsed document")
rescue
  e ->
    IO.puts("✗ SweetXML.parse failed with exception:")
    IO.inspect(e, label: "Exception")
catch
  :exit, reason ->
    IO.puts("✗ SweetXML.parse failed with exit:")
    IO.inspect(reason, label: "Exit reason")
end

IO.puts("")

# Test different XML variations
simple_xml = "<root><child>value</child></root>"
IO.puts("Testing simple XML: #{simple_xml}")

try do
  simple_doc = SweetXml.parse(simple_xml, quiet: true)
  IO.puts("✓ Simple XML parsed successfully")
rescue
  e -> IO.puts("✗ Simple XML failed: #{Exception.message(e)}")
catch
  :exit, reason -> IO.puts("✗ Simple XML failed with exit: #{inspect(reason)}")
end

# Test XML without declaration
xml_no_declaration = """
<Invoice xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2">
  <cbc:ID>TEST-001</cbc:ID>
</Invoice>
"""

IO.puts("")
IO.puts("Testing XML without declaration:")

try do
  doc_no_decl = SweetXml.parse(xml_no_declaration, quiet: true)
  IO.puts("✓ XML without declaration parsed successfully")
rescue
  e -> IO.puts("✗ XML without declaration failed: #{Exception.message(e)}")
catch
  :exit, reason -> IO.puts("✗ XML without declaration failed with exit: #{inspect(reason)}")
end
