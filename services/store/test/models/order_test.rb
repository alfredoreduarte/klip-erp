require "test_helper"

class OrderTest < ActiveSupport::TestCase
  def setup
    @product = Product.create!(name: "Test Product", base_price: 100.00)
    @variant = @product.product_variants.create!(
      sku: "TEST-001",
      price: 120.00,
      cost_price: 60.00,
      inventory_quantity: 10
    )
    @order = Order.new(
      channel: "whatsapp",
      customer_name: "John Doe",
      customer_phone: "1234567890",
      status: "pending"
    )
  end

  test "should be valid with valid attributes" do
    assert @order.valid?
  end

  test "should generate order number automatically" do
    @order.save!
    assert_match /ORD-\d{8}-[A-F0-9]{6}/, @order.order_number
  end

  test "should generate short link token automatically" do
    @order.save!
    assert_match /[A-Z0-9]{8}/, @order.short_link_token
  end

  test "should validate channel inclusion" do
    @order.channel = "invalid_channel"
    assert_not @order.valid?
    assert_includes @order.errors[:channel], "is not included in the list"
  end

  test "should validate status inclusion" do
    @order.status = "invalid_status"
    assert_not @order.valid?
    assert_includes @order.errors[:status], "is not included in the list"
  end

  test "should add items to order" do
    @order.save!
    @order.add_item(@variant, 2)
    
    assert_equal 1, @order.order_items.count
    assert_equal 2, @order.order_items.first.quantity
    assert_equal 240.00, @order.order_items.first.total_price
  end

  test "should calculate totals when adding items" do
    @order.save!
    @order.add_item(@variant, 2)
    
    assert_equal 240.00, @order.subtotal
    assert_equal 24.00, @order.tax_amount # 10% tax
    assert_equal 264.00, @order.total_amount
  end

  test "should check payment status" do
    @order.save!
    assert @order.unpaid?
    
    @order.payments.create!(
      payment_method: "cash",
      amount: 100.00,
      status: "completed"
    )
    assert @order.partially_paid?
    
    @order.payments.create!(
      payment_method: "card",
      amount: 164.00,
      status: "completed"
    )
    assert @order.fully_paid?
  end

  test "should calculate profit margin" do
    @order.save!
    @order.add_item(@variant, 2)
    @order.update!(cost_of_goods: 120.00) # 2 * 60.00
    
    # Profit = 264.00 - 120.00 = 144.00
    # Margin = 144.00 / 264.00 * 100 = 54.55%
    assert_equal 54.55, @order.profit_margin
  end

  test "should generate tracking URL" do
    @order.save!
    Rails.application.config.action_mailer.default_url_options = { host: "example.com" }
    
    expected_url = "example.com/track/#{@order.short_link_token}"
    assert_equal expected_url, @order.tracking_url
  end

  test "should generate WhatsApp message summary" do
    @order.save!
    @order.add_item(@variant, 2)
    
    summary = @order.whatsapp_message_summary
    assert_includes summary, @order.order_number
    assert_includes summary, "2x Test Product - TEST-001"
    assert_includes summary, "$264.0" # formatted price
    assert_includes summary, "pending"
  end

  test "should mark as confirmed and fulfill inventory" do
    @order.save!
    @order.add_item(@variant, 2)
    
    initial_inventory = @variant.inventory_quantity
    @order.mark_as_confirmed!
    
    assert @order.confirmed?
    assert_not_nil @order.order_date
    assert_equal initial_inventory - 2, @variant.reload.inventory_quantity
  end

  test "should check if order can be cancelled" do
    @order.status = "pending"
    assert @order.can_be_cancelled?
    
    @order.status = "confirmed"
    assert @order.can_be_cancelled?
    
    @order.status = "shipped"
    assert_not @order.can_be_cancelled?
  end

  test "should cancel order and restore inventory" do
    @order.save!
    @order.add_item(@variant, 2)
    @order.mark_as_confirmed!
    
    initial_inventory = @variant.reload.inventory_quantity
    @order.cancel!
    
    assert @order.cancelled?
    assert_equal initial_inventory + 2, @variant.reload.inventory_quantity
  end

  test "should remove item from order" do
    @order.save!
    @order.add_item(@variant, 2)
    
    assert_equal 1, @order.order_items.count
    
    @order.remove_item(@variant)
    assert_equal 0, @order.order_items.count
  end

  test "should calculate remaining balance" do
    @order.save!
    @order.add_item(@variant, 2) # Total: 264.00
    
    @order.payments.create!(
      payment_method: "cash",
      amount: 100.00,
      status: "completed"
    )
    
    assert_equal 164.00, @order.remaining_balance
  end

  test "should count total items" do
    @order.save!
    @order.add_item(@variant, 2)
    @order.add_item(@variant, 3) # Should update existing item
    
    assert_equal 5, @order.total_items
  end

  test "should include gift wrap cost in calculations" do
    @order.save!
    @order.add_item(@variant, 1)
    @order.update!(gift_wrap: true, gift_wrap_cost: 10.00)
    
    # Subtotal should include gift wrap cost
    expected_subtotal = 120.00 + 10.00 # item + gift wrap
    assert_equal expected_subtotal, @order.subtotal
  end
end