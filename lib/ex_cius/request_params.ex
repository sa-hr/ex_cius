defmodule ExCius.RequestParams do
  @moduledoc """
  Validates and formats input parameters for UBL 2.1 Invoice generation.

  Ensures all required fields for a UBL 2.1 invoice are present and properly formatted,
  based on the Croatian e-Invoice (CIUS-2025) specification.

  ## Required Fields

  - `:id` - Invoice identifier (string)
  - `:issue_datetime` - Date and time of issue (ISO 8601 string, DateTime, or NaiveDateTime)
  - `:currency_code` - Document currency, only "EUR" supported (string)
  - `:supplier` - Supplier party information (map)
  - `:customer` - Customer party information (map)
  - `:tax_total` - Tax total information (map)
  - `:legal_monetary_total` - Monetary totals (map)
  - `:invoice_lines` - List of invoice lines (list)

  ## Optional Fields

  - `:business_process` - Business process, defaults to "billing" (atom/string)
  - `:invoice_type_code` - Type of invoice, defaults to "commercial_invoice" (atom/string)
  - `:due_date` - Payment due date (Date or ISO 8601 string)
  - `:payment_method` - Payment information (map)
  - `:notes` - List of free-form notes (list of strings)
  - `:attachments` - List of embedded document attachments (list of maps)

  ## Attachment Structure

  Each attachment in the `:attachments` list requires:
  - `:id` - Document reference identifier (string, e.g., "1", "2")
  - `:filename` - Name of the attached file (string, e.g., "invoice.pdf")
  - `:mime_code` - MIME type of the attachment (string, e.g., "application/pdf")
  - `:content` - Base64-encoded content of the file (string)

  ## Supplier Structure

  Supplier requires:
  - `:oib` - Croatian OIB (11-digit string)
  - `:registration_name` - Legal name (string)
  - `:postal_address` - Address map with `:street_name`, `:city_name`, `:postal_zone`, `:country_code`
  - `:party_tax_scheme` - Tax scheme map with `:company_id`, `:tax_scheme_id`
  - `:seller_contact` - Operator information (required for Croatian CIUS compliance):
    - `:id` - Operator's OIB (HR-BT-5)
    - `:name` - Operator's name (HR-BT-4)

  ## Customer Structure

  Customer requires:
  - `:oib` - Croatian OIB (11-digit string)
  - `:registration_name` - Legal name (string)
  - `:postal_address` - Address map with `:street_name`, `:city_name`, `:postal_zone`, `:country_code`
  - `:party_tax_scheme` - Tax scheme map with `:company_id`, `:tax_scheme_id`
  """

  alias ExCius.Enums.{
    BusinessProcess,
    Currency,
    InvoiceTypeCode,
    TaxCategory,
    TaxScheme,
    UnitCode
  }

  @required_fields [
    :id,
    :issue_datetime,
    :currency_code,
    :supplier,
    :customer,
    :tax_total,
    :legal_monetary_total,
    :invoice_lines
  ]

  @required_supplier_fields [
    :oib,
    :registration_name,
    :postal_address,
    :party_tax_scheme,
    :seller_contact
  ]

  @required_seller_contact_fields [
    :id,
    :name
  ]

  @required_customer_fields [
    :oib,
    :registration_name,
    :postal_address,
    :party_tax_scheme
  ]

  @required_address_fields [:street_name, :city_name, :postal_zone, :country_code]

  @required_tax_scheme_fields [:company_id, :tax_scheme_id]

  @required_monetary_fields [
    :line_extension_amount,
    :tax_exclusive_amount,
    :tax_inclusive_amount,
    :payable_amount
  ]

  @required_tax_total_fields [:tax_amount, :tax_subtotals]

  @required_tax_subtotal_fields [:taxable_amount, :tax_amount, :tax_category]

  @required_tax_category_fields [:id, :percent, :tax_scheme_id]

  @required_line_fields [:id, :quantity, :unit_code, :line_extension_amount, :item, :price]

  @required_item_fields [:name, :classified_tax_category, :commodity_classification]

  @required_classified_tax_fields [:id, :percent, :tax_scheme_id]

  @required_price_fields [:price_amount]

  @required_payment_means_fields [:payment_means_code, :payee_financial_account_id]

  @required_attachment_fields [:id, :filename, :mime_code, :content]

  @doc """
  Creates and validates UBL 2.1 invoice parameters from an input map.

  Returns `{:ok, validated_params}` on success or `{:error, errors}` on validation failure.

  ## Examples

      iex> params = %{
      ...>   id: "INV-001",
      ...>   issue_datetime: "2025-05-01T12:00:00",
      ...>   currency_code: "EUR",
      ...>   supplier: %{
      ...>     oib: "12345678901",
      ...>     registration_name: "Supplier d.o.o.",
      ...>     postal_address: %{
      ...>       street_name: "Street 1",
      ...>       city_name: "Zagreb",
      ...>       postal_zone: "10000",
      ...>       country_code: "HR"
      ...>     },
      ...>     party_tax_scheme: %{
      ...>       company_id: "HR12345678901",
      ...>       tax_scheme_id: "vat"
      ...>     },
      ...>     seller_contact: %{
      ...>       id: "12345678901",
      ...>       name: "Operator1"
      ...>     }
      ...>   },
      ...>   customer: %{
      ...>     oib: "11111111119",
      ...>     registration_name: "Customer d.o.o.",
      ...>     postal_address: %{
      ...>       street_name: "Street 2",
      ...>       city_name: "Rijeka",
      ...>       postal_zone: "51000",
      ...>       country_code: "HR"
      ...>     },
      ...>     party_tax_scheme: %{
      ...>       company_id: "HR11111111119",
      ...>       tax_scheme_id: "vat"
      ...>     }
      ...>   },
      ...>   tax_total: %{
      ...>     tax_amount: "25.00",
      ...>     tax_subtotals: [
      ...>       %{
      ...>         taxable_amount: "100.00",
      ...>         tax_amount: "25.00",
      ...>         tax_category: %{id: "standard_rate", percent: 25, tax_scheme_id: "vat"}
      ...>       }
      ...>     ]
      ...>   },
      ...>   legal_monetary_total: %{
      ...>     line_extension_amount: "100.00",
      ...>     tax_exclusive_amount: "100.00",
      ...>     tax_inclusive_amount: "125.00",
      ...>     payable_amount: "125.00"
      ...>   },
      ...>   invoice_lines: [
      ...>     %{
      ...>       id: "1",
      ...>       quantity: 1.0,
      ...>       unit_code: "piece",
      ...>       line_extension_amount: "100.00",
      ...>       item: %{
      ...>         name: "Product",
      ...>         classified_tax_category: %{id: "standard_rate", percent: 25, tax_scheme_id: "vat"},
      ...>         commodity_classification: %{item_classification_code: "73211200", list_id: "CG"}
      ...>       },
      ...>       price: %{price_amount: "100.00"}
      ...>     }
      ...>   ]
      ...> }
      iex> {:ok, result} = ExCius.RequestParams.new(params)
      iex> result.id
      "INV-001"
      iex> result.issue_date
      ~D[2025-05-01]
      iex> result.issue_time
      ~T[12:00:00]

      iex> {:error, errors} = ExCius.RequestParams.new(%{})
      iex> errors.id
      "is required"

  """
  def new(params) when is_map(params) do
    params
    |> atomize_keys()
    |> set_defaults()
    |> validate()
  end

  @doc """
  Validates UBL 2.1 invoice parameters.

  This function is called automatically by `new/1` but can be used separately
  if you want to validate params that have already been atomized and have defaults set.
  """
  def validate(params) do
    with {:ok, _} <- validate_required_fields(params),
         {:ok, _} <- validate_formats(params),
         {:ok, _} <- validate_supplier(params.supplier),
         {:ok, _} <- validate_customer(params.customer),
         {:ok, _} <- validate_tax_total(params.tax_total, params.currency_code),
         {:ok, _} <- validate_monetary_total(params.legal_monetary_total),
         {:ok, _} <- validate_payment_method(params[:payment_method]),
         {:ok, _} <- validate_invoice_lines(params.invoice_lines, params.currency_code),
         {:ok, _} <- validate_notes(params[:notes]),
         {:ok, _} <- validate_attachments(params[:attachments]) do
      {:ok, params}
    end
  end

  defp atomize_keys(params) do
    params
    |> Enum.map(fn
      {key, value} when is_binary(key) -> {String.to_atom(key), value}
      {key, value} -> {key, value}
    end)
    |> Map.new()
    |> atomize_nested_maps()
  end

  defp atomize_nested_maps(params) do
    params
    |> Map.update(:supplier, %{}, &atomize_party/1)
    |> Map.update(:customer, %{}, &atomize_party/1)
    |> Map.update(:tax_total, %{}, &atomize_tax_total/1)
    |> Map.update(:legal_monetary_total, %{}, &atomize_map/1)
    |> Map.update(:payment_method, nil, &atomize_payment_method/1)
    |> Map.update(:invoice_lines, [], &atomize_invoice_lines/1)
    |> Map.update(:attachments, nil, &atomize_attachments/1)
  end

  defp atomize_map(nil), do: nil

  defp atomize_map(map) when is_map(map) do
    map
    |> Enum.map(fn
      {key, value} when is_binary(key) -> {String.to_atom(key), value}
      {key, value} -> {key, value}
    end)
    |> Map.new()
  end

  defp atomize_map(value), do: value

  defp atomize_party(party) when is_map(party) do
    party
    |> atomize_map()
    |> Map.update(:postal_address, %{}, &atomize_map/1)
    |> Map.update(:party_tax_scheme, %{}, &atomize_map/1)
    |> Map.update(:contact, nil, &atomize_map/1)
    |> Map.update(:seller_contact, nil, &atomize_map/1)
    |> Map.update(:party_identification, nil, &atomize_map/1)
  end

  defp atomize_party(value), do: value

  defp atomize_tax_total(tax_total) when is_map(tax_total) do
    tax_total
    |> atomize_map()
    |> Map.update(:tax_subtotals, [], fn subtotals ->
      Enum.map(subtotals || [], fn subtotal ->
        subtotal
        |> atomize_map()
        |> Map.update(:tax_category, %{}, &atomize_map/1)
      end)
    end)
  end

  defp atomize_tax_total(value), do: value

  defp atomize_payment_method(nil), do: nil

  defp atomize_payment_method(payment_method) when is_map(payment_method) do
    atomize_map(payment_method)
  end

  defp atomize_payment_method(value), do: value

  defp atomize_invoice_lines(lines) when is_list(lines) do
    Enum.map(lines, fn line ->
      line
      |> atomize_map()
      |> Map.update(:item, %{}, &atomize_item/1)
      |> Map.update(:price, %{}, &atomize_map/1)
    end)
  end

  defp atomize_invoice_lines(value), do: value

  defp atomize_item(item) when is_map(item) do
    item
    |> atomize_map()
    |> Map.update(:classified_tax_category, %{}, &atomize_map/1)
    |> Map.update(:commodity_classification, nil, &atomize_map/1)
  end

  defp atomize_item(value), do: value

  defp set_defaults(params) do
    defaults = %{
      profile_id: params[:business_process] || BusinessProcess.code(BusinessProcess.default()),
      invoice_type_code:
        params[:invoice_type_code] || InvoiceTypeCode.code(InvoiceTypeCode.default()),
      document_currency_code: params[:currency_code] || Currency.code(Currency.default())
    }

    defaults
    |> Map.merge(params)
    |> parse_issue_datetime()
  end

  defp parse_issue_datetime(%{issue_datetime: %DateTime{} = dt} = params) do
    params
    |> Map.put(:issue_date, DateTime.to_date(dt))
    |> Map.put(:issue_time, DateTime.to_time(dt))
  end

  defp parse_issue_datetime(%{issue_datetime: %NaiveDateTime{} = dt} = params) do
    params
    |> Map.put(:issue_date, NaiveDateTime.to_date(dt))
    |> Map.put(:issue_time, NaiveDateTime.to_time(dt))
  end

  defp parse_issue_datetime(%{issue_datetime: value} = params) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, dt, _offset} ->
        params
        |> Map.put(:issue_date, DateTime.to_date(dt))
        |> Map.put(:issue_time, DateTime.to_time(dt))

      {:error, _} ->
        case NaiveDateTime.from_iso8601(value) do
          {:ok, dt} ->
            params
            |> Map.put(:issue_date, NaiveDateTime.to_date(dt))
            |> Map.put(:issue_time, NaiveDateTime.to_time(dt))

          {:error, _} ->
            params
        end
    end
  end

  defp parse_issue_datetime(params), do: params

  defp validate_required_fields(params) do
    missing_fields =
      Enum.filter(@required_fields, fn field ->
        value = params[field]
        is_nil(value) || value == "" || (is_list(value) && Enum.empty?(value))
      end)

    case missing_fields do
      [] -> {:ok, params}
      fields -> {:error, missing_field_errors(fields)}
    end
  end

  defp validate_formats(params) do
    errors =
      %{}
      |> add_error(:id, validate_id(params.id))
      |> add_error(:issue_datetime, validate_issue_datetime(params))
      |> add_error(:due_date, validate_optional_date(params[:due_date]))
      |> add_error(:currency_code, validate_currency_code(params.currency_code))
      |> add_error(:invoice_type_code, validate_invoice_type_code(params[:invoice_type_code]))
      |> add_error(
        :business_process,
        validate_optional_business_process(params[:business_process])
      )

    case Enum.empty?(errors) do
      true -> {:ok, params}
      false -> {:error, errors}
    end
  end

  defp validate_id(value) when is_binary(value) and byte_size(value) > 0, do: :ok
  defp validate_id(_), do: {:error, "must be a non-empty string"}

  defp validate_date(%Date{} = _date), do: :ok

  defp validate_date(value) when is_binary(value) do
    case Date.from_iso8601(value) do
      {:ok, _date} -> :ok
      {:error, _} -> {:error, "must be a valid date (YYYY-MM-DD or Date struct)"}
    end
  end

  defp validate_date(_), do: {:error, "must be a valid date (YYYY-MM-DD or Date struct)"}

  defp validate_optional_date(nil), do: :ok
  defp validate_optional_date(value), do: validate_date(value)

  defp validate_issue_datetime(%{issue_date: %Date{}, issue_time: %Time{}}), do: :ok

  defp validate_issue_datetime(_),
    do: {:error, "must be a valid ISO 8601 datetime (e.g., 2025-05-01T12:00:00)"}

  defp validate_currency_code(value) when is_binary(value) do
    if Currency.valid?(value) do
      :ok
    else
      {:error,
       "only #{Enum.join(Enum.map(Currency.values(), &Currency.code/1), ", ")} is supported"}
    end
  end

  defp validate_currency_code(_),
    do: {:error, "must be #{Currency.code(Currency.default())}"}

  defp validate_optional_business_process(nil), do: :ok

  defp validate_optional_business_process(value) when is_binary(value) do
    if BusinessProcess.valid?(value) do
      :ok
    else
      {:error,
       "must be one of: #{Enum.join(Enum.map(BusinessProcess.values(), &BusinessProcess.code/1), ", ")}"}
    end
  end

  defp validate_optional_business_process(_), do: {:error, "must be a non-empty string"}

  defp validate_invoice_type_code(nil), do: :ok

  defp validate_invoice_type_code(value) when is_binary(value) do
    if InvoiceTypeCode.valid?(value) do
      :ok
    else
      {:error,
       "must be one of: #{Enum.join(Enum.map(InvoiceTypeCode.values(), &InvoiceTypeCode.code/1), ", ")}"}
    end
  end

  defp validate_invoice_type_code(_), do: {:error, "must be a valid invoice type code string"}

  defp validate_supplier(supplier) when is_map(supplier) do
    missing_fields =
      Enum.filter(@required_supplier_fields, fn field ->
        value = supplier[field]
        is_nil(value) || value == "" || (is_map(value) && map_size(value) == 0)
      end)

    case missing_fields do
      [] ->
        errors =
          %{}
          |> add_error(:oib, validate_oib(supplier.oib))
          |> add_error(:registration_name, validate_registration_name(supplier.registration_name))
          |> add_error(:postal_address, validate_postal_address(supplier.postal_address))
          |> add_error(:party_tax_scheme, validate_party_tax_scheme(supplier.party_tax_scheme))
          |> add_error(
            :party_identification,
            validate_optional_party_identification(supplier[:party_identification])
          )
          |> add_error(:contact, validate_optional_contact(supplier[:contact]))
          |> add_error(
            :seller_contact,
            validate_required_seller_contact(supplier.seller_contact)
          )

        if Enum.empty?(errors) do
          {:ok, supplier}
        else
          {:error, %{supplier: errors}}
        end

      fields ->
        {:error, %{supplier: missing_field_errors(fields)}}
    end
  end

  defp validate_supplier(_), do: {:error, %{supplier: "must be a map"}}

  defp validate_customer(customer) when is_map(customer) do
    missing_fields =
      Enum.filter(@required_customer_fields, fn field ->
        value = customer[field]
        is_nil(value) || value == "" || (is_map(value) && map_size(value) == 0)
      end)

    case missing_fields do
      [] ->
        errors =
          %{}
          |> add_error(:oib, validate_oib(customer.oib))
          |> add_error(:registration_name, validate_registration_name(customer.registration_name))
          |> add_error(:postal_address, validate_postal_address(customer.postal_address))
          |> add_error(:party_tax_scheme, validate_party_tax_scheme(customer.party_tax_scheme))

        if Enum.empty?(errors) do
          {:ok, customer}
        else
          {:error, %{customer: errors}}
        end

      fields ->
        {:error, %{customer: missing_field_errors(fields)}}
    end
  end

  defp validate_customer(_), do: {:error, %{customer: "must be a map"}}

  defp validate_oib(value) when is_binary(value) do
    if String.match?(value, ~r/^\d{11}$/) do
      :ok
    else
      {:error, "must be an 11-digit OIB number"}
    end
  end

  defp validate_oib(_), do: {:error, "must be an 11-digit OIB number"}

  defp validate_registration_name(value) when is_binary(value) and byte_size(value) > 0, do: :ok
  defp validate_registration_name(_), do: {:error, "must be a non-empty string"}

  defp validate_postal_address(address) when is_map(address) do
    missing_fields =
      Enum.filter(@required_address_fields, fn field ->
        value = address[field]
        is_nil(value) || value == ""
      end)

    case missing_fields do
      [] ->
        errors =
          %{}
          |> add_error(:street_name, validate_non_empty_string_required(address.street_name))
          |> add_error(:city_name, validate_non_empty_string_required(address.city_name))
          |> add_error(:postal_zone, validate_postal_zone(address.postal_zone))
          |> add_error(:country_code, validate_country_code(address.country_code))

        if Enum.empty?(errors), do: :ok, else: {:error, errors}

      fields ->
        {:error, missing_field_errors(fields)}
    end
  end

  defp validate_postal_address(_), do: {:error, "must be a map"}

  defp validate_non_empty_string_required(value) when is_binary(value) and byte_size(value) > 0,
    do: :ok

  defp validate_non_empty_string_required(_), do: {:error, "must be a non-empty string"}

  defp validate_postal_zone(value) when is_binary(value) and byte_size(value) > 0, do: :ok
  defp validate_postal_zone(_), do: {:error, "must be a non-empty string"}

  defp validate_country_code(value) when is_binary(value) do
    if String.match?(value, ~r/^[A-Z]{2}$/),
      do: :ok,
      else: {:error, "must be a 2-letter ISO 3166-1 alpha-2 country code"}
  end

  defp validate_country_code(_),
    do: {:error, "must be a 2-letter ISO 3166-1 alpha-2 country code"}

  defp validate_party_tax_scheme(tax_scheme) when is_map(tax_scheme) do
    missing_fields =
      Enum.filter(@required_tax_scheme_fields, fn field ->
        value = tax_scheme[field]
        is_nil(value) || value == ""
      end)

    case missing_fields do
      [] ->
        errors =
          %{}
          |> add_error(:company_id, validate_company_id(tax_scheme.company_id))
          |> add_error(:tax_scheme_id, validate_tax_scheme_id(tax_scheme.tax_scheme_id))

        if Enum.empty?(errors), do: :ok, else: {:error, errors}

      fields ->
        {:error, missing_field_errors(fields)}
    end
  end

  defp validate_party_tax_scheme(_), do: {:error, "must be a map"}

  defp validate_company_id(value) when is_binary(value) and byte_size(value) > 0, do: :ok
  defp validate_company_id(_), do: {:error, "must be a non-empty string (e.g., HR12345678901)"}

  defp validate_tax_scheme_id(value) when is_binary(value) do
    if TaxScheme.valid?(value) do
      :ok
    else
      {:error,
       "must be one of: #{Enum.join(Enum.map(TaxScheme.values(), &TaxScheme.code/1), ", ")}"}
    end
  end

  defp validate_tax_scheme_id(_), do: {:error, "must be a valid tax scheme ID string"}

  defp validate_optional_party_identification(nil), do: :ok

  defp validate_optional_party_identification(party_id) when is_map(party_id) do
    if party_id[:id] && is_binary(party_id[:id]) && byte_size(party_id[:id]) > 0 do
      :ok
    else
      {:error, %{id: "must be a non-empty string"}}
    end
  end

  defp validate_optional_party_identification(_), do: {:error, "must be a map with :id field"}

  defp validate_optional_contact(nil), do: :ok

  defp validate_optional_contact(contact) when is_map(contact) do
    errors =
      %{}
      |> add_error(:name, validate_optional_non_empty_string(contact[:name]))
      |> add_error(:electronic_mail, validate_optional_email(contact[:electronic_mail]))
      |> add_error(:telephone, validate_optional_non_empty_string(contact[:telephone]))

    if Enum.empty?(errors), do: :ok, else: {:error, errors}
  end

  defp validate_optional_contact(_), do: {:error, "must be a map"}

  defp validate_required_seller_contact(seller_contact) when is_map(seller_contact) do
    missing_fields =
      Enum.filter(@required_seller_contact_fields, fn field ->
        value = seller_contact[field]
        is_nil(value) || value == ""
      end)

    case missing_fields do
      [] ->
        errors =
          %{}
          |> add_error(:id, validate_oib(seller_contact.id))
          |> add_error(:name, validate_non_empty_string_required(seller_contact.name))

        if Enum.empty?(errors), do: :ok, else: {:error, errors}

      fields ->
        {:error, missing_field_errors(fields)}
    end
  end

  defp validate_required_seller_contact(_),
    do: {:error, "must be a map with id (operator OIB) and name (operator name)"}

  defp validate_optional_non_empty_string(nil), do: :ok

  defp validate_optional_non_empty_string(value) when is_binary(value) and byte_size(value) > 0,
    do: :ok

  defp validate_optional_non_empty_string(""),
    do: {:error, "must be a non-empty string if provided"}

  defp validate_optional_non_empty_string(_), do: {:error, "must be a string"}

  defp validate_optional_email(nil), do: :ok

  defp validate_optional_email(value) when is_binary(value) do
    if String.match?(value, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/),
      do: :ok,
      else: {:error, "must be a valid email address"}
  end

  defp validate_optional_email(_), do: {:error, "must be a string"}

  defp validate_tax_total(tax_total, currency_code) when is_map(tax_total) do
    missing_fields =
      Enum.filter(@required_tax_total_fields, fn field ->
        value = tax_total[field]
        is_nil(value) || value == "" || (is_list(value) && Enum.empty?(value))
      end)

    case missing_fields do
      [] ->
        errors =
          %{}
          |> add_error(:tax_amount, validate_amount(tax_total.tax_amount))
          |> add_error(
            :tax_subtotals,
            validate_tax_subtotals(tax_total.tax_subtotals, currency_code)
          )

        if Enum.empty?(errors) do
          {:ok, tax_total}
        else
          {:error, %{tax_total: errors}}
        end

      fields ->
        {:error, %{tax_total: missing_field_errors(fields)}}
    end
  end

  defp validate_tax_total(_, _), do: {:error, %{tax_total: "must be a map"}}

  defp validate_tax_subtotals(subtotals, _currency_code)
       when is_list(subtotals) and length(subtotals) > 0 do
    errors =
      subtotals
      |> Enum.with_index()
      |> Enum.reduce(%{}, fn {subtotal, index}, acc ->
        case validate_tax_subtotal(subtotal) do
          :ok -> acc
          {:error, subtotal_errors} -> Map.put(acc, "subtotal_#{index + 1}", subtotal_errors)
        end
      end)

    case Enum.empty?(errors) do
      true -> :ok
      false -> {:error, errors}
    end
  end

  defp validate_tax_subtotals(_, _), do: {:error, "must be a non-empty list"}

  defp validate_tax_subtotal(subtotal) when is_map(subtotal) do
    missing_fields =
      Enum.filter(@required_tax_subtotal_fields, fn field ->
        value = subtotal[field]
        is_nil(value) || value == "" || (is_map(value) && map_size(value) == 0)
      end)

    case missing_fields do
      [] ->
        errors =
          %{}
          |> add_error(:taxable_amount, validate_amount(subtotal.taxable_amount))
          |> add_error(:tax_amount, validate_amount(subtotal.tax_amount))
          |> add_error(:tax_category, validate_tax_category(subtotal.tax_category))

        if Enum.empty?(errors), do: :ok, else: {:error, errors}

      fields ->
        {:error, missing_field_errors(fields)}
    end
  end

  defp validate_tax_subtotal(_), do: {:error, "must be a map"}

  defp validate_tax_category(tax_category) when is_map(tax_category) do
    missing_fields =
      Enum.filter(@required_tax_category_fields, fn field ->
        value = tax_category[field]
        is_nil(value) || value == ""
      end)

    case missing_fields do
      [] ->
        errors =
          %{}
          |> add_error(:id, validate_tax_category_id(tax_category.id))
          |> add_error(:percent, validate_percent(tax_category.percent))
          |> add_error(:tax_scheme_id, validate_tax_scheme_id(tax_category.tax_scheme_id))

        if Enum.empty?(errors), do: :ok, else: {:error, errors}

      fields ->
        {:error, missing_field_errors(fields)}
    end
  end

  defp validate_tax_category(_), do: {:error, "must be a map"}

  defp validate_tax_category_id(value) when is_binary(value) do
    if TaxCategory.valid?(value) do
      :ok
    else
      {:error,
       "must be one of: #{Enum.join(Enum.map(TaxCategory.values(), &TaxCategory.code/1), ", ")}"}
    end
  end

  defp validate_tax_category_id(_), do: {:error, "must be a valid tax category ID string"}

  defp validate_percent(value) when is_number(value) and value >= 0 and value <= 100, do: :ok
  defp validate_percent(_), do: {:error, "must be a number between 0 and 100"}

  defp validate_monetary_total(total) when is_map(total) do
    missing_fields =
      Enum.filter(@required_monetary_fields, fn field ->
        value = total[field]
        is_nil(value) || value == ""
      end)

    case missing_fields do
      [] ->
        errors =
          %{}
          |> add_error(:line_extension_amount, validate_amount(total.line_extension_amount))
          |> add_error(:tax_exclusive_amount, validate_amount(total.tax_exclusive_amount))
          |> add_error(:tax_inclusive_amount, validate_amount(total.tax_inclusive_amount))
          |> add_error(:payable_amount, validate_amount(total.payable_amount))

        if Enum.empty?(errors) do
          {:ok, total}
        else
          {:error, %{legal_monetary_total: errors}}
        end

      fields ->
        {:error, %{legal_monetary_total: missing_field_errors(fields)}}
    end
  end

  defp validate_monetary_total(_), do: {:error, %{legal_monetary_total: "must be a map"}}

  defp validate_payment_method(nil), do: {:ok, nil}

  defp validate_payment_method(payment_method) when is_map(payment_method) do
    missing_fields =
      Enum.filter(@required_payment_means_fields, fn field ->
        value = payment_method[field]
        is_nil(value) || value == ""
      end)

    case missing_fields do
      [] ->
        errors =
          %{}
          |> add_error(
            :payment_means_code,
            validate_payment_means_code(payment_method.payment_means_code)
          )
          |> add_error(
            :payee_financial_account_id,
            validate_iban(payment_method.payee_financial_account_id)
          )
          |> add_error(
            :instruction_note,
            validate_optional_non_empty_string(payment_method[:instruction_note])
          )
          |> add_error(
            :payment_id,
            validate_optional_non_empty_string(payment_method[:payment_id])
          )

        if Enum.empty?(errors) do
          {:ok, payment_method}
        else
          {:error, %{payment_method: errors}}
        end

      fields ->
        {:error, %{payment_method: missing_field_errors(fields)}}
    end
  end

  defp validate_payment_method(_), do: {:error, %{payment_method: "must be a map"}}

  defp validate_payment_means_code(value) when is_binary(value) do
    if String.match?(value, ~r/^\d{1,3}$/),
      do: :ok,
      else: {:error, "must be a numeric code (1-3 digits)"}
  end

  defp validate_payment_means_code(_), do: {:error, "must be a numeric code string"}

  defp validate_iban(value) when is_binary(value) and byte_size(value) > 0, do: :ok
  defp validate_iban(_), do: {:error, "must be a non-empty string (IBAN)"}

  defp validate_invoice_lines(lines, currency_code) when is_list(lines) and length(lines) > 0 do
    errors =
      lines
      |> Enum.with_index()
      |> Enum.reduce(%{}, fn {line, index}, acc ->
        case validate_invoice_line(line, currency_code) do
          {:ok, _} -> acc
          {:error, line_errors} -> Map.put(acc, "line_#{index + 1}", line_errors)
        end
      end)

    case Enum.empty?(errors) do
      true -> {:ok, lines}
      false -> {:error, %{invoice_lines: errors}}
    end
  end

  defp validate_invoice_lines(_, _), do: {:error, %{invoice_lines: "must be a non-empty list"}}

  defp validate_invoice_line(line, _currency_code) when is_map(line) do
    missing_fields =
      Enum.filter(@required_line_fields, fn field ->
        value = line[field]
        is_nil(value) || value == "" || (is_map(value) && map_size(value) == 0)
      end)

    case missing_fields do
      [] ->
        errors =
          %{}
          |> add_error(:id, validate_line_id(line.id))
          |> add_error(:quantity, validate_quantity(line.quantity))
          |> add_error(:unit_code, validate_unit_code(line.unit_code))
          |> add_error(:line_extension_amount, validate_amount(line.line_extension_amount))
          |> add_error(:item, validate_item(line.item))
          |> add_error(:price, validate_price(line.price))

        if Enum.empty?(errors) do
          {:ok, line}
        else
          {:error, errors}
        end

      fields ->
        {:error, missing_field_errors(fields)}
    end
  end

  defp validate_invoice_line(_, _), do: {:error, "must be a map"}

  defp validate_line_id(value) when is_binary(value) and byte_size(value) > 0, do: :ok
  defp validate_line_id(value) when is_integer(value), do: :ok
  defp validate_line_id(_), do: {:error, "must be a non-empty string or integer"}

  defp validate_quantity(value) when is_number(value) and value > 0, do: :ok
  defp validate_quantity(_), do: {:error, "must be a positive number"}

  defp validate_unit_code(value) when is_binary(value) do
    if UnitCode.valid?(value) do
      :ok
    else
      {:error,
       "only #{Enum.join(Enum.map(UnitCode.values(), &UnitCode.code/1), ", ")} is supported"}
    end
  end

  defp validate_unit_code(_), do: {:error, "must be #{UnitCode.code(UnitCode.default())}"}

  defp validate_item(item) when is_map(item) do
    missing_fields =
      Enum.filter(@required_item_fields, fn field ->
        value = item[field]
        is_nil(value) || value == "" || (is_map(value) && map_size(value) == 0)
      end)

    case missing_fields do
      [] ->
        errors =
          %{}
          |> add_error(:name, validate_item_name(item.name))
          |> add_error(
            :classified_tax_category,
            validate_classified_tax_category(item.classified_tax_category)
          )
          |> add_error(
            :commodity_classification,
            validate_required_commodity_classification(item.commodity_classification)
          )

        if Enum.empty?(errors), do: :ok, else: {:error, errors}

      fields ->
        {:error, missing_field_errors(fields)}
    end
  end

  defp validate_item(_), do: {:error, "must be a map"}

  defp validate_item_name(value) when is_binary(value) and byte_size(value) > 0, do: :ok
  defp validate_item_name(_), do: {:error, "must be a non-empty string"}

  defp validate_classified_tax_category(tax_category) when is_map(tax_category) do
    missing_fields =
      Enum.filter(@required_classified_tax_fields, fn field ->
        value = tax_category[field]
        is_nil(value) || value == ""
      end)

    case missing_fields do
      [] ->
        errors =
          %{}
          |> add_error(:id, validate_tax_category_id(tax_category.id))
          |> add_error(:percent, validate_percent(tax_category.percent))
          |> add_error(:tax_scheme_id, validate_tax_scheme_id(tax_category.tax_scheme_id))
          |> add_error(:name, validate_optional_non_empty_string(tax_category[:name]))

        if Enum.empty?(errors), do: :ok, else: {:error, errors}

      fields ->
        {:error, missing_field_errors(fields)}
    end
  end

  defp validate_classified_tax_category(_), do: {:error, "must be a map"}

  defp validate_required_commodity_classification(classification) when is_map(classification) do
    errors =
      %{}
      |> add_error(
        :item_classification_code,
        validate_non_empty_string_required(classification[:item_classification_code])
      )
      |> add_error(:list_id, validate_cg_list_id(classification[:list_id]))

    if Enum.empty?(errors), do: :ok, else: {:error, errors}
  end

  defp validate_required_commodity_classification(_),
    do: {:error, "must be a map with item_classification_code and list_id"}

  defp validate_cg_list_id("CG"), do: :ok
  defp validate_cg_list_id(_), do: {:error, "must be 'CG' for Croatian CIUS compliance"}

  defp validate_price(price) when is_map(price) do
    missing_fields =
      Enum.filter(@required_price_fields, fn field ->
        value = price[field]
        is_nil(value) || value == ""
      end)

    case missing_fields do
      [] ->
        errors =
          %{}
          |> add_error(:price_amount, validate_amount(price.price_amount))
          |> add_error(:base_quantity, validate_optional_quantity(price[:base_quantity]))
          |> add_error(
            :base_quantity_unit_code,
            validate_optional_unit_code(price[:base_quantity_unit_code])
          )

        if Enum.empty?(errors), do: :ok, else: {:error, errors}

      fields ->
        {:error, missing_field_errors(fields)}
    end
  end

  defp validate_price(_), do: {:error, "must be a map"}

  defp validate_optional_quantity(nil), do: :ok
  defp validate_optional_quantity(value) when is_number(value) and value > 0, do: :ok
  defp validate_optional_quantity(_), do: {:error, "must be a positive number"}

  defp validate_optional_unit_code(nil), do: :ok
  defp validate_optional_unit_code(value), do: validate_unit_code(value)

  defp validate_amount(value) when is_binary(value) do
    case Float.parse(value) do
      {float, ""} when float >= 0 -> :ok
      _ -> {:error, "must be a valid decimal string"}
    end
  end

  defp validate_amount(value) when is_number(value) and value >= 0, do: :ok
  defp validate_amount(_), do: {:error, "must be a non-negative number or decimal string"}

  defp missing_field_errors(fields) do
    Enum.map(fields, fn field -> {field, "is required"} end)
    |> Map.new()
  end

  defp validate_notes(nil), do: {:ok, nil}

  defp validate_notes(notes) when is_list(notes) do
    if Enum.all?(notes, &(is_binary(&1) and byte_size(&1) > 0)) do
      {:ok, notes}
    else
      {:error, %{notes: "must be a list of non-empty strings"}}
    end
  end

  defp validate_notes(_), do: {:error, %{notes: "must be a list of strings"}}

  defp atomize_attachments(nil), do: nil

  defp atomize_attachments(attachments) when is_list(attachments) do
    Enum.map(attachments, &atomize_map/1)
  end

  defp atomize_attachments(value), do: value

  defp validate_attachments(nil), do: {:ok, nil}

  defp validate_attachments(attachments) when is_list(attachments) do
    errors =
      attachments
      |> Enum.with_index(1)
      |> Enum.reduce(%{}, fn {attachment, index}, acc ->
        case validate_attachment(attachment, index) do
          :ok -> acc
          {:error, errors} -> Map.merge(acc, errors)
        end
      end)

    if map_size(errors) == 0, do: {:ok, attachments}, else: {:error, errors}
  end

  defp validate_attachments(_), do: {:error, %{attachments: "must be a list of attachment maps"}}

  defp validate_attachment(attachment, index) when is_map(attachment) do
    missing =
      @required_attachment_fields
      |> Enum.filter(fn field -> is_nil(Map.get(attachment, field)) end)

    if missing == [] do
      errors =
        %{}
        |> add_error(:"attachments[#{index}].id", validate_attachment_id(attachment[:id]))
        |> add_error(
          :"attachments[#{index}].filename",
          validate_attachment_filename(attachment[:filename])
        )
        |> add_error(
          :"attachments[#{index}].mime_code",
          validate_mime_code(attachment[:mime_code])
        )
        |> add_error(
          :"attachments[#{index}].content",
          validate_base64_content(attachment[:content])
        )

      if map_size(errors) == 0, do: :ok, else: {:error, errors}
    else
      {:error, missing_field_errors(Enum.map(missing, fn f -> :"attachments[#{index}].#{f}" end))}
    end
  end

  defp validate_attachment(_, index), do: {:error, %{:"attachments[#{index}]" => "must be a map"}}

  defp validate_attachment_id(value) when is_binary(value) and byte_size(value) > 0, do: :ok
  defp validate_attachment_id(_), do: {:error, "must be a non-empty string"}

  defp validate_attachment_filename(value) when is_binary(value) and byte_size(value) > 0, do: :ok
  defp validate_attachment_filename(_), do: {:error, "must be a non-empty string"}

  defp validate_mime_code(value) when is_binary(value) do
    valid_mime_codes = [
      "application/pdf",
      "image/png",
      "image/jpeg",
      "image/gif",
      "text/csv",
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      "application/vnd.oasis.opendocument.spreadsheet",
      "application/xml",
      "text/xml"
    ]

    if value in valid_mime_codes do
      :ok
    else
      {:error, "must be a valid MIME type (e.g., application/pdf, image/png)"}
    end
  end

  defp validate_mime_code(_), do: {:error, "must be a string"}

  defp validate_base64_content(value) when is_binary(value) and byte_size(value) > 0 do
    # Basic validation - check if it looks like valid base64
    case Base.decode64(value) do
      {:ok, _} -> :ok
      :error -> {:error, "must be valid base64-encoded content"}
    end
  end

  defp validate_base64_content(_), do: {:error, "must be a non-empty base64-encoded string"}

  defp add_error(errors, _field, :ok), do: errors

  defp add_error(errors, field, {:error, message}) do
    Map.put(errors, field, message)
  end
end
