FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    name     { "Test User" }
    password { "password123" }
  end

  factory :portfolio do
    user
    name     { "Carteira Teste" }
    currency { "BRL" }
  end

  factory :security do
    sequence(:ticker) { |n| "TICK#{n}" }
    name          { "Security Teste" }
    security_type { "stock" }
    annual_rate   { nil }
    index_type    { nil }
    maturity_date { nil }
  end

  factory :transaction do
    portfolio
    security
    transaction_type { "BUY" }
    quantity         { 100.0 }
    price            { 30.0 }
    date             { "2024-01-15" }
    broker           { nil }
  end
end
