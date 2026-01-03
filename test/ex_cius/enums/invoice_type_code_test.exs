defmodule ExCius.Enums.InvoiceTypeCodeTest do
  use ExUnit.Case, async: true

  alias ExCius.Enums.InvoiceTypeCode

  describe "valid?/1" do
    test "returns true for valid atom keys" do
      assert InvoiceTypeCode.valid?(:commercial_invoice)
      assert InvoiceTypeCode.valid?(:credit_note)
      assert InvoiceTypeCode.valid?(:debit_note)
      assert InvoiceTypeCode.valid?(:corrected_invoice)
      assert InvoiceTypeCode.valid?(:prepayment_invoice)
      assert InvoiceTypeCode.valid?(:self_billed_invoice)
      assert InvoiceTypeCode.valid?(:invoice_information)
    end

    test "returns true for valid string codes" do
      assert InvoiceTypeCode.valid?("380")
      assert InvoiceTypeCode.valid?("381")
      assert InvoiceTypeCode.valid?("383")
      assert InvoiceTypeCode.valid?("384")
      assert InvoiceTypeCode.valid?("386")
      assert InvoiceTypeCode.valid?("389")
      assert InvoiceTypeCode.valid?("751")
    end

    test "returns false for invalid values" do
      refute InvoiceTypeCode.valid?(:invalid)
      refute InvoiceTypeCode.valid?("999")
      refute InvoiceTypeCode.valid?(123)
      refute InvoiceTypeCode.valid?(nil)
    end
  end

  describe "code/1" do
    test "returns correct code for atom keys" do
      assert InvoiceTypeCode.code(:commercial_invoice) == "380"
      assert InvoiceTypeCode.code(:credit_note) == "381"
      assert InvoiceTypeCode.code(:debit_note) == "383"
      assert InvoiceTypeCode.code(:corrected_invoice) == "384"
      assert InvoiceTypeCode.code(:prepayment_invoice) == "386"
      assert InvoiceTypeCode.code(:self_billed_invoice) == "389"
      assert InvoiceTypeCode.code(:invoice_information) == "751"
    end

    test "returns code unchanged when passed a code string" do
      assert InvoiceTypeCode.code("380") == "380"
      assert InvoiceTypeCode.code("381") == "381"
      assert InvoiceTypeCode.code("383") == "383"
      assert InvoiceTypeCode.code("384") == "384"
      assert InvoiceTypeCode.code("386") == "386"
    end

    test "returns nil for invalid values" do
      assert InvoiceTypeCode.code(:invalid) == nil
      assert InvoiceTypeCode.code("invalid") == nil
    end
  end

  describe "from_code/1" do
    test "converts code strings to atoms" do
      assert InvoiceTypeCode.from_code("380") == :commercial_invoice
      assert InvoiceTypeCode.from_code("381") == :credit_note
      assert InvoiceTypeCode.from_code("383") == :debit_note
      assert InvoiceTypeCode.from_code("384") == :corrected_invoice
      assert InvoiceTypeCode.from_code("386") == :prepayment_invoice
      assert InvoiceTypeCode.from_code("389") == :self_billed_invoice
      assert InvoiceTypeCode.from_code("751") == :invoice_information
    end

    test "returns nil for invalid codes" do
      assert InvoiceTypeCode.from_code("INVALID") == nil
      assert InvoiceTypeCode.from_code("999") == nil
    end
  end

  describe "description/1" do
    test "returns description for commercial_invoice" do
      assert InvoiceTypeCode.description(:commercial_invoice) == "Commercial Invoice (Standard)"
    end

    test "returns description for credit_note" do
      assert InvoiceTypeCode.description(:credit_note) == "Credit Note (Odobrenje)"
    end

    test "returns description for debit_note" do
      assert InvoiceTypeCode.description(:debit_note) == "Debit Note (Terećenje)"
    end

    test "returns description for corrected_invoice" do
      assert InvoiceTypeCode.description(:corrected_invoice) ==
               "Corrected Invoice (Korektivni račun)"
    end

    test "returns description for prepayment_invoice" do
      assert InvoiceTypeCode.description(:prepayment_invoice) ==
               "Prepayment Invoice (Račun za predujam)"
    end

    test "returns nil for invalid key" do
      assert InvoiceTypeCode.description(:invalid) == nil
    end
  end

  describe "values/0" do
    test "returns all valid atom keys" do
      values = InvoiceTypeCode.values()

      assert :commercial_invoice in values
      assert :credit_note in values
      assert :debit_note in values
      assert :corrected_invoice in values
      assert :prepayment_invoice in values
      assert :self_billed_invoice in values
      assert :invoice_information in values
    end
  end

  describe "default/0" do
    test "returns :commercial_invoice as default" do
      assert InvoiceTypeCode.default() == :commercial_invoice
    end
  end

  describe "accessor functions" do
    test "commercial_invoice/0 returns :commercial_invoice" do
      assert InvoiceTypeCode.commercial_invoice() == :commercial_invoice
    end

    test "credit_note/0 returns :credit_note" do
      assert InvoiceTypeCode.credit_note() == :credit_note
    end

    test "debit_note/0 returns :debit_note" do
      assert InvoiceTypeCode.debit_note() == :debit_note
    end

    test "corrected_invoice/0 returns :corrected_invoice" do
      assert InvoiceTypeCode.corrected_invoice() == :corrected_invoice
    end

    test "prepayment_invoice/0 returns :prepayment_invoice" do
      assert InvoiceTypeCode.prepayment_invoice() == :prepayment_invoice
    end
  end

  describe "credit_type?/1" do
    test "returns true for credit_note" do
      assert InvoiceTypeCode.credit_type?(:credit_note)
      assert InvoiceTypeCode.credit_type?("381")
    end

    test "returns true for corrected_invoice" do
      assert InvoiceTypeCode.credit_type?(:corrected_invoice)
      assert InvoiceTypeCode.credit_type?("384")
    end

    test "returns false for commercial_invoice" do
      refute InvoiceTypeCode.credit_type?(:commercial_invoice)
      refute InvoiceTypeCode.credit_type?("380")
    end

    test "returns false for debit_note" do
      refute InvoiceTypeCode.credit_type?(:debit_note)
      refute InvoiceTypeCode.credit_type?("383")
    end

    test "returns false for prepayment_invoice" do
      refute InvoiceTypeCode.credit_type?(:prepayment_invoice)
      refute InvoiceTypeCode.credit_type?("386")
    end
  end

  describe "requires_billing_reference?/1" do
    test "returns true for credit_note" do
      assert InvoiceTypeCode.requires_billing_reference?(:credit_note)
      assert InvoiceTypeCode.requires_billing_reference?("381")
    end

    test "returns true for corrected_invoice" do
      assert InvoiceTypeCode.requires_billing_reference?(:corrected_invoice)
      assert InvoiceTypeCode.requires_billing_reference?("384")
    end

    test "returns true for debit_note" do
      assert InvoiceTypeCode.requires_billing_reference?(:debit_note)
      assert InvoiceTypeCode.requires_billing_reference?("383")
    end

    test "returns false for commercial_invoice" do
      refute InvoiceTypeCode.requires_billing_reference?(:commercial_invoice)
      refute InvoiceTypeCode.requires_billing_reference?("380")
    end

    test "returns false for prepayment_invoice" do
      refute InvoiceTypeCode.requires_billing_reference?(:prepayment_invoice)
      refute InvoiceTypeCode.requires_billing_reference?("386")
    end

    test "returns false for self_billed_invoice" do
      refute InvoiceTypeCode.requires_billing_reference?(:self_billed_invoice)
    end
  end
end
