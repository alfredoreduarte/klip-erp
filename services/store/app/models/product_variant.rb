class ProductVariant < ApplicationRecord
  belongs_to :product
  has_many :inventory_lots, dependent: :destroy
  has_many :order_items, dependent: :restrict_with_exception
  has_many :cart_items, dependent: :destroy
  has_many :sourcing_order_items, dependent: :restrict_with_exception
  
  validates :sku, presence: true, uniqueness: true
  validates :price, :cost_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :weight, numericality: { greater_than: 0 }, allow_nil: true
  validates :inventory_quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :inventory_policy, inclusion: { in: %w[deny continue] }
  validates :fulfillment_service, inclusion: { in: %w[manual automatic] }
  validates :weight_unit, inclusion: { in: %w[kg g lb oz] }
  validates :position, numericality: { greater_than: 0 }
  
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :in_stock, -> { where('inventory_quantity > 0') }
  scope :out_of_stock, -> { where(inventory_quantity: 0) }
  scope :low_stock, ->(threshold = 10) { where('inventory_quantity <= ?', threshold) }
  scope :trackable, -> { where(track_inventory: true) }
  
  before_save :update_inventory_from_lots
  
  def active?
    active
  end
  
  def in_stock?
    inventory_quantity > 0
  end
  
  def out_of_stock?
    inventory_quantity == 0
  end
  
  def low_stock?(threshold = 10)
    inventory_quantity <= threshold
  end
  
  def can_fulfill?(quantity)
    return true unless track_inventory?
    
    case inventory_policy
    when 'deny'
      inventory_quantity >= quantity
    when 'continue'
      true
    else
      false
    end
  end
  
  def available_quantity
    track_inventory? ? inventory_quantity : Float::INFINITY
  end
  
  def fifo_cost_for_quantity(quantity)
    return 0 if quantity <= 0
    
    remaining_quantity = quantity
    total_cost = 0
    
    inventory_lots.where(status: 'active')
                  .where('quantity_remaining > 0')
                  .order(:received_date, :created_at)
                  .each do |lot|
      break if remaining_quantity <= 0
      
      quantity_from_lot = [lot.quantity_remaining, remaining_quantity].min
      cost_from_lot = quantity_from_lot * (lot.landed_cost_per_unit || lot.unit_cost)
      
      total_cost += cost_from_lot
      remaining_quantity -= quantity_from_lot
    end
    
    total_cost
  end
  
  def average_cost
    return cost_price if inventory_lots.empty?
    
    total_cost = inventory_lots.where(status: 'active')
                              .where('quantity_remaining > 0')
                              .sum('quantity_remaining * COALESCE(landed_cost_per_unit, unit_cost)')
    
    total_quantity = inventory_lots.where(status: 'active')
                                  .where('quantity_remaining > 0')
                                  .sum(:quantity_remaining)
    
    return cost_price if total_quantity == 0
    
    total_cost / total_quantity
  end
  
  def fulfill_quantity!(quantity)
    return false unless can_fulfill?(quantity)
    
    remaining_quantity = quantity
    
    inventory_lots.where(status: 'active')
                  .where('quantity_remaining > 0')
                  .order(:received_date, :created_at)
                  .each do |lot|
      break if remaining_quantity <= 0
      
      quantity_from_lot = [lot.quantity_remaining, remaining_quantity].min
      lot.update!(quantity_remaining: lot.quantity_remaining - quantity_from_lot)
      
      remaining_quantity -= quantity_from_lot
    end
    
    update_inventory_from_lots
    true
  end
  
  def receive_inventory!(quantity, unit_cost, options = {})
    lot = inventory_lots.create!(
      lot_number: options[:lot_number] || generate_lot_number,
      quantity_received: quantity,
      quantity_remaining: quantity,
      unit_cost: unit_cost,
      total_cost: quantity * unit_cost,
      landed_cost_per_unit: options[:landed_cost_per_unit],
      total_landed_cost: options[:total_landed_cost],
      received_date: options[:received_date] || Date.current,
      expiry_date: options[:expiry_date],
      supplier_name: options[:supplier_name],
      purchase_order_number: options[:purchase_order_number],
      cost_breakdown: options[:cost_breakdown] || {},
      metadata: options[:metadata] || {}
    )
    
    update_inventory_from_lots
    lot
  end
  
  def display_name
    name.present? ? name : "#{product.name} - #{sku}"
  end
  
  private
  
  def update_inventory_from_lots
    return unless track_inventory?
    
    total_quantity = inventory_lots.where(status: 'active').sum(:quantity_remaining)
    self.inventory_quantity = total_quantity
  end
  
  def generate_lot_number
    "#{sku}-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(4).upcase}"
  end
end