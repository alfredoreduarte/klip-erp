class Cart < ApplicationRecord
  belongs_to :chat, optional: true
  has_many :cart_items, dependent: :destroy
  has_many :product_variants, through: :cart_items
  
  validates :status, inclusion: { in: %w[active abandoned converted expired] }
  validates :channel, inclusion: { in: %w[whatsapp web pos] }
  validates :subtotal, :tax_amount, :discount_amount, :shipping_amount, :total_amount,
            numericality: { greater_than_or_equal_to: 0 }
  validates :currency, inclusion: { in: %w[USD EUR GBP PYG ARS BRL] }
  
  scope :active, -> { where(status: 'active') }
  scope :abandoned, -> { where(status: 'abandoned') }
  scope :converted, -> { where(status: 'converted') }
  scope :expired, -> { where(status: 'expired') }
  scope :by_channel, ->(channel) { where(channel: channel) }
  scope :by_customer, ->(phone) { where(customer_phone: phone) }
  scope :recent, -> { order(last_activity_at: :desc) }
  scope :expiring_soon, -> { where('expires_at <= ?', 1.day.from_now) }
  
  before_save :calculate_totals
  before_save :update_activity_timestamp
  
  def active?
    status == 'active'
  end
  
  def abandoned?
    status == 'abandoned'
  end
  
  def converted?
    status == 'converted'
  end
  
  def expired?
    status == 'expired' || (expires_at && expires_at < Time.current)
  end
  
  def empty?
    cart_items.empty?
  end
  
  def total_items
    cart_items.sum(:quantity)
  end
  
  def add_item(product_variant, quantity = 1)
    existing_item = cart_items.find_by(product_variant: product_variant)
    
    if existing_item
      existing_item.update!(
        quantity: existing_item.quantity + quantity,
        total_price: (existing_item.quantity + quantity) * product_variant.price
      )
    else
      cart_items.create!(
        product_variant: product_variant,
        quantity: quantity,
        unit_price: product_variant.price,
        total_price: quantity * product_variant.price
      )
    end
    
    touch_activity!
  end
  
  def remove_item(product_variant)
    cart_items.find_by(product_variant: product_variant)&.destroy
    touch_activity!
  end
  
  def update_item_quantity(product_variant, quantity)
    item = cart_items.find_by(product_variant: product_variant)
    return unless item
    
    if quantity <= 0
      item.destroy
    else
      item.update!(
        quantity: quantity,
        total_price: quantity * item.unit_price
      )
    end
    
    touch_activity!
  end
  
  def clear!
    cart_items.destroy_all
    touch_activity!
  end
  
  def convert_to_order!
    return nil if empty?
    
    transaction do
      order = Order.create!(
        channel: channel,
        customer_name: customer_name,
        customer_phone: customer_phone,
        customer_email: customer_email,
        subtotal: subtotal,
        tax_amount: tax_amount,
        discount_amount: discount_amount,
        shipping_amount: shipping_amount,
        total_amount: total_amount,
        currency: currency,
        shipping_address: shipping_address,
        billing_address: billing_address,
        notes: notes
      )
      
      cart_items.each do |cart_item|
        order.order_items.create!(
          product_variant: cart_item.product_variant,
          quantity: cart_item.quantity,
          unit_price: cart_item.unit_price,
          total_price: cart_item.total_price
        )
      end
      
      update!(status: 'converted')
      order
    end
  end
  
  def touch_activity!
    update!(last_activity_at: Time.current)
  end
  
  def extend_expiry!(hours = 24)
    update!(expires_at: hours.hours.from_now)
  end
  
  def whatsapp_summary
    return "🛒 Your cart is empty" if empty?
    
    items_text = cart_items.map do |item|
      "#{item.quantity}x #{item.product_variant.display_name} - #{formatted_price(item.total_price)}"
    end.join("\n")
    
    <<~MESSAGE
      🛒 *Your Cart*
      
      #{items_text}
      
      💰 Total: #{formatted_price(total_amount)}
      📦 Items: #{total_items}
    MESSAGE
  end
  
  private
  
  def calculate_totals
    self.subtotal = cart_items.sum(:total_price)
    self.tax_amount = subtotal * 0.1 # 10% tax rate
    self.total_amount = subtotal + tax_amount + shipping_amount - discount_amount
  end
  
  def update_activity_timestamp
    self.last_activity_at = Time.current
  end
  
  def formatted_price(amount)
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