require "test_helper"

class ProductsShowViewTest < ActionView::TestCase
  include Rails.application.routes.url_helpers

  setup do
    @product = products(:one)
    @variant = product_variants(:one)
    @variants = [@variant] # Simulate controller instance variable
  end

  test "products show view renders without route errors" do
    # Simulate the controller setting instance variables
    assign(:product, @product)
    assign(:variants, @variants)
    
    # This should not raise any route generation errors
    assert_nothing_raised do
      render template: "products/show", locals: {}
    end
    
    # Verify key elements are present
    assert_select "h1", text: @product.name
    assert_select "a[href=?]", product_variants_path(@product), text: "Manage Variants"
  end

  test "variant links use correct route helpers" do
    assign(:product, @product)
    assign(:variants, @variants)
    
    render template: "products/show", locals: {}
    
    # Check that variant view links are generated correctly
    assert_select "a[href=?]", product_variant_path(@product, @variant), text: "View"
    assert_select "a[href=?]", edit_product_variant_path(@product, @variant), text: "Edit"
  end

  test "manage variants link works correctly" do
    assign(:product, @product)
    assign(:variants, @variants)
    
    render template: "products/show", locals: {}
    
    # Should have the manage variants link with correct path
    assert_select "a[href=?]", product_variants_path(@product) do
      assert_select "svg" # Should have the icon
    end
  end
end