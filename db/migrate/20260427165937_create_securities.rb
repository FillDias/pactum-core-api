class CreateSecurities < ActiveRecord::Migration[7.2]
  def change
    create_table :securities, id: :uuid do |t|
      t.string :ticker, null: false, index: { unique: true }
      t.string :name, null: false
      t.string :security_type, null: false
      t.string :currency, null: false, default: "BRL"
      t.timestamps
    end
  end
end
