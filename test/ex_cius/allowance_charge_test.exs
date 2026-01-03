defmodule ExCius.AllowanceChargeTest do
  use ExUnit.Case, async: true

  alias ExCius.AllowanceCharge

  describe "validate_document_level/1" do
    test "validates a valid document-level charge with tax category" do
      charge = %{
        charge_indicator: true,
        allowance_charge_reason_code: :freight,
        allowance_charge_reason: "Shipping and handling",
        amount: "15.00",
        tax_category: %{
          id: :standard_rate,
          percent: 25,
          tax_scheme_id: :vat
        }
      }

      assert {:ok, validated} = AllowanceCharge.validate_document_level(charge)
      assert validated.charge_indicator == true
      assert validated.amount == "15.00"
      assert validated.tax_category.id == :standard_rate
    end

    test "validates a valid document-level discount with percentage" do
      discount = %{
        charge_indicator: false,
        allowance_charge_reason_code: :discount,
        allowance_charge_reason: "Loyalty discount",
        multiplier_factor_numeric: 10,
        base_amount: "100.00",
        amount: "10.00",
        tax_category: %{
          id: :standard_rate,
          percent: 25,
          tax_scheme_id: :vat
        }
      }

      assert {:ok, validated} = AllowanceCharge.validate_document_level(discount)
      assert validated.charge_indicator == false
      assert validated.multiplier_factor_numeric == 10
      assert validated.base_amount == "100.00"
    end

    test "validates a non-taxable charge (Croatian Povratna naknada)" do
      charge = %{
        charge_indicator: true,
        allowance_charge_reason_code: :deposit_fee,
        allowance_charge_reason: "Povratna naknada",
        amount: "0.50",
        tax_category: %{
          id: :outside_scope,
          percent: 0,
          tax_scheme_id: :vat,
          tax_exemption_reason: "Povratna naknada - izvan područja primjene PDV-a"
        }
      }

      assert {:ok, validated} = AllowanceCharge.validate_document_level(charge)
      assert validated.tax_category.id == :outside_scope
      assert validated.tax_category.tax_exemption_reason =~ "Povratna naknada"
    end

    test "validates exempt tax category with exemption reason" do
      charge = %{
        charge_indicator: true,
        amount: "10.00",
        tax_category: %{
          id: :exempt,
          percent: 0,
          tax_scheme_id: :vat,
          tax_exemption_reason: "Oslobođeno PDV-a"
        }
      }

      assert {:ok, _} = AllowanceCharge.validate_document_level(charge)
    end

    test "fails when charge_indicator is missing" do
      charge = %{
        amount: "15.00",
        tax_category: %{
          id: :standard_rate,
          percent: 25,
          tax_scheme_id: :vat
        }
      }

      assert {:error, errors} = AllowanceCharge.validate_document_level(charge)
      assert "charge_indicator is required" in errors
    end

    test "fails when charge_indicator is not a boolean" do
      charge = %{
        charge_indicator: "true",
        amount: "15.00",
        tax_category: %{
          id: :standard_rate,
          percent: 25,
          tax_scheme_id: :vat
        }
      }

      assert {:error, errors} = AllowanceCharge.validate_document_level(charge)
      assert Enum.any?(errors, &(&1 =~ "charge_indicator must be a boolean"))
    end

    test "fails when amount is missing" do
      charge = %{
        charge_indicator: true,
        tax_category: %{
          id: :standard_rate,
          percent: 25,
          tax_scheme_id: :vat
        }
      }

      assert {:error, errors} = AllowanceCharge.validate_document_level(charge)
      assert "amount is required" in errors
    end

    test "fails when amount is not a valid decimal string" do
      charge = %{
        charge_indicator: true,
        amount: "invalid",
        tax_category: %{
          id: :standard_rate,
          percent: 25,
          tax_scheme_id: :vat
        }
      }

      assert {:error, errors} = AllowanceCharge.validate_document_level(charge)
      assert "amount must be a valid decimal string" in errors
    end

    test "fails when tax_category is missing for document level" do
      charge = %{
        charge_indicator: true,
        amount: "15.00"
      }

      assert {:error, errors} = AllowanceCharge.validate_document_level(charge)
      assert "tax_category is required for document-level allowance/charge" in errors
    end

    test "fails when tax_category.id is invalid" do
      charge = %{
        charge_indicator: true,
        amount: "15.00",
        tax_category: %{
          id: :invalid_category,
          percent: 25,
          tax_scheme_id: :vat
        }
      }

      assert {:error, errors} = AllowanceCharge.validate_document_level(charge)
      assert Enum.any?(errors, &(&1 =~ "tax_category.id"))
    end

    test "fails when tax_category.percent is missing" do
      charge = %{
        charge_indicator: true,
        amount: "15.00",
        tax_category: %{
          id: :standard_rate,
          tax_scheme_id: :vat
        }
      }

      assert {:error, errors} = AllowanceCharge.validate_document_level(charge)
      assert "tax_category.percent is required" in errors
    end

    test "fails when tax_category.tax_scheme_id is missing" do
      charge = %{
        charge_indicator: true,
        amount: "15.00",
        tax_category: %{
          id: :standard_rate,
          percent: 25
        }
      }

      assert {:error, errors} = AllowanceCharge.validate_document_level(charge)
      assert "tax_category.tax_scheme_id is required" in errors
    end

    test "fails with invalid charge reason code" do
      charge = %{
        charge_indicator: true,
        allowance_charge_reason_code: :invalid_code,
        amount: "15.00",
        tax_category: %{
          id: :standard_rate,
          percent: 25,
          tax_scheme_id: :vat
        }
      }

      assert {:error, errors} = AllowanceCharge.validate_document_level(charge)
      assert Enum.any?(errors, &(&1 =~ "not a valid charge reason code"))
    end

    test "fails with invalid allowance reason code" do
      discount = %{
        charge_indicator: false,
        allowance_charge_reason_code: :invalid_code,
        amount: "10.00",
        tax_category: %{
          id: :standard_rate,
          percent: 25,
          tax_scheme_id: :vat
        }
      }

      assert {:error, errors} = AllowanceCharge.validate_document_level(discount)
      assert Enum.any?(errors, &(&1 =~ "not a valid allowance reason code"))
    end

    test "fails when allowance_charge_reason is empty string" do
      charge = %{
        charge_indicator: true,
        allowance_charge_reason: "",
        amount: "15.00",
        tax_category: %{
          id: :standard_rate,
          percent: 25,
          tax_scheme_id: :vat
        }
      }

      assert {:error, errors} = AllowanceCharge.validate_document_level(charge)
      assert "allowance_charge_reason cannot be an empty string" in errors
    end

    test "fails when multiplier_factor_numeric is negative" do
      charge = %{
        charge_indicator: true,
        multiplier_factor_numeric: -5,
        amount: "15.00",
        tax_category: %{
          id: :standard_rate,
          percent: 25,
          tax_scheme_id: :vat
        }
      }

      assert {:error, errors} = AllowanceCharge.validate_document_level(charge)
      assert "multiplier_factor_numeric must be a non-negative number" in errors
    end

    test "fails when base_amount is invalid" do
      charge = %{
        charge_indicator: true,
        base_amount: "not-a-number",
        amount: "15.00",
        tax_category: %{
          id: :standard_rate,
          percent: 25,
          tax_scheme_id: :vat
        }
      }

      assert {:error, errors} = AllowanceCharge.validate_document_level(charge)
      assert "base_amount must be a valid decimal string" in errors
    end

    test "accepts string keys and converts them to atoms" do
      charge = %{
        "charge_indicator" => true,
        "amount" => "15.00",
        "tax_category" => %{
          "id" => :standard_rate,
          "percent" => 25,
          "tax_scheme_id" => :vat
        }
      }

      assert {:ok, validated} = AllowanceCharge.validate_document_level(charge)
      assert validated.charge_indicator == true
    end
  end

  describe "validate_line_level/1" do
    test "validates a valid line-level discount" do
      discount = %{
        charge_indicator: false,
        allowance_charge_reason_code: :discount,
        allowance_charge_reason: "Volume discount",
        multiplier_factor_numeric: 5,
        base_amount: "200.00",
        amount: "10.00"
      }

      assert {:ok, validated} = AllowanceCharge.validate_line_level(discount)
      assert validated.charge_indicator == false
      assert validated.amount == "10.00"
      # tax_category should not be present
      refute Map.has_key?(validated, :tax_category)
    end

    test "validates a valid line-level charge" do
      charge = %{
        charge_indicator: true,
        allowance_charge_reason: "Special handling",
        amount: "5.00"
      }

      assert {:ok, validated} = AllowanceCharge.validate_line_level(charge)
      assert validated.charge_indicator == true
    end

    test "strips tax_category from line-level allowance/charge" do
      discount = %{
        charge_indicator: false,
        amount: "10.00",
        tax_category: %{
          id: :standard_rate,
          percent: 25,
          tax_scheme_id: :vat
        }
      }

      assert {:ok, validated} = AllowanceCharge.validate_line_level(discount)
      refute Map.has_key?(validated, :tax_category)
    end

    test "fails when charge_indicator is missing" do
      discount = %{
        amount: "10.00"
      }

      assert {:error, errors} = AllowanceCharge.validate_line_level(discount)
      assert "charge_indicator is required" in errors
    end

    test "fails when amount is missing" do
      discount = %{
        charge_indicator: false
      }

      assert {:error, errors} = AllowanceCharge.validate_line_level(discount)
      assert "amount is required" in errors
    end
  end

  describe "validate_document_level_list/1" do
    test "validates a list of document-level allowances/charges" do
      list = [
        %{
          charge_indicator: true,
          amount: "15.00",
          tax_category: %{id: :standard_rate, percent: 25, tax_scheme_id: :vat}
        },
        %{
          charge_indicator: false,
          amount: "10.00",
          tax_category: %{id: :standard_rate, percent: 25, tax_scheme_id: :vat}
        }
      ]

      assert {:ok, validated} = AllowanceCharge.validate_document_level_list(list)
      assert length(validated) == 2
    end

    test "returns empty list for nil" do
      assert {:ok, []} = AllowanceCharge.validate_document_level_list(nil)
    end

    test "returns empty list for empty list" do
      assert {:ok, []} = AllowanceCharge.validate_document_level_list([])
    end

    test "fails with indexed errors for invalid items" do
      list = [
        %{
          charge_indicator: true,
          amount: "15.00",
          tax_category: %{id: :standard_rate, percent: 25, tax_scheme_id: :vat}
        },
        %{
          charge_indicator: true,
          # missing amount
          tax_category: %{id: :standard_rate, percent: 25, tax_scheme_id: :vat}
        }
      ]

      assert {:error, errors} = AllowanceCharge.validate_document_level_list(list)
      assert Enum.any?(errors, &(&1 =~ "allowance_charge[2]"))
    end
  end

  describe "validate_line_level_list/1" do
    test "validates a list of line-level allowances/charges" do
      list = [
        %{charge_indicator: false, amount: "5.00"},
        %{charge_indicator: true, amount: "2.00"}
      ]

      assert {:ok, validated} = AllowanceCharge.validate_line_level_list(list)
      assert length(validated) == 2
    end

    test "returns empty list for nil" do
      assert {:ok, []} = AllowanceCharge.validate_line_level_list(nil)
    end

    test "returns empty list for empty list" do
      assert {:ok, []} = AllowanceCharge.validate_line_level_list([])
    end
  end

  describe "charge?/1" do
    test "returns true for charges" do
      assert AllowanceCharge.charge?(%{charge_indicator: true})
    end

    test "returns false for allowances" do
      refute AllowanceCharge.charge?(%{charge_indicator: false})
    end

    test "returns false for invalid input" do
      refute AllowanceCharge.charge?(%{})
      refute AllowanceCharge.charge?(nil)
    end
  end

  describe "allowance?/1" do
    test "returns true for allowances" do
      assert AllowanceCharge.allowance?(%{charge_indicator: false})
    end

    test "returns false for charges" do
      refute AllowanceCharge.allowance?(%{charge_indicator: true})
    end

    test "returns false for invalid input" do
      refute AllowanceCharge.allowance?(%{})
      refute AllowanceCharge.allowance?(nil)
    end
  end
end
