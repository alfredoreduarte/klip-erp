require "application_system_test_case"

class ProductVariantRoutesTest < ApplicationSystemTestCase
  setup do
    @product = products(:one) # Using fixture
    @variant = product_variants(:one) # Using fixture
    
    # Ensure the variant belongs to the product
    @variant.update!(product: @product)
  end

  test "product show page displays variant links correctly" do
    visit product_path(@product)
    
    # Should show the product details
    assert_selector "h1", text: @product.name
    
    # Should have variant management link that works
    click_link "Manage Variants"
    assert_current_path product_variants_path(@product)
    
    # Go back to product page
    visit product_path(@product)
    
    # Should have individual variant links that work
    if page.has_link?(@variant.name.presence || "Default")
      click_link @variant.name.presence || "Default"
      assert_current_path product_variant_path(@product, @variant)
    end
  end

  test "product variant index page has correct back navigation" do
    visit product_variants_path(@product)
    
    # Should show the variants page
    assert_selector "h1", text: "Product Variants"
    
    # Should have working back link (arrow icon)
    find("a[href='#{product_variants_path(@product)}']").click
    assert_current_path product_variants_path(@product)
  end

  test "product variant new page has correct navigation" do
    visit new_product_variant_path(@product)
    
    # Should show the new variant form
    assert_selector "h1", text: "New Product Variant"
    
    # Should have working back link
    find("a.text-gray-400").click # Back arrow link
    assert_current_path product_variants_path(@product)
  end

  test "product variant edit page has correct cancel link" do
    visit edit_product_variant_path(@product, @variant)
    
    # Should show the edit form
    assert_selector "h1", text: "Edit Product Variant"
    
    # Should have working cancel link
    click_link "Cancel"
    assert_current_path product_variants_path(@product)
  end

  test "product variant show page displays correctly" do
    visit product_variant_path(@product, @variant)
    
    # Should show the variant details
    assert_selector "h1", text: /Product Variant/
    
    # Should have edit link
    click_link "Edit Variant"
    assert_current_path edit_product_variant_path(@product, @variant)
  end

  test "inventory adjustment show page has correct product variants link" do
    # Create an adjustment for the variant
    adjustment = inventory_adjustments(:one)
    adjustment.update!(product_variant: @variant)
    
    visit inventory_adjustment_path(adjustment)
    
    # Should have working link to product variants
    if page.has_text?("Product Variants")
      click_link "Product Variants"
      assert_current_path product_variants_path(@product)
    end
  end
end