class AddFixedIncomeFieldsToSecurities < ActiveRecord::Migration[7.2]
  def change
    add_column :securities, :annual_rate, :decimal
    add_column :securities, :index_type, :string
    add_column :securities, :maturity_date, :date
  end
end
