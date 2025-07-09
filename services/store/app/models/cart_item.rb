class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product_variant
  
  validates :quantity, numericality: { greater_than: 0 }
  validates :unit_price, :total_price, numericality: { greater_than_or_equal_to: 0 }
  
  before_save :calculate_total_price
  after_save :touch_cart_activity
  after_destroy :touch_cart_activity
  
  def can_fulfill?
    product_variant.can_fulfill?(quantity)
  end
  
  def availability_message
    return "✅ Available" if can_fulfill?
    
    available = product_variant.available_quantity
    if available == 0
      "❌ Out of stock"
    else
      "⚠️ Only #{available} available"
    end
  end
  
  private
  
  def calculate_total_price
    self.total_price = quantity * unit_price if quantity && unit_price
  end
  
  def touch_cart_activity
    cart.touch_activity!
  end
end