defmodule ExCius.Enums.BusinessProcessTest do
  use ExUnit.Case, async: true

  alias ExCius.Enums.BusinessProcess

  describe "valid?/1" do
    test "returns true for valid atom keys" do
      assert BusinessProcess.valid?(:p1)
      assert BusinessProcess.valid?(:p2)
      assert BusinessProcess.valid?(:p3)
      assert BusinessProcess.valid?(:p4)
      assert BusinessProcess.valid?(:p5)
      assert BusinessProcess.valid?(:p6)
      assert BusinessProcess.valid?(:p7)
      assert BusinessProcess.valid?(:p8)
      assert BusinessProcess.valid?(:p9)
      assert BusinessProcess.valid?(:p10)
      assert BusinessProcess.valid?(:p11)
      assert BusinessProcess.valid?(:p12)
      assert BusinessProcess.valid?(:p99)
      assert BusinessProcess.valid?(:billing)
    end

    test "returns true for valid string codes" do
      assert BusinessProcess.valid?("P1")
      assert BusinessProcess.valid?("P2")
      assert BusinessProcess.valid?("P3")
      assert BusinessProcess.valid?("P4")
      assert BusinessProcess.valid?("P5")
      assert BusinessProcess.valid?("P6")
      assert BusinessProcess.valid?("P7")
      assert BusinessProcess.valid?("P8")
      assert BusinessProcess.valid?("P9")
      assert BusinessProcess.valid?("P10")
      assert BusinessProcess.valid?("P11")
      assert BusinessProcess.valid?("P12")
      assert BusinessProcess.valid?("P99")
    end

    test "returns false for invalid values" do
      refute BusinessProcess.valid?(:invalid)
      refute BusinessProcess.valid?("P100")
      refute BusinessProcess.valid?(123)
      refute BusinessProcess.valid?(nil)
    end
  end

  describe "code/1" do
    test "returns correct code for atom keys" do
      assert BusinessProcess.code(:p1) == "P1"
      assert BusinessProcess.code(:p2) == "P2"
      assert BusinessProcess.code(:p3) == "P3"
      assert BusinessProcess.code(:p4) == "P4"
      assert BusinessProcess.code(:p5) == "P5"
      assert BusinessProcess.code(:p6) == "P6"
      assert BusinessProcess.code(:p7) == "P7"
      assert BusinessProcess.code(:p8) == "P8"
      assert BusinessProcess.code(:p9) == "P9"
      assert BusinessProcess.code(:p10) == "P10"
      assert BusinessProcess.code(:p11) == "P11"
      assert BusinessProcess.code(:p12) == "P12"
      assert BusinessProcess.code(:p99) == "P99"
      assert BusinessProcess.code(:billing) == "P1"
    end

    test "returns code unchanged when passed a code string" do
      assert BusinessProcess.code("P1") == "P1"
      assert BusinessProcess.code("P10") == "P10"
      assert BusinessProcess.code("P99") == "P99"
    end

    test "returns nil for invalid values" do
      assert BusinessProcess.code(:invalid) == nil
      assert BusinessProcess.code("invalid") == nil
    end
  end

  describe "from_code/1" do
    test "converts code strings to atoms" do
      assert BusinessProcess.from_code("P1") == :p1
      assert BusinessProcess.from_code("P2") == :p2
      assert BusinessProcess.from_code("P3") == :p3
      assert BusinessProcess.from_code("P4") == :p4
      assert BusinessProcess.from_code("P5") == :p5
      assert BusinessProcess.from_code("P6") == :p6
      assert BusinessProcess.from_code("P7") == :p7
      assert BusinessProcess.from_code("P8") == :p8
      assert BusinessProcess.from_code("P9") == :p9
      assert BusinessProcess.from_code("P10") == :p10
      assert BusinessProcess.from_code("P11") == :p11
      assert BusinessProcess.from_code("P12") == :p12
      assert BusinessProcess.from_code("P99") == :p99
    end

    test "returns nil for invalid codes" do
      assert BusinessProcess.from_code("INVALID") == nil
      assert BusinessProcess.from_code("P100") == nil
    end
  end

  describe "description/1" do
    test "returns description for p1" do
      assert BusinessProcess.description(:p1) =~
               "Issuing invoices for supplies of goods and services"
    end

    test "returns description for p4 (prepayment)" do
      assert BusinessProcess.description(:p4) == "Payment in advance (Prepayment)"
    end

    test "returns description for p5 (spot payment)" do
      assert BusinessProcess.description(:p5) == "Payment on the spot (Spot payment)"
    end

    test "returns description for p9 (credit notes)" do
      assert BusinessProcess.description(:p9) =~
               "Credit notes or invoices with negative amounts"
    end

    test "returns description for p10 (corrective invoice)" do
      assert BusinessProcess.description(:p10) =~
               "Issuance of a corrective invoice"
    end

    test "returns description for p12 (self-issuance)" do
      assert BusinessProcess.description(:p12) == "Self-issuance of invoices"
    end

    test "returns description for p99 (customer-defined)" do
      assert BusinessProcess.description(:p99) == "Customer-defined process"
    end

    test "returns nil for invalid key" do
      assert BusinessProcess.description(:invalid) == nil
    end
  end

  describe "values/0" do
    test "returns all valid atom keys" do
      values = BusinessProcess.values()

      assert :p1 in values
      assert :p2 in values
      assert :p3 in values
      assert :p4 in values
      assert :p5 in values
      assert :p6 in values
      assert :p7 in values
      assert :p8 in values
      assert :p9 in values
      assert :p10 in values
      assert :p11 in values
      assert :p12 in values
      assert :p99 in values
      assert :billing in values
    end
  end

  describe "default/0" do
    test "returns :p1 as default" do
      assert BusinessProcess.default() == :p1
    end
  end

  describe "accessor functions" do
    test "p1/0 returns :p1" do
      assert BusinessProcess.p1() == :p1
    end

    test "p9/0 returns :p9" do
      assert BusinessProcess.p9() == :p9
    end

    test "p10/0 returns :p10" do
      assert BusinessProcess.p10() == :p10
    end

    test "p99/0 returns :p99" do
      assert BusinessProcess.p99() == :p99
    end

    test "billing/0 returns :billing (legacy)" do
      assert BusinessProcess.billing() == :billing
    end
  end
end
