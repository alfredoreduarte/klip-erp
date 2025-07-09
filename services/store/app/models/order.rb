class Order < ApplicationRecord
  has_many :order_items, dependent: :destroy
  has_many :product_variants, through: :order_items
  has_many :payments, dependent: :destroy
  has_many :shipments, dependent: :destroy
  has_many :order_attributions, dependent: :destroy
  has_many :marketing_campaigns, through: :order_attributions
  
  validates :order_number, presence: true, uniqueness: true
  validates :short_link_token, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[pending confirmed packed shipped delivered cancelled] }
  validates :channel, inclusion: { in: %w[whatsapp phone web pos] }
  validates :subtotal, :tax_amount, :discount_amount, :shipping_amount, :total_amount, :cost_of_goods,
            numericality: { greater_than_or_equal_to: 0 }
  validates :currency, inclusion: { in: %w[USD EUR GBP PYG ARS BRL] }
  
  scope :pending, -> { where(status: 'pending') }
  scope :confirmed, -> { where(status: 'confirmed') }
  scope :packed, -> { where(status: 'packed') }
  scope :shipped, -> { where(status: 'shipped') }
  scope :delivered, -> { where(status: 'delivered') }
  scope :cancelled, -> { where(status: 'cancelled') }
  scope :by_channel, ->(channel) { where(channel: channel) }
  scope :by_customer, ->(phone) { where(customer_phone: phone) }
  scope :recent, -> { order(created_at: :desc) }
  scope :with_gift_wrap, -> { where(gift_wrap: true) }
  
  before_validation :generate_order_number, on: :create
  before_validation :generate_short_link_token, on: :create
  before_save :calculate_totals
  
  def pending?
    status == 'pending'
  end
  
  def confirmed?
    status == 'confirmed'
  end
  
  def packed?
    status == 'packed'
  end
  
  def shipped?
    status == 'shipped'
  end
  
  def delivered?
    status == 'delivered'
  end
  
  def cancelled?
    status == 'cancelled'
  end
  
  def can_be_cancelled?
    %w[pending confirmed].include?(status)
  end
  
  def can_be_shipped?
    %w[confirmed packed].include?(status)
  end
  
  def fully_paid?
    total_payments >= total_amount
  end
  
  def partially_paid?
    total_payments > 0 && total_payments < total_amount
  end
  
  def unpaid?
    total_payments == 0
  end
  
  def total_payments
    payments.where(status: 'completed').sum(:amount)
  end
  
  def remaining_balance
    total_amount - total_payments
  end
  
  def profit_margin
    return 0 if total_amount == 0
    
    ((total_amount - cost_of_goods) / total_amount * 100).round(2)
  end
  
  def total_items
    order_items.sum(:quantity)
  end
  
  def tracking_url
    return nil unless short_link_token
    
    "#{Rails.application.config.action_mailer.default_url_options[:host]}/track/#{short_link_token}"
  end
  
  def whatsapp_message_summary
    items_text = order_items.map do |item|
      "#{item.quantity}x #{item.product_variant.display_name} - #{formatted_price(item.total_price)}"
    end.join("\n")
    
    <<~MESSAGE
      🛍️ *Order #{order_number}*
      
      #{items_text}
      
      💰 Total: #{formatted_price(total_amount)}
      📍 Status: #{status.humanize}
      📱 Track: #{tracking_url}
      
      #{customer_notes.present? ? "📝 Notes: #{customer_notes}" : ""}
    MESSAGE
  end
  
  def mark_as_confirmed!
    update!(status: 'confirmed', order_date: Time.current)
    fulfill_inventory!
  end
  
  def mark_as_packed!
    update!(status: 'packed')
  end
  
  def mark_as_shipped!
    update!(status: 'shipped', shipped_date: Time.current)
  end
  
  def mark_as_delivered!
    update!(status: 'delivered', delivered_date: Time.current)
  end
  
  def cancel!
    return false unless can_be_cancelled?
    
    transaction do
      update!(status: 'cancelled')
      restore_inventory!
    end
  end
  
  def add_item(product_variant, quantity, unit_price = nil)
    unit_price ||= product_variant.price
    
    existing_item = order_items.find_by(product_variant: product_variant)
    
    if existing_item
      existing_item.update!(
        quantity: existing_item.quantity + quantity,
        total_price: (existing_item.quantity + quantity) * unit_price
      )
    else
      order_items.create!(
        product_variant: product_variant,
        quantity: quantity,
        unit_price: unit_price,
        total_price: quantity * unit_price
      )
    end
    
    calculate_totals
    save!
  end
  
  def remove_item(product_variant)
    order_items.find_by(product_variant: product_variant)&.destroy
    calculate_totals
    save!
  end
  
  private
  
  def generate_order_number
    return if order_number.present?
    
    loop do
      number = "ORD-#{Date.current.strftime('%Y%m%d')}-#{SecureRandom.hex(3).upcase}"
      break self.order_number = number unless self.class.exists?(order_number: number)
    end
  end
  
  def generate_short_link_token
    return if short_link_token.present?
    
    loop do
      token = SecureRandom.alphanumeric(8).upcase
      break self.short_link_token = token unless self.class.exists?(short_link_token: token)
    end
  end
  
  def calculate_totals
    self.subtotal = order_items.sum(:total_price)
    self.cost_of_goods = order_items.sum { |item| item.total_cost || 0 }
    
    # Add gift wrap cost if applicable
    self.subtotal += gift_wrap_cost if gift_wrap?
    
    # Calculate tax (simple flat rate for now)
    self.tax_amount = subtotal * 0.1 # 10% tax rate
    
    # Calculate total
    self.total_amount = subtotal + tax_amount + shipping_amount - discount_amount
  end
  
  def fulfill_inventory!
    order_items.each do |item|
      item.product_variant.fulfill_quantity!(item.quantity)
      item.update!(
        unit_cost: item.product_variant.fifo_cost_for_quantity(item.quantity) / item.quantity,
        total_cost: item.product_variant.fifo_cost_for_quantity(item.quantity)
      )
    end
  end
  
  def restore_inventory!
    order_items.each do |item|
      # This is a simplified version - in reality, you'd need to restore to specific lots
      variant = item.product_variant
      variant.update!(inventory_quantity: variant.inventory_quantity + item.quantity)
    end
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