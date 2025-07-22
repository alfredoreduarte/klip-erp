class InventoryAdjustment < ApplicationRecord
  belongs_to :product_variant
  belongs_to :user, class_name: 'User', foreign_key: 'user_id', optional: true
  belongs_to :approved_by_user, class_name: 'User', foreign_key: 'approved_by_user_id', optional: true

  # Adjustment types for inventory changes
  ADJUSTMENT_TYPES = {
    'purchase' => 'Purchase Receipt',
    'sale' => 'Sale/Order Fulfillment',
    'return' => 'Customer Return',
    'shrinkage' => 'Loss/Shrinkage',
    'damage' => 'Damaged Goods',
    'transfer_in' => 'Transfer In',
    'transfer_out' => 'Transfer Out',
    'count' => 'Physical Count Adjustment',
    'promotion' => 'Promotional Use',
    'sample' => 'Sample Given',
    'expired' => 'Expired Product',
    'manual' => 'Manual Adjustment',
    'correction' => 'Error Correction'
  }.freeze

  # Validations
  validates :adjustment_type, presence: true, inclusion: { in: ADJUSTMENT_TYPES.keys }
  validates :quantity, presence: true, numericality: { other_than: 0 }
  validates :quantity_before, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity_after, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :reason, presence: true, length: { maximum: 100 }
  validates :reference_number, length: { maximum: 50 }
  validates :cost_impact, numericality: true, allow_nil: true

  # Scopes
  scope :by_type, ->(type) { where(adjustment_type: type) }
  scope :pending_approval, -> { where(approved: false) }
  scope :approved, -> { where(approved: true) }
  scope :positive, -> { where('quantity > 0') }
  scope :negative, -> { where('quantity < 0') }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_date_range, ->(start_date, end_date) { where(created_at: start_date..end_date) }

  # Callbacks
  before_validation :set_quantity_snapshots, on: :create
  before_validation :calculate_cost_impact, on: :create
  after_create :update_product_variant_inventory
  before_validation :generate_reference_number, on: :create

  def adjustment_type_name
    ADJUSTMENT_TYPES[adjustment_type]
  end

  def positive_adjustment?
    quantity > 0
  end

  def negative_adjustment?
    quantity < 0
  end

  def requires_approval?
    ['shrinkage', 'damage', 'manual', 'correction'].include?(adjustment_type) &&
      quantity.abs > 10 # Require approval for large adjustments
  end

  def approve!(approver)
    update!(
      approved: true,
      approved_at: Time.current,
      approved_by_user: approver
    )
  end

  # Class methods for reporting
  def self.total_adjustments_by_type
    group(:adjustment_type).sum(:quantity)
  end

  def self.total_cost_impact_by_type
    group(:adjustment_type).sum(:cost_impact)
  end

  def self.for_product(product)
    joins(:product_variant).where(product_variants: { product_id: product.id })
  end

  private

  def set_quantity_snapshots
    return unless product_variant.present?
    
    self.quantity_before = product_variant.inventory_quantity
    self.quantity_after = quantity_before + quantity
  end

  def calculate_cost_impact
    return unless product_variant.present? && quantity.present?
    
    if positive_adjustment?
      # For positive adjustments, use average cost or provided cost
      cost_per_unit = product_variant.cost_price || 0
      self.cost_impact = quantity * cost_per_unit
    else
      # For negative adjustments, calculate based on FIFO cost
      cost_per_unit = product_variant.average_cost || product_variant.cost_price || 0
      self.cost_impact = quantity * cost_per_unit
    end
  end

  def update_product_variant_inventory
    # Update the product variant's inventory quantity
    new_quantity = [quantity_after, 0].max # Ensure non-negative
    product_variant.update!(inventory_quantity: new_quantity)
  end

  def generate_reference_number
    return if reference_number.present?
    
    prefix = case adjustment_type
             when 'purchase' then 'PUR'
             when 'sale' then 'SAL'
             when 'return' then 'RET'
             when 'shrinkage' then 'SHR'
             when 'damage' then 'DMG'
             when 'transfer_in' then 'TIN'
             when 'transfer_out' then 'TOU'
             when 'count' then 'CNT'
             else 'ADJ'
             end
    
    timestamp = Time.current.strftime('%Y%m%d%H%M%S')
    sequence = format('%03d', (self.class.where(adjustment_type: adjustment_type).count % 1000) + 1)
    
    self.reference_number = "#{prefix}-#{timestamp}-#{sequence}"
  end
end
