defmodule ExCius.RequestParamsTest do
  use ExUnit.Case, async: true

  alias ExCius.RequestParams

  doctest ExCius.RequestParams

  defp valid_params do
    %{
      id: "INV-001",
      issue_datetime: "2025-05-01T12:00:00",
      operator_name: "Operator1",
      currency_code: "EUR",
      supplier: %{
        oib: "12345678901",
        registration_name: "Company A d.o.o.",
        postal_address: %{
          street_name: "Street 1",
          city_name: "Zagreb",
          postal_zone: "10000",
          country_code: "HR"
        },
        party_tax_scheme: %{
          company_id: "HR12345678901",
          tax_scheme_id: "vat"
        }
      },
      customer: %{
        oib: "11111111119",
        registration_name: "Company B d.o.o.",
        postal_address: %{
          street_name: "Street 2",
          city_name: "Rijeka",
          postal_zone: "51000",
          country_code: "HR"
        },
        party_tax_scheme: %{
          company_id: "HR11111111119",
          tax_scheme_id: "vat"
        }
      },
      tax_total: %{
        tax_amount: "25.00",
        tax_subtotals: [
          %{
            taxable_amount: "100.00",
            tax_amount: "25.00",
            tax_category: %{
              id: "standard_rate",
              percent: 25,
              tax_scheme_id: "vat"
            }
          }
        ]
      },
      legal_monetary_total: %{
        line_extension_amount: "100.00",
        tax_exclusive_amount: "100.00",
        tax_inclusive_amount: "125.00",
        payable_amount: "125.00"
      },
      invoice_lines: [
        %{
          id: "1",
          quantity: 1.0,
          unit_code: "piece",
          line_extension_amount: "100.00",
          item: %{
            name: "Product",
            classified_tax_category: %{
              id: "standard_rate",
              percent: 25,
              tax_scheme_id: "vat"
            }
          },
          price: %{
            price_amount: "100.00"
          }
        }
      ]
    }
  end

  describe "new/1" do
    test "validates valid params successfully" do
      assert {:ok, params} = RequestParams.new(valid_params())
      assert params.id == "INV-001"
      assert params.issue_date == ~D[2025-05-01]
      assert params.issue_time == ~T[12:00:00]
      assert params.operator_name == "Operator1"
    end

    test "parses ISO 8601 datetime with timezone" do
      params = Map.put(valid_params(), :issue_datetime, "2025-05-01T12:00:00Z")
      assert {:ok, result} = RequestParams.new(params)
      assert result.issue_date == ~D[2025-05-01]
      assert result.issue_time == ~T[12:00:00]
    end

    test "parses ISO 8601 datetime with offset" do
      params = Map.put(valid_params(), :issue_datetime, "2025-05-01T14:00:00+02:00")
      assert {:ok, result} = RequestParams.new(params)
      assert result.issue_date == ~D[2025-05-01]
      assert result.issue_time == ~T[12:00:00]
    end

    test "accepts DateTime struct" do
      {:ok, dt, _} = DateTime.from_iso8601("2025-05-01T12:00:00Z")
      params = Map.put(valid_params(), :issue_datetime, dt)
      assert {:ok, result} = RequestParams.new(params)
      assert result.issue_date == ~D[2025-05-01]
      assert result.issue_time == ~T[12:00:00]
    end

    test "accepts NaiveDateTime struct" do
      {:ok, dt} = NaiveDateTime.from_iso8601("2025-05-01T12:00:00")
      params = Map.put(valid_params(), :issue_datetime, dt)
      assert {:ok, result} = RequestParams.new(params)
      assert result.issue_date == ~D[2025-05-01]
      assert result.issue_time == ~T[12:00:00]
    end

    test "sets default values" do
      assert {:ok, params} = RequestParams.new(valid_params())
      assert params.profile_id == "P1"
      assert params.invoice_type_code == "380"
      assert params.document_currency_code == "EUR"
    end

    test "accepts optional business_process" do
      params = Map.put(valid_params(), :business_process, "billing")
      assert {:ok, result} = RequestParams.new(params)
      assert result.profile_id == "billing"
    end

    test "accepts optional notes as list of strings" do
      params = Map.put(valid_params(), :notes, ["Note 1", "Note 2"])
      assert {:ok, result} = RequestParams.new(params)
      assert result.notes == ["Note 1", "Note 2"]
    end

    test "accepts optional due_date" do
      params = Map.put(valid_params(), :due_date, "2025-05-31")
      assert {:ok, result} = RequestParams.new(params)
      assert result.due_date == "2025-05-31"
    end

    test "accepts optional payment_method" do
      params =
        Map.put(valid_params(), :payment_method, %{
          payment_means_code: "30",
          payee_financial_account_id: "HR1234567890123456789"
        })

      assert {:ok, result} = RequestParams.new(params)
      assert result.payment_method.payment_means_code == "30"
    end

    test "accepts string keys" do
      params =
        valid_params()
        |> Enum.map(fn {k, v} -> {Atom.to_string(k), v} end)
        |> Map.new()

      assert {:ok, _} = RequestParams.new(params)
    end
  end

  describe "new/1 validation errors" do
    test "returns error for missing required fields" do
      assert {:error, errors} = RequestParams.new(%{})
      assert errors.id == "is required"
      assert errors.issue_datetime == "is required"
      assert errors.operator_name == "is required"
      assert errors.currency_code == "is required"
      assert errors.invoice_lines == "is required"
    end

    test "returns error for invalid issue_datetime" do
      params = Map.put(valid_params(), :issue_datetime, "invalid")
      assert {:error, errors} = RequestParams.new(params)

      assert errors.issue_datetime ==
               "must be a valid ISO 8601 datetime (e.g., 2025-05-01T12:00:00)"
    end

    test "returns error for empty operator_name" do
      params = Map.put(valid_params(), :operator_name, "")
      assert {:error, errors} = RequestParams.new(params)
      assert errors.operator_name == "is required"
    end

    test "returns error for invalid currency_code" do
      params = Map.put(valid_params(), :currency_code, "USD")
      assert {:error, errors} = RequestParams.new(params)
      assert errors.currency_code =~ "only"
    end

    test "returns error for invalid invoice_type_code" do
      params = Map.put(valid_params(), :invoice_type_code, "999")
      assert {:error, errors} = RequestParams.new(params)
      assert errors.invoice_type_code =~ "must be one of"
    end

    test "returns error for invalid business_process" do
      params = Map.put(valid_params(), :business_process, "invalid")
      assert {:error, errors} = RequestParams.new(params)
      assert errors.business_process =~ "must be one of"
    end

    test "returns error for invalid notes (not a list)" do
      params = Map.put(valid_params(), :notes, "not a list")
      assert {:error, %{notes: _}} = RequestParams.new(params)
    end

    test "returns error for invalid notes (empty strings)" do
      params = Map.put(valid_params(), :notes, ["valid", ""])
      assert {:error, %{notes: _}} = RequestParams.new(params)
    end
  end

  describe "supplier validation" do
    test "returns error for missing supplier fields" do
      params = Map.put(valid_params(), :supplier, %{})
      assert {:error, %{supplier: errors}} = RequestParams.new(params)
      assert errors.oib == "is required"
      assert errors.registration_name == "is required"
      assert errors.postal_address == "is required"
      assert errors.party_tax_scheme == "is required"
    end

    test "returns error for invalid oib" do
      params = put_in(valid_params(), [:supplier, :oib], "123")
      assert {:error, %{supplier: errors}} = RequestParams.new(params)
      assert errors.oib =~ "11-digit"
    end

    test "returns error for invalid postal_address" do
      params = put_in(valid_params(), [:supplier, :postal_address], %{})
      assert {:error, %{supplier: errors}} = RequestParams.new(params)
      assert errors.postal_address == "is required"
    end

    test "returns error for invalid country_code" do
      params = put_in(valid_params(), [:supplier, :postal_address, :country_code], "HRV")
      assert {:error, %{supplier: errors}} = RequestParams.new(params)
      assert errors.postal_address.country_code =~ "2-letter"
    end

    test "returns error for invalid party_tax_scheme" do
      params = put_in(valid_params(), [:supplier, :party_tax_scheme], %{})
      assert {:error, %{supplier: errors}} = RequestParams.new(params)
      assert errors.party_tax_scheme == "is required"
    end

    test "returns error for invalid tax_scheme_id" do
      params = put_in(valid_params(), [:supplier, :party_tax_scheme, :tax_scheme_id], "invalid")
      assert {:error, %{supplier: errors}} = RequestParams.new(params)
      assert errors.party_tax_scheme.tax_scheme_id =~ "must be one of"
    end
  end

  describe "customer validation" do
    test "returns error for missing customer fields" do
      params = Map.put(valid_params(), :customer, %{})
      assert {:error, %{customer: errors}} = RequestParams.new(params)
      assert errors.oib == "is required"
    end

    test "returns error for invalid oib" do
      params = put_in(valid_params(), [:customer, :oib], "invalid")
      assert {:error, %{customer: errors}} = RequestParams.new(params)
      assert errors.oib =~ "11-digit"
    end
  end

  describe "tax_total validation" do
    test "returns error for missing tax_total fields" do
      params = Map.put(valid_params(), :tax_total, %{})
      assert {:error, %{tax_total: errors}} = RequestParams.new(params)
      assert errors.tax_amount == "is required"
      assert errors.tax_subtotals == "is required"
    end

    test "returns error for empty tax_subtotals" do
      params = put_in(valid_params(), [:tax_total, :tax_subtotals], [])
      assert {:error, %{tax_total: errors}} = RequestParams.new(params)
      assert errors.tax_subtotals == "is required"
    end

    test "returns error for invalid tax_subtotal" do
      params = put_in(valid_params(), [:tax_total, :tax_subtotals], [%{}])
      assert {:error, %{tax_total: errors}} = RequestParams.new(params)
      assert errors.tax_subtotals["subtotal_1"].taxable_amount == "is required"
    end

    test "returns error for invalid tax_category_id" do
      params =
        put_in(
          valid_params(),
          [:tax_total, :tax_subtotals, Access.at(0), :tax_category, :id],
          "invalid"
        )

      assert {:error, %{tax_total: errors}} = RequestParams.new(params)
      assert errors.tax_subtotals["subtotal_1"].tax_category.id =~ "must be one of"
    end
  end

  describe "legal_monetary_total validation" do
    test "returns error for missing fields" do
      params = Map.put(valid_params(), :legal_monetary_total, %{})
      assert {:error, %{legal_monetary_total: errors}} = RequestParams.new(params)
      assert errors.line_extension_amount == "is required"
      assert errors.tax_exclusive_amount == "is required"
      assert errors.tax_inclusive_amount == "is required"
      assert errors.payable_amount == "is required"
    end

    test "returns error for invalid amount" do
      params = put_in(valid_params(), [:legal_monetary_total, :payable_amount], "invalid")
      assert {:error, %{legal_monetary_total: errors}} = RequestParams.new(params)
      assert errors.payable_amount =~ "valid decimal"
    end

    test "returns error for negative amount" do
      params = put_in(valid_params(), [:legal_monetary_total, :payable_amount], "-10.00")
      assert {:error, %{legal_monetary_total: errors}} = RequestParams.new(params)
      assert errors.payable_amount =~ "valid decimal"
    end
  end

  describe "invoice_lines validation" do
    test "returns error for empty invoice_lines" do
      params = Map.put(valid_params(), :invoice_lines, [])
      assert {:error, errors} = RequestParams.new(params)
      assert errors.invoice_lines == "is required"
    end

    test "returns error for missing line fields" do
      params = Map.put(valid_params(), :invoice_lines, [%{}])
      assert {:error, %{invoice_lines: errors}} = RequestParams.new(params)
      assert errors["line_1"].id == "is required"
      assert errors["line_1"].quantity == "is required"
      assert errors["line_1"].unit_code == "is required"
      assert errors["line_1"].line_extension_amount == "is required"
      assert errors["line_1"].item == "is required"
      assert errors["line_1"].price == "is required"
    end

    test "returns error for invalid unit_code" do
      params = put_in(valid_params(), [:invoice_lines, Access.at(0), :unit_code], "invalid")
      assert {:error, %{invoice_lines: errors}} = RequestParams.new(params)
      assert errors["line_1"].unit_code =~ "only"
    end

    test "returns error for invalid quantity" do
      params = put_in(valid_params(), [:invoice_lines, Access.at(0), :quantity], 0)
      assert {:error, %{invoice_lines: errors}} = RequestParams.new(params)
      assert errors["line_1"].quantity =~ "positive"
    end

    test "returns error for missing item fields" do
      params = put_in(valid_params(), [:invoice_lines, Access.at(0), :item], %{})
      assert {:error, %{invoice_lines: errors}} = RequestParams.new(params)
      assert errors["line_1"].item.name == "is required"
      assert errors["line_1"].item.classified_tax_category == "is required"
    end

    test "returns error for missing price fields" do
      params = put_in(valid_params(), [:invoice_lines, Access.at(0), :price], %{})
      assert {:error, %{invoice_lines: errors}} = RequestParams.new(params)
      assert errors["line_1"].price == "is required"
    end
  end

  describe "payment_method validation" do
    test "returns error for missing payment_method fields" do
      params = Map.put(valid_params(), :payment_method, %{})
      assert {:error, %{payment_method: errors}} = RequestParams.new(params)
      assert errors.payment_means_code == "is required"
      assert errors.payee_financial_account_id == "is required"
    end

    test "returns error for invalid payment_means_code" do
      params =
        Map.put(valid_params(), :payment_method, %{
          payment_means_code: "invalid",
          payee_financial_account_id: "HR1234567890123456789"
        })

      assert {:error, %{payment_method: errors}} = RequestParams.new(params)
      assert errors.payment_means_code =~ "numeric"
    end

    test "accepts valid payment_method with optional fields" do
      params =
        Map.put(valid_params(), :payment_method, %{
          payment_means_code: "30",
          payee_financial_account_id: "HR1234567890123456789",
          instruction_note: "Payment note",
          payment_id: "HR00 123456"
        })

      assert {:ok, result} = RequestParams.new(params)
      assert result.payment_method.instruction_note == "Payment note"
      assert result.payment_method.payment_id == "HR00 123456"
    end
  end
end
