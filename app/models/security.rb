class Security < ApplicationRecord
  has_many :transactions, dependent: :destroy

  validates :ticker, presence: true, uniqueness: { case_sensitive: false }
  validates :name, presence: true
  validates :security_type, presence: true
end
