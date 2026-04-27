class Portfolio < ApplicationRecord
  belongs_to :user
  has_many :transactions, dependent: :destroy
  has_many :securities, through: :transactions

  validates :name, presence: true
  validates :currency, presence: true, inclusion: { in: %w[BRL USD EUR] }
end
