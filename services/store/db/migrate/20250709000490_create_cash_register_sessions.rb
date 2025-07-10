class CreateCashRegisterSessions < ActiveRecord::Migration[7.2]
  def change
    create_table :cash_register_sessions do |t|
      t.string :session_number, null: false
      t.string :cashier_name, null: false
      t.string :status, default: 'open'
      t.decimal :opening_cash, precision: 10, scale: 2, null: false
      t.decimal :closing_cash, precision: 10, scale: 2
      t.decimal :cash_sales, precision: 10, scale: 2, default: 0
      t.decimal :card_sales, precision: 10, scale: 2, default: 0
      t.decimal :other_sales, precision: 10, scale: 2, default: 0
      t.decimal :total_sales, precision: 10, scale: 2, default: 0
      t.decimal :cash_deposits, precision: 10, scale: 2, default: 0
      t.decimal :cash_withdrawals, precision: 10, scale: 2, default: 0
      t.decimal :expected_cash, precision: 10, scale: 2
      t.decimal :actual_cash, precision: 10, scale: 2
      t.decimal :cash_difference, precision: 10, scale: 2
      t.datetime :opened_at, null: false
      t.datetime :closed_at
      t.text :opening_notes
      t.text :closing_notes
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :cash_register_sessions, :session_number, unique: true
    add_index :cash_register_sessions, :cashier_name
    add_index :cash_register_sessions, :status
    add_index :cash_register_sessions, :opened_at
    add_index :cash_register_sessions, :closed_at
  end
end