class InventoryLot < ApplicationRecord
  belongs_to :product_variant
  
  validates :lot_number, presence: true, uniqueness: true
  validates :quantity_received, :quantity_remaining, numericality: { greater_than_or_equal_to: 0 }
  validates :unit_cost, :total_cost, numericality: { greater_than: 0 }
  validates :landed_cost_per_unit, :total_landed_cost, numericality: { greater_than: 0 }, allow_nil: true
  validates :received_date, presence: true
  validates :status, inclusion: { in: %w[active depleted expired] }
  
  validate :quantity_remaining_not_greater_than_received
  validate :expiry_date_after_received_date
  
  scope :active, -> { where(status: 'active') }
  scope :depleted, -> { where(status: 'depleted') }
  scope :expired, -> { where(status: 'expired') }
  scope :with_remaining, -> { where('quantity_remaining > 0') }
  scope :by_supplier, ->(supplier) { where(supplier_name: supplier) }
  scope :by_po, ->(po_number) { where(purchase_order_number: po_number) }
  scope :expiring_soon, ->(days = 30) { where('expiry_date <= ?', Date.current + days.days) }
  scope :fifo_order, -> { order(:received_date, :created_at) }
  
  before_save :update_status
  before_save :calculate_totals
  
  def active?
    status == 'active'
  end
  
  def depleted?
    status == 'depleted'
  end
  
  def expired?
    status == 'expired'
  end
  
  def expiring_soon?(days = 30)
    expiry_date.present? && expiry_date <= Date.current + days.days
  end
  
  def effective_unit_cost
    landed_cost_per_unit || unit_cost
  end
  
  def effective_total_cost
    total_landed_cost || total_cost
  end
  
  def utilization_percentage
    return 0 if quantity_received == 0
    
    ((quantity_received - quantity_remaining).to_f / quantity_received * 100).round(2)
  end
  
  def days_since_received
    (Date.current - received_date).to_i
  end
  
  def days_until_expiry
    return nil unless expiry_date
    
    (expiry_date - Date.current).to_i
  end
  
  def reduce_quantity!(amount)
    return false if amount <= 0 || amount > quantity_remaining
    
    self.quantity_remaining -= amount
    save!
  end
  
  def cost_allocation_for_quantity(quantity)
    return 0 if quantity <= 0
    
    allocated_quantity = [quantity, quantity_remaining].min
    allocated_quantity * effective_unit_cost
  end
  
  def to_s
    "#{lot_number} (#{quantity_remaining}/#{quantity_received})"
  end
  
  private
  
  def quantity_remaining_not_greater_than_received
    return unless quantity_remaining && quantity_received
    
    if quantity_remaining > quantity_received
      errors.add(:quantity_remaining, "cannot be greater than quantity received")
    end
  end
  
  def expiry_date_after_received_date
    return unless expiry_date && received_date
    
    if expiry_date <= received_date
      errors.add(:expiry_date, "must be after received date")
    end
  end
  
  def update_status
    if quantity_remaining == 0
      self.status = 'depleted'
    elsif expiry_date.present? && expiry_date < Date.current
      self.status = 'expired'
    else
      self.status = 'active'
    end
  end
  
  def calculate_totals
    self.total_cost = quantity_received * unit_cost if quantity_received && unit_cost
    
    if quantity_received && landed_cost_per_unit
      self.total_landed_cost = quantity_received * landed_cost_per_unit
    end
  end
end