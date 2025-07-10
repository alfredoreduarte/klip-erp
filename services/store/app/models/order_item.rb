class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product_variant
  
  validates :quantity, numericality: { greater_than: 0 }
  validates :unit_price, :total_price, numericality: { greater_than_or_equal_to: 0 }
  validates :unit_cost, :total_cost, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :fulfillment_status, inclusion: { in: %w[pending fulfilled cancelled] }
  
  scope :pending, -> { where(fulfillment_status: 'pending') }
  scope :fulfilled, -> { where(fulfillment_status: 'fulfilled') }
  scope :cancelled, -> { where(fulfillment_status: 'cancelled') }
  
  before_save :calculate_total_price
  
  def pending?
    fulfillment_status == 'pending'
  end
  
  def fulfilled?
    fulfillment_status == 'fulfilled'
  end
  
  def cancelled?
    fulfillment_status == 'cancelled'
  end
  
  def profit
    return 0 unless total_cost
    total_price - total_cost
  end
  
  def profit_margin
    return 0 if total_price == 0
    (profit / total_price * 100).round(2)
  end
  
  private
  
  def calculate_total_price
    self.total_price = quantity * unit_price if quantity && unit_price
    self.total_cost = quantity * unit_cost if quantity && unit_cost
  end
end