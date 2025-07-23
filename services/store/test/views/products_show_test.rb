require "test_helper"

class ProductsShowViewTest < ActionDispatch::IntegrationTest
  include Rails.application.routes.url_helpers

  setup do
    @product = Product.create!(
      name: "Test Product",
      description: "A test product for view tests",
      category: "Electronics",
      status: "active"
    )
    @variant = ProductVariant.create!(
      product: @product,
      sku: "VIEW-TEST-001",
      name: "Standard",
      price: 25000,
      cost_price: 15000,
      weight: 0.5,
      inventory_quantity: 100,
      active: true,
      track_inventory: true,
      inventory_policy: "deny",
      fulfillment_service: "manual",
      weight_unit: "kg",
      position: 1
    )
    @variants = [@variant] # Simulate controller instance variable
  end

    test "products show view renders without route errors" do
    # This should not raise any route generation errors
    assert_nothing_raised do
      get product_path(@product)
    end

    # Verify key elements are present
    assert_select "h1", text: @product.name
    assert_select "a[href=?]", product_variants_path(@product), text: "Manage Variants"
  end

    test "variant links use correct route helpers" do
    get product_path(@product)

    # Check that variant view links are generated correctly
    assert_select "a[href=?]", product_variant_path(@product, @variant), text: "View"
    assert_select "a[href=?]", edit_product_variant_path(@product, @variant), text: "Edit"
  end

    test "manage variants link works correctly" do
    get product_path(@product)

    # Should have the manage variants link with correct path
    assert_select "a[href=?]", product_variants_path(@product) do
      assert_select "svg" # Should have the icon
    end
  end
end