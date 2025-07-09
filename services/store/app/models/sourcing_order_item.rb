class SourcingOrderItem < ApplicationRecord
  belongs_to :sourcing_order
  belongs_to :product_variant
  
  validates :quantity_ordered, numericality: { greater_than: 0 }
  validates :quantity_received, numericality: { greater_than_or_equal_to: 0 }
  validates :unit_cost, :total_cost, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: %w[pending received cancelled] }
  
  scope :pending, -> { where(status: 'pending') }
  scope :received, -> { where(status: 'received') }
  scope :cancelled, -> { where(status: 'cancelled') }
  
  before_save :calculate_total_cost
  
  def pending?
    status == 'pending'
  end
  
  def received?
    status == 'received'
  end
  
  def cancelled?
    status == 'cancelled'
  end
  
  def fully_received?
    quantity_received >= quantity_ordered
  end
  
  def remaining_quantity
    quantity_ordered - quantity_received
  end
  
  def receive_quantity!(quantity)
    return false if quantity <= 0 || quantity_received + quantity > quantity_ordered
    
    self.quantity_received += quantity
    self.status = 'received' if fully_received?
    save!
  end
  
  private
  
  def calculate_total_cost
    self.total_cost = quantity_ordered * unit_cost if quantity_ordered && unit_cost
  end
end