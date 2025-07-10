class Product < ApplicationRecord
  has_many :product_variants, dependent: :destroy
  has_many :inventory_lots, through: :product_variants
  
  validates :name, presence: true, length: { minimum: 1, maximum: 255 }
  validates :status, inclusion: { in: %w[active inactive discontinued] }
  validates :base_price, :cost_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :weight, numericality: { greater_than: 0 }, allow_nil: true
  validates :length, :width, :height, numericality: { greater_than: 0 }, allow_nil: true
  validates :weight_unit, inclusion: { in: %w[kg g lb oz] }
  validates :dimension_unit, inclusion: { in: %w[cm mm in ft] }
  
  scope :active, -> { where(status: 'active') }
  scope :inactive, -> { where(status: 'inactive') }
  scope :discontinued, -> { where(status: 'discontinued') }
  scope :by_category, ->(category) { where(category: category) }
  scope :by_brand, ->(brand) { where(brand: brand) }
  scope :trackable, -> { where(track_inventory: true) }
  
  def active?
    status == 'active'
  end
  
  def inactive?
    status == 'inactive'
  end
  
  def discontinued?
    status == 'discontinued'
  end
  
  def total_inventory
    product_variants.sum(:inventory_quantity)
  end
  
  def lowest_price
    product_variants.active.minimum(:price) || base_price
  end
  
  def highest_price
    product_variants.active.maximum(:price) || base_price
  end
  
  def average_cost
    return cost_price if product_variants.empty?
    
    product_variants.where.not(cost_price: nil).average(:cost_price) || cost_price
  end
  
  def total_value
    product_variants.sum { |variant| (variant.cost_price || 0) * variant.inventory_quantity }
  end
  
  def categories
    self.class.distinct.pluck(:category).compact.sort
  end
  
  def brands
    self.class.distinct.pluck(:brand).compact.sort
  end
end