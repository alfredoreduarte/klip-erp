require "test_helper"

class ProductVariantRoutingTest < ActionDispatch::IntegrationTest
  include Rails.application.routes.url_helpers

  setup do
    @product = products(:one)
    @variant = product_variants(:one)
  end

  test "product variant route helpers generate correct paths" do
    # Test individual route helpers
    assert_equal "/products/#{@product.id}/variants", product_variants_path(@product)
    assert_equal "/products/#{@product.id}/variants/new", new_product_variant_path(@product)
    assert_equal "/products/#{@product.id}/variants/#{@variant.id}", product_variant_path(@product, @variant)
    assert_equal "/products/#{@product.id}/variants/#{@variant.id}/edit", edit_product_variant_path(@product, @variant)
    assert_equal "/products/#{@product.id}/variants/#{@variant.id}/activate", activate_product_variant_path(@product, @variant)
    assert_equal "/products/#{@product.id}/variants/#{@variant.id}/deactivate", deactivate_product_variant_path(@product, @variant)
    assert_equal "/products/#{@product.id}/variants/#{@variant.id}/duplicate", duplicate_product_variant_path(@product, @variant)
  end

  test "polymorphic path with symbol generates correct variants index path" do
    # Test polymorphic route with symbol - this should work for index
    expected_path = "/products/#{@product.id}/variants"
    actual_path = polymorphic_path([@product, :variants])
    assert_equal expected_path, actual_path
  end

  test "polymorphic path does not work for individual variant show path" do
    # This is the problematic case - polymorphic routing doesn't work well 
    # with nested resources for individual resources
    assert_raises(ActionController::UrlGenerationError) do
      polymorphic_path([@product, @variant])
    end
  end

  test "explicit route helpers work for all variant actions" do
    # These should all work without errors
    assert_nothing_raised do
      product_variants_path(@product)
      new_product_variant_path(@product)
      product_variant_path(@product, @variant)
      edit_product_variant_path(@product, @variant)
      activate_product_variant_path(@product, @variant)
      deactivate_product_variant_path(@product, @variant)
      duplicate_product_variant_path(@product, @variant)
    end
  end
end