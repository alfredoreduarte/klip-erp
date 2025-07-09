class CreatePayments < ActiveRecord::Migration[7.2]
  def change
    create_table :payments do |t|
      t.references :order, null: false, foreign_key: true
      t.string :payment_method, null: false # 'cash', 'tigo', 'itau', 'card', 'online', etc.
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :currency, default: 'USD'
      t.string :status, default: 'pending'
      t.string :reference_number
      t.string :transaction_id
      t.text :notes
      t.datetime :payment_date
      t.datetime :processed_at
      t.string :processor # 'stripe', 'paypal', 'bank', 'cash', etc.
      t.jsonb :processor_response, default: {}
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :payments, :order_id, if_not_exists: true
    add_index :payments, :payment_method
    add_index :payments, :status
    add_index :payments, :reference_number
    add_index :payments, :transaction_id
    add_index :payments, :payment_date
    add_index :payments, :processor
  end
end