require "test_helper"

class ProductTest < ActiveSupport::TestCase
  def setup
    @product = Product.new(
      name: "Test Product",
      description: "A test product",
      category: "Electronics",
      brand: "TestBrand",
      base_price: 100.00,
      cost_price: 50.00,
      status: "active"
    )
  end

  test "should be valid with valid attributes" do
    assert @product.valid?
  end

  test "should require name" do
    @product.name = nil
    assert_not @product.valid?
    assert_includes @product.errors[:name], "can't be blank"
  end

  test "should validate status inclusion" do
    @product.status = "invalid_status"
    assert_not @product.valid?
    assert_includes @product.errors[:status], "is not included in the list"
  end

  test "should validate price numericality" do
    @product.base_price = -10
    assert_not @product.valid?
    assert_includes @product.errors[:base_price], "must be greater than or equal to 0"
  end

  test "should have many product variants" do
    @product.save!
    variant = @product.product_variants.create!(
      sku: "PRODUCT-TEST-001",
      price: 120.00,
      cost_price: 60.00
    )
    assert_includes @product.product_variants, variant
  end

  test "should calculate total inventory" do
    @product.save!
    @product.product_variants.create!(
      sku: "PRODUCT-TEST-002",
      price: 120.00,
      inventory_quantity: 10
    )
    @product.product_variants.create!(
      sku: "PRODUCT-TEST-003",
      price: 110.00,
      inventory_quantity: 5
    )
    assert_equal 15, @product.total_inventory
  end

  test "active scope should return only active products" do
    @product.save!
    inactive_product = Product.create!(
      name: "Inactive Product",
      status: "inactive"
    )

    assert_includes Product.active, @product
    assert_not_includes Product.active, inactive_product
  end

  test "should check if product is active" do
    @product.status = "active"
    assert @product.active?

    @product.status = "inactive"
    assert_not @product.active?
  end
end