class Payment < ApplicationRecord
  belongs_to :order
  
  validates :payment_method, presence: true
  validates :amount, numericality: { greater_than: 0 }
  validates :currency, inclusion: { in: %w[USD EUR GBP PYG ARS BRL] }
  validates :status, inclusion: { in: %w[pending processing completed failed refunded] }
  
  scope :pending, -> { where(status: 'pending') }
  scope :processing, -> { where(status: 'processing') }
  scope :completed, -> { where(status: 'completed') }
  scope :failed, -> { where(status: 'failed') }
  scope :refunded, -> { where(status: 'refunded') }
  scope :by_method, ->(method) { where(payment_method: method) }
  
  def pending?
    status == 'pending'
  end
  
  def processing?
    status == 'processing'
  end
  
  def completed?
    status == 'completed'
  end
  
  def failed?
    status == 'failed'
  end
  
  def refunded?
    status == 'refunded'
  end
  
  def mark_as_completed!
    update!(status: 'completed', processed_at: Time.current)
  end
  
  def mark_as_failed!
    update!(status: 'failed', processed_at: Time.current)
  end
  
  def formatted_amount
    case currency
    when 'USD'
      "$#{amount}"
    when 'EUR'
      "€#{amount}"
    when 'PYG'
      "₲#{amount.to_i}"
    else
      "#{currency} #{amount}"
    end
  end
end