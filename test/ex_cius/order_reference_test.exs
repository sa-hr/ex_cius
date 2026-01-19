defmodule ExCius.OrderReferenceTest do
  use ExUnit.Case, async: true

  alias ExCius.OrderReference

  describe "new/1" do
    test "creates order reference with both buyer_reference and sales_order_id" do
      attrs = %{
        buyer_reference: "PO-2025-001",
        sales_order_id: "QUO-2025-100"
      }

      assert {:ok, order_ref} = OrderReference.new(attrs)
      assert order_ref.buyer_reference == "PO-2025-001"
      assert order_ref.sales_order_id == "QUO-2025-100"
    end

    test "creates order reference with only buyer_reference (BT-13)" do
      attrs = %{buyer_reference: "PO-2025-001"}

      assert {:ok, order_ref} = OrderReference.new(attrs)
      assert order_ref.buyer_reference == "PO-2025-001"
      assert order_ref.sales_order_id == nil
    end

    test "creates order reference with only sales_order_id (BT-14)" do
      attrs = %{sales_order_id: "QUO-2025-100"}

      assert {:ok, order_ref} = OrderReference.new(attrs)
      assert order_ref.buyer_reference == nil
      assert order_ref.sales_order_id == "QUO-2025-100"
    end

    test "returns error when neither field is provided" do
      assert {:error, %{order_reference: message}} = OrderReference.new(%{})
      assert message =~ "at least one of buyer_reference"
    end

    test "returns error when both fields are empty strings" do
      attrs = %{buyer_reference: "", sales_order_id: ""}

      assert {:error, %{order_reference: message}} = OrderReference.new(attrs)
      assert message =~ "at least one of buyer_reference"
    end

    test "accepts string keys" do
      attrs = %{
        "buyer_reference" => "PO-2025-001",
        "sales_order_id" => "QUO-2025-100"
      }

      assert {:ok, order_ref} = OrderReference.new(attrs)
      assert order_ref.buyer_reference == "PO-2025-001"
      assert order_ref.sales_order_id == "QUO-2025-100"
    end

    test "returns error when input is not a map" do
      assert {:error, %{order_reference: "must be a map"}} = OrderReference.new("invalid")
    end
  end

  describe "new!/1" do
    test "creates order reference when valid" do
      attrs = %{buyer_reference: "PO-2025-001"}

      order_ref = OrderReference.new!(attrs)
      assert order_ref.buyer_reference == "PO-2025-001"
    end

    test "raises on invalid input" do
      assert_raise ArgumentError, fn ->
        OrderReference.new!(%{})
      end
    end
  end

  describe "validate/1" do
    test "returns :ok for valid order reference with buyer_reference" do
      attrs = %{buyer_reference: "PO-001"}

      assert :ok = OrderReference.validate(attrs)
    end

    test "returns :ok for valid order reference with sales_order_id" do
      attrs = %{sales_order_id: "QUO-001"}

      assert :ok = OrderReference.validate(attrs)
    end

    test "returns :ok for valid order reference with both fields" do
      attrs = %{buyer_reference: "PO-001", sales_order_id: "QUO-001"}

      assert :ok = OrderReference.validate(attrs)
    end

    test "returns error when neither field is provided" do
      assert {:error, _} = OrderReference.validate(%{})
    end

    test "returns error for non-map input" do
      assert {:error, %{order_reference: "must be a map"}} = OrderReference.validate("invalid")
    end
  end

  describe "to_map/1" do
    test "converts struct to map with both fields" do
      order_ref = %OrderReference{
        buyer_reference: "PO-001",
        sales_order_id: "QUO-001"
      }

      result = OrderReference.to_map(order_ref)

      assert result == %{
               buyer_reference: "PO-001",
               sales_order_id: "QUO-001"
             }
    end

    test "excludes nil fields from map" do
      order_ref = %OrderReference{
        buyer_reference: "PO-001",
        sales_order_id: nil
      }

      result = OrderReference.to_map(order_ref)

      assert result == %{buyer_reference: "PO-001"}
    end
  end

  describe "should_generate?/1" do
    test "returns true when buyer_reference is present" do
      assert OrderReference.should_generate?(%{buyer_reference: "PO-001"})
    end

    test "returns true when sales_order_id is present" do
      assert OrderReference.should_generate?(%{sales_order_id: "QUO-001"})
    end

    test "returns true when both are present" do
      assert OrderReference.should_generate?(%{
               buyer_reference: "PO-001",
               sales_order_id: "QUO-001"
             })
    end

    test "returns false for empty map" do
      refute OrderReference.should_generate?(%{})
    end

    test "returns false for nil" do
      refute OrderReference.should_generate?(nil)
    end

    test "returns false when values are empty strings" do
      refute OrderReference.should_generate?(%{buyer_reference: "", sales_order_id: ""})
    end

    test "returns false for non-map input" do
      refute OrderReference.should_generate?("invalid")
    end
  end
end
