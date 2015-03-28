class CreateRunAndScanTables < ActiveRecord::Migration
  def change
    create_table :bitvacuum_scans do |t|
      t.integer :number_of_inputs
      t.float :total_amount
      t.datetime :created_at
    end

    create_table :bitvacuum_runs do |t|
      t.string :currency
      t.integer :number_of_inputs
      t.float :total_amount
      t.string :address
      t.datetime :created_at
      t.string :sent_transaction_id
    end
  end
end
