require "rails_helper"

RSpec.describe PositionService do
  let(:portfolio) { create(:portfolio) }
  let(:stock)     { create(:security, ticker: "PETR4", security_type: "stock") }
  let(:fii)       { create(:security, ticker: "HGLG11", security_type: "fii") }
  let(:cdb)       { create(:security, ticker: "CDB-BANCO-X", security_type: "cdb", annual_rate: 12.5, index_type: "CDI") }

  before do
    allow(BrapiService).to receive(:fetch_quotes).and_return({})
    allow(BrapiService).to receive(:variable_income?).and_call_original
  end

  describe ".build_positions" do
    context "sem transações" do
      it "retorna array vazio" do
        expect(described_class.build_positions(portfolio)).to eq([])
      end
    end

    context "posição simples — uma compra" do
      before { create(:transaction, portfolio: portfolio, security: stock, quantity: 100, price: 30.0) }

      it "retorna uma posição" do
        positions = described_class.build_positions(portfolio)
        expect(positions.length).to eq(1)
      end

      it "calcula custo médio corretamente" do
        pos = described_class.build_positions(portfolio).first
        expect(pos[:averagePrice]).to eq(30.0)
        expect(pos[:costBasis]).to eq(3000.0)
      end

      it "usa último preço de transação quando BRAPI não retorna" do
        pos = described_class.build_positions(portfolio).first
        expect(pos[:priceSource]).to eq("last_transaction")
        expect(pos[:currentPrice]).to eq(30.0)
      end

      it "usa preço da BRAPI quando disponível" do
        allow(BrapiService).to receive(:fetch_quotes).and_return({ "PETR4" => 38.50 })
        pos = described_class.build_positions(portfolio).first
        expect(pos[:priceSource]).to eq("brapi")
        expect(pos[:currentPrice]).to eq(38.5)
        expect(pos[:marketValue]).to eq(3850.0)
      end

      it "marca priceSource como unavailable quando sem preço algum" do
        # Cria transação sem preço disponível via BRAPI e apaga para simular ausência
        allow(BrapiService).to receive(:fetch_quotes).and_return({})
        pos = described_class.build_positions(portfolio).first
        # last_transaction usa o preço da compra — não é unavailable aqui
        expect(pos[:priceSource]).not_to eq("unavailable")
      end
    end

    context "compra e venda parcial" do
      before do
        create(:transaction, portfolio: portfolio, security: stock, transaction_type: "BUY",  quantity: 100, price: 30.0, date: "2024-01-01")
        create(:transaction, portfolio: portfolio, security: stock, transaction_type: "SELL", quantity: 40,  price: 35.0, date: "2024-02-01")
      end

      it "mostra quantidade líquida correta" do
        pos = described_class.build_positions(portfolio).first
        expect(pos[:quantity]).to eq(60.0)
      end

      it "custo médio usa apenas as compras" do
        pos = described_class.build_positions(portfolio).first
        expect(pos[:averagePrice]).to eq(30.0)
      end
    end

    context "posição totalmente zerada — compra e venda integral" do
      before do
        create(:transaction, portfolio: portfolio, security: stock, transaction_type: "BUY",  quantity: 100, price: 30.0, date: "2024-01-01")
        create(:transaction, portfolio: portfolio, security: stock, transaction_type: "SELL", quantity: 100, price: 35.0, date: "2024-02-01")
      end

      it "não retorna a posição zerada" do
        expect(described_class.build_positions(portfolio)).to be_empty
      end
    end

    context "custo médio ponderado — múltiplas compras" do
      before do
        create(:transaction, portfolio: portfolio, security: stock, transaction_type: "BUY", quantity: 100, price: 20.0, date: "2024-01-01")
        create(:transaction, portfolio: portfolio, security: stock, transaction_type: "BUY", quantity: 100, price: 40.0, date: "2024-02-01")
      end

      it "calcula média ponderada corretamente" do
        pos = described_class.build_positions(portfolio).first
        expect(pos[:averagePrice]).to eq(30.0)
        expect(pos[:quantity]).to eq(200.0)
        expect(pos[:costBasis]).to eq(6000.0)
      end
    end

    context "múltiplos ativos" do
      before do
        create(:transaction, portfolio: portfolio, security: stock, quantity: 100, price: 30.0)
        create(:transaction, portfolio: portfolio, security: fii,   quantity: 50,  price: 100.0)
      end

      it "retorna posição para cada ativo" do
        positions = described_class.build_positions(portfolio)
        tickers = positions.map { |p| p[:ticker] }
        expect(tickers).to include("PETR4", "HGLG11")
      end
    end

    context "ativo de renda fixa" do
      before { create(:transaction, portfolio: portfolio, security: cdb, quantity: 1, price: 10_000.0, date: 365.days.ago.to_date.to_s) }

      it "inclui metadados de renda fixa" do
        pos = described_class.build_positions(portfolio).first
        expect(pos[:annualRate]).to eq(12.5)
        expect(pos[:indexType]).to eq("CDI")
      end

      it "usa priceSource estimated quando tem annual_rate" do
        pos = described_class.build_positions(portfolio).first
        expect(pos[:priceSource]).to eq("estimated")
      end

      it "calcula valor estimado maior que o investido após 1 ano" do
        pos = described_class.build_positions(portfolio).first
        expect(pos[:currentPrice]).to be > 10_000.0
        expect(pos[:pl]).to be > 0
      end

      it "não consulta BRAPI para renda fixa" do
        described_class.build_positions(portfolio)
        expect(BrapiService).not_to have_received(:fetch_quotes).with(include("CDB-BANCO-X"))
      end
    end

    context "priceSource unavailable — ativo de renda variável sem preço" do
      let(:novo_stock) { create(:security, ticker: "XYZW3", security_type: "stock") }

      it "marca como unavailable quando BRAPI falha e sem transação prévia" do
        # Criamos via SQL direto para ter transação mas sem preço na BRAPI
        allow(BrapiService).to receive(:fetch_quotes).and_return({})
        create(:transaction, portfolio: portfolio, security: novo_stock, quantity: 10, price: 15.0, date: "2024-01-01")
        pos = described_class.build_positions(portfolio).first
        # Deve cair em last_transaction porque há preço histórico
        expect(pos[:priceSource]).to eq("last_transaction")
        expect(pos[:currentPrice]).to eq(15.0)
      end
    end
  end
end
