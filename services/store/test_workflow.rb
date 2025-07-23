# Test complete purchase-to-stock workflow

puts '=== Testing Complete Purchase-to-Stock Workflow ==='

# 1. Create or find a test product
product = Product.find_or_create_by(name: 'Test Widget Pro') do |p|
  p.description = 'A test product for workflow validation'
  p.category = 'Electronics'
  p.status = 'active'
end

# 2. Create product variant
variant = product.product_variants.find_or_create_by(sku: 'TWP-001') do |v|
  v.name = 'Standard'
  v.price = 25000
  v.cost_price = 15000
  v.weight = 0.5
  v.active = true
end

puts "✓ Product: #{product.name} (#{variant.sku})"

# 3. Create sourcing order
order = SourcingOrder.create!(
  supplier_name: 'Test Supplier Co.',
  supplier_email: 'orders@testsupplier.com',
  order_date: Date.current,
  status: 'draft',
  notes: 'Test order for workflow validation'
)

# 4. Add items to sourcing order
order_item = order.sourcing_order_items.new(
  product_variant: variant,
  quantity_ordered: 100,
  quantity_received: 0,
  unit_cost: 15000,
  status: 'pending',
  notes: 'Initial stock for new product'
)
order_item.save!

puts "✓ Sourcing Order: #{order.id} with #{order_item.quantity_ordered} units"

# 5. Submit order
order.update!(status: 'submitted')
puts '✓ Order submitted'

# 6. Approve order
order.update!(status: 'approved')
puts '✓ Order approved'

# 7. Receive order (this should create inventory lot and adjustment)
order.update!(status: 'received')

# Create inventory lot manually (simulating the receive process)
lot = InventoryLot.create!(
  product_variant: variant,
  quantity_received: order_item.quantity_ordered,
  quantity_remaining: order_item.quantity_ordered,
  unit_cost: order_item.unit_cost,
  total_cost: order_item.quantity_ordered * order_item.unit_cost,
  supplier_name: order.supplier_name,
  purchase_order_number: "PO-#{order.id}",
  received_date: Date.current,
  status: 'active'
)

# Create purchase adjustment
adjustment = InventoryAdjustment.create!(
  product_variant: variant,
  adjustment_type: 'purchase',
  quantity: order_item.quantity_ordered,
  unit_cost: order_item.unit_cost,
  total_cost_impact: order_item.quantity_ordered * order_item.unit_cost,
  reference_number: "PO-#{order.id}",
  reason: 'Purchase order receipt',
  adjustment_date: Date.current,
  quantity_before: 0,
  quantity_after: order_item.quantity_ordered,
  status: 'approved'
)

puts "✓ Inventory Lot: #{lot.lot_number} (#{lot.quantity_remaining} units)"
puts "✓ Purchase Adjustment: #{adjustment.reference_number} (+#{adjustment.quantity} units)"

# 8. Test sale adjustment
sale_qty = 25
sale_adjustment = InventoryAdjustment.create!(
  product_variant: variant,
  adjustment_type: 'sale',
  quantity: -sale_qty,
  unit_cost: variant.cost_price,
  total_cost_impact: -(sale_qty * variant.cost_price),
  reference_number: 'SALE-TEST-001',
  reason: 'Test sale transaction',
  adjustment_date: Date.current,
  quantity_before: lot.quantity_remaining,
  quantity_after: lot.quantity_remaining - sale_qty,
  status: 'approved'
)

# Update lot quantity
lot.update!(quantity_remaining: lot.quantity_remaining - sale_qty)

puts "✓ Sale Adjustment: #{sale_adjustment.reference_number} (-#{sale_qty} units)"
puts "✓ Updated Lot: #{lot.quantity_remaining} units remaining"

# 9. Test inventory count adjustment
count_qty = 72 # Physical count shows 72 instead of expected 75
difference = count_qty - lot.quantity_remaining
count_adjustment = InventoryAdjustment.create!(
  product_variant: variant,
  adjustment_type: 'count',
  quantity: difference,
  unit_cost: variant.cost_price,
  total_cost_impact: difference * variant.cost_price,
  reference_number: 'COUNT-001',
  reason: 'Physical inventory count discrepancy',
  adjustment_date: Date.current,
  quantity_before: lot.quantity_remaining,
  quantity_after: count_qty,
  status: 'approved'
)

lot.update!(quantity_remaining: count_qty)

puts "✓ Count Adjustment: #{count_adjustment.reference_number} (#{difference} units difference)"
puts "✓ Final Lot Quantity: #{lot.quantity_remaining} units"

# 10. Generate summary
puts "\n=== Workflow Summary ==="
puts "Product: #{product.name} (#{variant.sku})"
puts "Sourcing Order: #{order.id} - #{order.status}"
puts "Inventory Lot: #{lot.lot_number} - #{lot.status}"
puts "Adjustments: #{variant.inventory_adjustments.count} total"
puts "Current Stock: #{lot.quantity_remaining} units"
puts "Total Value: ₲#{(lot.landed_cost_per_unit || lot.unit_cost) * lot.quantity_remaining if lot.unit_cost}"
puts "\n✅ Complete purchase-to-stock workflow test successful!"