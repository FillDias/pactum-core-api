class User < ApplicationRecord
  has_secure_password
  has_many :portfolios, dependent: :destroy

  validates :name, presence: true
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }

  before_save { email.downcase! }
end
