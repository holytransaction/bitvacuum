class AddCurrencyToScans < ActiveRecord::Migration
  def change
    add_column :bitvacuum_scans, :currency, :string
  end
end
