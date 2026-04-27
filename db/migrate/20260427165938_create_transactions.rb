class CreateTransactions < ActiveRecord::Migration[7.2]
  def change
    create_table :transactions, id: :uuid do |t|
      t.references :portfolio, type: :uuid, null: false, foreign_key: true
      t.references :security,  type: :uuid, null: false, foreign_key: true
      t.string  :transaction_type, null: false
      t.decimal :quantity, precision: 15, scale: 6, null: false
      t.decimal :price,    precision: 15, scale: 6, null: false
      t.date    :date, null: false
      t.string  :broker
      t.timestamps
    end
  end
end
