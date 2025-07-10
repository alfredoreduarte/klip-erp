require "test_helper"

class ProductVariantTest < ActiveSupport::TestCase
  def setup
    @product = Product.create!(
      name: "Test Product",
      base_price: 100.00
    )
    @variant = @product.product_variants.create!(
      sku: "TEST-001",
      price: 120.00,
      cost_price: 60.00,
      inventory_quantity: 0
    )
  end

  test "should be valid with valid attributes" do
    assert @variant.valid?
  end

  test "should require unique SKU" do
    duplicate_variant = @product.product_variants.build(
      sku: "TEST-001",
      price: 110.00
    )
    assert_not duplicate_variant.valid?
    assert_includes duplicate_variant.errors[:sku], "has already been taken"
  end

  test "should receive inventory and create lot" do
    lot = @variant.receive_inventory!(10, 50.00, supplier_name: "Test Supplier")
    
    assert_equal 10, @variant.reload.inventory_quantity
    assert_equal 1, @variant.inventory_lots.count
    assert_equal 50.00, lot.unit_cost
    assert_equal "Test Supplier", lot.supplier_name
  end

  test "should calculate FIFO cost correctly" do
    # First lot - older, cheaper
    @variant.receive_inventory!(5, 40.00, received_date: 2.days.ago)
    # Second lot - newer, more expensive
    @variant.receive_inventory!(5, 60.00, received_date: 1.day.ago)
    
    # Should use FIFO - first the cheaper lot, then the expensive one
    cost_for_3 = @variant.fifo_cost_for_quantity(3)
    assert_equal 120.00, cost_for_3 # 3 * 40.00
    
    cost_for_7 = @variant.fifo_cost_for_quantity(7)
    assert_equal 320.00, cost_for_7 # (5 * 40.00) + (2 * 60.00)
  end

  test "should fulfill quantity using FIFO" do
    # Create two lots
    @variant.receive_inventory!(5, 40.00, received_date: 2.days.ago)
    @variant.receive_inventory!(5, 60.00, received_date: 1.day.ago)
    
    # Fulfill 7 items - should use 5 from first lot and 2 from second
    @variant.fulfill_quantity!(7)
    
    lots = @variant.inventory_lots.order(:received_date)
    assert_equal 0, lots.first.quantity_remaining  # First lot depleted
    assert_equal 3, lots.second.quantity_remaining # Second lot has 3 remaining
    assert_equal 3, @variant.reload.inventory_quantity
  end

  test "should check if can fulfill quantity" do
    @variant.receive_inventory!(10, 50.00)
    
    assert @variant.can_fulfill?(5)
    assert @variant.can_fulfill?(10)
    assert_not @variant.can_fulfill?(15)
  end

  test "should check stock status" do
    assert @variant.out_of_stock?
    assert_not @variant.in_stock?
    
    @variant.receive_inventory!(10, 50.00)
    assert @variant.in_stock?
    assert_not @variant.out_of_stock?
    
    @variant.update!(inventory_quantity: 5)
    assert @variant.low_stock?(10)
    assert_not @variant.low_stock?(3)
  end

  test "should calculate average cost from lots" do
    @variant.receive_inventory!(5, 40.00)
    @variant.receive_inventory!(5, 60.00)
    
    # Average should be (5*40 + 5*60) / 10 = 50.00
    assert_equal 50.00, @variant.average_cost
  end

  test "should generate lot number automatically" do
    lot = @variant.receive_inventory!(10, 50.00)
    assert_match /TEST-001-\d{8}-[A-F0-9]{8}/, lot.lot_number
  end

  test "should have display name" do
    @variant.name = "Red Variant"
    assert_equal "Red Variant", @variant.display_name
    
    @variant.name = nil
    assert_equal "Test Product - TEST-001", @variant.display_name
  end

  test "should validate inventory policy" do
    @variant.inventory_policy = "invalid"
    assert_not @variant.valid?
    assert_includes @variant.errors[:inventory_policy], "is not included in the list"
  end

  test "should respect inventory policy when checking fulfillment" do
    @variant.update!(inventory_quantity: 5, inventory_policy: "deny")
    assert_not @variant.can_fulfill?(10)
    
    @variant.update!(inventory_policy: "continue")
    assert @variant.can_fulfill?(10)
  end
end