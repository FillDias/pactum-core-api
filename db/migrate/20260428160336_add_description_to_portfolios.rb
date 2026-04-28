class AddDescriptionToPortfolios < ActiveRecord::Migration[7.2]
  def change
    add_column :portfolios, :description, :string
  end
end
