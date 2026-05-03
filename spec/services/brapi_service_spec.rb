require "rails_helper"

RSpec.describe BrapiService do
  describe ".fixed_income?" do
    it { expect(described_class.fixed_income?("cdb")).to be true }
    it { expect(described_class.fixed_income?("lci")).to be true }
    it { expect(described_class.fixed_income?("lca")).to be true }
    it { expect(described_class.fixed_income?("tesouro")).to be true }
    it { expect(described_class.fixed_income?("stock")).to be false }
    it { expect(described_class.fixed_income?("fii")).to be false }
  end

  describe ".variable_income?" do
    it { expect(described_class.variable_income?("stock")).to be true }
    it { expect(described_class.variable_income?("fii")).to be true }
    it { expect(described_class.variable_income?("etf")).to be true }
    it { expect(described_class.variable_income?("bdr")).to be true }
    it { expect(described_class.variable_income?("crypto")).to be true }
    it { expect(described_class.variable_income?("cdb")).to be false }
  end

  describe "detect_security_type (via lookup_ticker mock)" do
    def detect(ticker)
      # Acessa o método privado diretamente para testar os padrões
      BrapiService.send(:detect_security_type, ticker)
    end

    context "FIIs" do
      it { expect(detect("HGLG11")).to eq("fii") }
      it { expect(detect("KNRI11")).to eq("fii") }
      it { expect(detect("VISC11")).to eq("fii") }
      it { expect(detect("XPML11")).to eq("fii") }
    end

    context "ETFs" do
      it { expect(detect("BOVA11B")).to eq("etf") }
    end

    context "BDRs" do
      it { expect(detect("AAPL34")).to eq("bdr") }
      it { expect(detect("AMZO34")).to eq("bdr") }
      it { expect(detect("MSFT34")).to eq("bdr") }
    end

    context "ações brasileiras" do
      it { expect(detect("PETR4")).to eq("stock") }
      it { expect(detect("VALE3")).to eq("stock") }
      it { expect(detect("ITUB4")).to eq("stock") }
      it { expect(detect("BBAS3")).to eq("stock") }
    end

    context "crypto" do
      it { expect(detect("BTC")).to eq("crypto") }
      it { expect(detect("BTCBRL")).to eq("crypto") }
      it { expect(detect("ETHUSD")).to eq("crypto") }
      it { expect(detect("SOL")).to eq("crypto") }
    end

    context "fallback para stock" do
      it { expect(detect("XPTO")).to eq("stock") }
      it { expect(detect("QUALQUER")).to eq("stock") }
    end
  end
end
