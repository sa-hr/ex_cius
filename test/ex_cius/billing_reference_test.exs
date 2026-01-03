defmodule ExCius.BillingReferenceTest do
  use ExUnit.Case, async: true

  alias ExCius.BillingReference

  describe "new/1" do
    test "creates billing reference with id and issue_date" do
      attrs = %{
        invoice_document_reference: %{
          id: "INV-2025-001",
          issue_date: ~D[2025-01-15]
        }
      }

      assert {:ok, billing_ref} = BillingReference.new(attrs)
      assert billing_ref.invoice_document_reference.id == "INV-2025-001"
      assert billing_ref.invoice_document_reference.issue_date == ~D[2025-01-15]
    end

    test "creates billing reference with id only (issue_date optional)" do
      attrs = %{
        invoice_document_reference: %{
          id: "INV-2025-001"
        }
      }

      assert {:ok, billing_ref} = BillingReference.new(attrs)
      assert billing_ref.invoice_document_reference.id == "INV-2025-001"
      assert billing_ref.invoice_document_reference.issue_date == nil
    end

    test "parses ISO 8601 date string" do
      attrs = %{
        invoice_document_reference: %{
          id: "INV-2025-001",
          issue_date: "2025-01-15"
        }
      }

      assert {:ok, billing_ref} = BillingReference.new(attrs)
      assert billing_ref.invoice_document_reference.issue_date == ~D[2025-01-15]
    end

    test "returns error when invoice_document_reference is missing" do
      assert {:error, %{invoice_document_reference: "is required"}} = BillingReference.new(%{})
    end

    test "returns error when id is missing" do
      attrs = %{
        invoice_document_reference: %{
          issue_date: ~D[2025-01-15]
        }
      }

      assert {:error, %{invoice_document_reference_id: "is required"}} =
               BillingReference.new(attrs)
    end

    test "returns error when id is empty string" do
      attrs = %{
        invoice_document_reference: %{
          id: "",
          issue_date: ~D[2025-01-15]
        }
      }

      assert {:error, %{invoice_document_reference_id: "must be a non-empty string"}} =
               BillingReference.new(attrs)
    end

    test "returns error for invalid date format" do
      attrs = %{
        invoice_document_reference: %{
          id: "INV-001",
          issue_date: "not-a-date"
        }
      }

      assert {:error, %{invoice_document_reference_issue_date: "must be a valid date"}} =
               BillingReference.new(attrs)
    end

    test "accepts string keys" do
      attrs = %{
        "invoice_document_reference" => %{
          "id" => "INV-2025-001",
          "issue_date" => "2025-01-15"
        }
      }

      assert {:ok, billing_ref} = BillingReference.new(attrs)
      assert billing_ref.invoice_document_reference.id == "INV-2025-001"
    end
  end

  describe "new!/1" do
    test "creates billing reference when valid" do
      attrs = %{
        invoice_document_reference: %{
          id: "INV-2025-001",
          issue_date: ~D[2025-01-15]
        }
      }

      billing_ref = BillingReference.new!(attrs)
      assert billing_ref.invoice_document_reference.id == "INV-2025-001"
    end

    test "raises on invalid input" do
      assert_raise ArgumentError, fn ->
        BillingReference.new!(%{})
      end
    end
  end

  describe "validate/1" do
    test "returns :ok for valid billing reference" do
      attrs = %{
        invoice_document_reference: %{
          id: "INV-2025-001"
        }
      }

      assert :ok = BillingReference.validate(attrs)
    end

    test "returns error for invalid billing reference" do
      assert {:error, _} = BillingReference.validate(%{})
    end
  end

  describe "to_map/1" do
    test "converts struct to map" do
      billing_ref = %BillingReference{
        invoice_document_reference: %{
          id: "INV-001",
          issue_date: ~D[2025-01-15]
        }
      }

      result = BillingReference.to_map(billing_ref)

      assert result == %{
               invoice_document_reference: %{
                 id: "INV-001",
                 issue_date: ~D[2025-01-15]
               }
             }
    end
  end

  describe "required_for_invoice_type?/1" do
    test "returns true for credit_note" do
      assert BillingReference.required_for_invoice_type?(:credit_note)
      assert BillingReference.required_for_invoice_type?("381")
    end

    test "returns true for corrected_invoice" do
      assert BillingReference.required_for_invoice_type?(:corrected_invoice)
      assert BillingReference.required_for_invoice_type?("384")
    end

    test "returns true for debit_note" do
      assert BillingReference.required_for_invoice_type?(:debit_note)
      assert BillingReference.required_for_invoice_type?("383")
    end

    test "returns false for commercial_invoice" do
      refute BillingReference.required_for_invoice_type?(:commercial_invoice)
      refute BillingReference.required_for_invoice_type?("380")
    end

    test "returns false for prepayment_invoice" do
      refute BillingReference.required_for_invoice_type?(:prepayment_invoice)
      refute BillingReference.required_for_invoice_type?("386")
    end
  end

  describe "required_for_business_process?/1" do
    test "returns true for p9 (credit notes)" do
      assert BillingReference.required_for_business_process?(:p9)
      assert BillingReference.required_for_business_process?("P9")
    end

    test "returns true for p10 (corrective invoice)" do
      assert BillingReference.required_for_business_process?(:p10)
      assert BillingReference.required_for_business_process?("P10")
    end

    test "returns false for p1 (standard billing)" do
      refute BillingReference.required_for_business_process?(:p1)
      refute BillingReference.required_for_business_process?("P1")
    end
  end
end
