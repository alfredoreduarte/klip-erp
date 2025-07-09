class PackagingMaterial < ApplicationRecord
  validates :name, presence: true
  validates :sku, uniqueness: true, allow_blank: true
  validates :unit_type, presence: true
  validates :unit_cost, numericality: { greater_than: 0 }
  validates :quantity_on_hand, :reorder_point, numericality: { greater_than_or_equal_to: 0 }
  validates :weight_per_unit, numericality: { greater_than: 0 }, allow_nil: true
  validates :length, :width, :height, numericality: { greater_than: 0 }, allow_nil: true
  validates :weight_unit, inclusion: { in: %w[kg g lb oz] }
  validates :dimension_unit, inclusion: { in: %w[cm mm in ft] }
  
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :by_category, ->(category) { where(category: category) }
  scope :by_supplier, ->(supplier) { where(supplier_name: supplier) }
  scope :low_stock, -> { where('quantity_on_hand <= reorder_point') }
  scope :out_of_stock, -> { where(quantity_on_hand: 0) }
  
  def active?
    active
  end
  
  def low_stock?
    quantity_on_hand <= reorder_point
  end
  
  def out_of_stock?
    quantity_on_hand == 0
  end
  
  def total_value
    quantity_on_hand * unit_cost
  end
  
  def consume!(quantity)
    return false if quantity > quantity_on_hand
    
    update!(quantity_on_hand: quantity_on_hand - quantity)
  end
  
  def receive!(quantity)
    update!(quantity_on_hand: quantity_on_hand + quantity)
  end
end