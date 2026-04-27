class CreatePortfolios < ActiveRecord::Migration[7.2]
  def change
    create_table :portfolios, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.string :name, null: false
      t.string :currency, null: false, default: "BRL"
      t.timestamps
    end
  end
end
