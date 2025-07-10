class CashRegisterSession < ApplicationRecord
  validates :session_number, presence: true, uniqueness: true
  validates :cashier_name, presence: true
  validates :status, inclusion: { in: %w[open closed] }
  validates :opening_cash, numericality: { greater_than_or_equal_to: 0 }
  validates :closing_cash, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :opened_at, presence: true
  
  scope :open, -> { where(status: 'open') }
  scope :closed, -> { where(status: 'closed') }
  scope :by_cashier, ->(cashier) { where(cashier_name: cashier) }
  
  before_validation :generate_session_number, on: :create
  before_save :calculate_totals
  
  def open?
    status == 'open'
  end
  
  def closed?
    status == 'closed'
  end
  
  def session_duration
    return nil unless opened_at
    
    end_time = closed_at || Time.current
    ((end_time - opened_at) / 1.hour).round(2)
  end
  
  def close_session!(closing_cash_amount, notes = nil)
    return false unless open?
    
    self.closing_cash = closing_cash_amount
    self.actual_cash = closing_cash_amount
    self.closed_at = Time.current
    self.closing_notes = notes
    self.status = 'closed'
    
    save!
  end
  
  def cash_variance
    return 0 unless expected_cash && actual_cash
    
    actual_cash - expected_cash
  end
  
  def over_short_percentage
    return 0 if expected_cash == 0
    
    (cash_variance / expected_cash * 100).round(2)
  end
  
  private
  
  def generate_session_number
    return if session_number.present?
    
    date_prefix = Date.current.strftime('%Y%m%d')
    counter = self.class.where('session_number LIKE ?', "#{date_prefix}-%").count + 1
    
    self.session_number = "#{date_prefix}-#{counter.to_s.rjust(3, '0')}"
  end
  
  def calculate_totals
    self.expected_cash = opening_cash + cash_sales - cash_deposits + cash_withdrawals
    self.cash_difference = cash_variance
  end
end