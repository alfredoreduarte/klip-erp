class SourcingOrder < ApplicationRecord
  has_many :sourcing_order_items, dependent: :destroy
  has_many :product_variants, through: :sourcing_order_items
  
  validates :po_number, presence: true, uniqueness: true
  validates :supplier_name, presence: true
  validates :status, inclusion: { in: %w[draft sent confirmed received completed cancelled] }
  validates :subtotal, :shipping_cost, :customs_duty, :marketplace_fees, :handling_fees, :other_costs, :total_cost,
            numericality: { greater_than_or_equal_to: 0 }
  validates :currency, inclusion: { in: %w[USD EUR GBP PYG ARS BRL] }
  
  scope :draft, -> { where(status: 'draft') }
  scope :sent, -> { where(status: 'sent') }
  scope :confirmed, -> { where(status: 'confirmed') }
  scope :received, -> { where(status: 'received') }
  scope :completed, -> { where(status: 'completed') }
  scope :cancelled, -> { where(status: 'cancelled') }
  scope :by_supplier, ->(supplier) { where(supplier_name: supplier) }
  
  before_validation :generate_po_number, on: :create
  before_save :calculate_total_cost
  
  def draft?
    status == 'draft'
  end
  
  def sent?
    status == 'sent'
  end
  
  def confirmed?
    status == 'confirmed'
  end
  
  def received?
    status == 'received'
  end
  
  def completed?
    status == 'completed'
  end
  
  def cancelled?
    status == 'cancelled'
  end
  
  def total_items
    sourcing_order_items.sum(:quantity_ordered)
  end
  
  def total_received
    sourcing_order_items.sum(:quantity_received)
  end
  
  def fully_received?
    total_items == total_received
  end
  
  def landed_cost_per_item
    return 0 if total_items == 0
    
    total_cost / total_items
  end
  
  def add_item(product_variant, quantity, unit_cost)
    existing_item = sourcing_order_items.find_by(product_variant: product_variant)
    
    if existing_item
      existing_item.update!(
        quantity_ordered: existing_item.quantity_ordered + quantity,
        total_cost: (existing_item.quantity_ordered + quantity) * unit_cost
      )
    else
      sourcing_order_items.create!(
        product_variant: product_variant,
        quantity_ordered: quantity,
        unit_cost: unit_cost,
        total_cost: quantity * unit_cost
      )
    end
  end
  
  def receive_items!
    sourcing_order_items.each do |item|
      next if item.quantity_received >= item.quantity_ordered
      
      quantity_to_receive = item.quantity_ordered - item.quantity_received
      landed_cost = item.unit_cost + (total_cost - subtotal) / total_items
      
      item.product_variant.receive_inventory!(
        quantity_to_receive,
        item.unit_cost,
        landed_cost_per_unit: landed_cost,
        supplier_name: supplier_name,
        purchase_order_number: po_number,
        received_date: actual_delivery_date || Date.current
      )
      
      item.update!(
        quantity_received: item.quantity_ordered,
        received_date: Date.current,
        status: 'received'
      )
    end
    
    update!(status: 'received')
  end
  
  private
  
  def generate_po_number
    return if po_number.present?
    
    loop do
      number = "PO-#{Date.current.strftime('%Y%m%d')}-#{SecureRandom.hex(3).upcase}"
      break self.po_number = number unless self.class.exists?(po_number: number)
    end
  end
  
  def calculate_total_cost
    self.subtotal = sourcing_order_items.sum(:total_cost)
    self.total_cost = subtotal + shipping_cost + customs_duty + marketplace_fees + handling_fees + other_costs
  end
end