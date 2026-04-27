class Transaction < ApplicationRecord
  belongs_to :portfolio
  belongs_to :security

  validates :quantity, numericality: { greater_than: 0 }
  validates :price, numericality: { greater_than: 0 }
  validates :transaction_type, inclusion: { in: %w[BUY SELL] }
  validates :date, presence: true
end
