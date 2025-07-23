require "test_helper"

class ProductActivationTest < ActionDispatch::IntegrationTest
  setup do
    @product = Product.create!(
      name: "Test Product for Activation",
      description: "Test product for activation/deactivation tests",
      category: "Electronics",
      status: "active"
    )
    
    @variant = @product.product_variants.create!(
      sku: "TEST-ACTIVATION-001",
      name: "Standard",
      price: 25000,
      cost_price: 15000,
      active: true
    )
  end

  test "deactivate product uses POST method and updates status" do
    assert @product.active?, "Product should start as active"
    
    # Test that the route exists and uses POST
    assert_routing(
      { method: :post, path: "/products/#{@product.id}/deactivate" },
      { controller: "products", action: "deactivate", id: @product.id.to_s }
    )
    
    # Test the actual deactivation
    post "/products/#{@product.id}/deactivate"
    
    assert_redirected_to product_path(@product)
    assert_equal "Product deactivated.", flash[:notice]
    
    @product.reload
    assert_equal "inactive", @product.status
    assert_not @product.active?
  end

  test "activate product uses POST method and updates status" do
    @product.update!(status: "inactive")
    assert_not @product.active?, "Product should start as inactive"
    
    # Test that the route exists and uses POST
    assert_routing(
      { method: :post, path: "/products/#{@product.id}/activate" },
      { controller: "products", action: "activate", id: @product.id.to_s }
    )
    
    # Test the actual activation
    post "/products/#{@product.id}/activate"
    
    assert_redirected_to product_path(@product)
    assert_equal "Product activated.", flash[:notice]
    
    @product.reload
    assert_equal "active", @product.status
    assert @product.active?
  end

  test "product variant deactivate uses POST method and updates status" do
    assert @variant.active?, "Variant should start as active"
    
    # Test that the route exists and uses POST
    assert_routing(
      { method: :post, path: "/products/#{@product.id}/variants/#{@variant.id}/deactivate" },
      { controller: "product_variants", action: "deactivate", product_id: @product.id.to_s, id: @variant.id.to_s }
    )
    
    # Test the actual deactivation
    post "/products/#{@product.id}/variants/#{@variant.id}/deactivate"
    
    assert_redirected_to product_variant_path(@product, @variant)
    
    @variant.reload
    assert_not @variant.active?
  end

  test "product variant activate uses POST method and updates status" do
    @variant.update!(active: false)
    assert_not @variant.active?, "Variant should start as inactive"
    
    # Test that the route exists and uses POST
    assert_routing(
      { method: :post, path: "/products/#{@product.id}/variants/#{@variant.id}/activate" },
      { controller: "product_variants", action: "activate", product_id: @product.id.to_s, id: @variant.id.to_s }
    )
    
    # Test the actual activation
    post "/products/#{@product.id}/variants/#{@variant.id}/activate"
    
    assert_redirected_to product_variant_path(@product, @variant)
    
    @variant.reload
    assert @variant.active?
  end

  test "product show page displays correct activate/deactivate button based on status" do
    # Test with active product - should show deactivate button
    get product_path(@product)
    assert_response :success
    
    # Should have deactivate button with correct attributes
    assert_select "a[href='#{deactivate_product_path(@product)}'][data-turbo-method='post']" do
      assert_select "svg" # Should have icon
    end
    assert_select "a", text: /Deactivate/
    
    # Should have confirmation dialog
    assert_select "a[data-confirm*='deactivate this product']"
    
    # Test with inactive product - should show activate button  
    @product.update!(status: "inactive")
    get product_path(@product)
    assert_response :success
    
    assert_select "a[href='#{activate_product_path(@product)}'][data-turbo-method='post']" do
      assert_select "svg" # Should have icon
    end
    assert_select "a", text: /Activate/
    assert_select "a[data-confirm*='Activate this product']"
  end

  test "product variant index displays correct activate/deactivate buttons" do
    get product_variants_path(@product)
    assert_response :success
    
    # Should have deactivate button for active variant
    assert_select "a[href='#{deactivate_product_variant_path(@product, @variant)}'][data-turbo-method='post']"
    assert_select "a", text: "Deactivate"
    assert_select "a[data-confirm*='Deactivate this variant']"
    
    # Test with inactive variant
    @variant.update!(active: false)
    get product_variants_path(@product)
    assert_response :success
    
    assert_select "a[href='#{activate_product_variant_path(@product, @variant)}'][data-turbo-method='post']"
    assert_select "a", text: "Activate"
    assert_select "a[data-confirm*='Activate this variant']"
  end

  test "deactivate button has proper styling and confirmation" do
    get product_path(@product)
    assert_response :success
    
    # Deactivate button should have red styling
    assert_select "a.text-red-600.border-red-300[href='#{deactivate_product_path(@product)}']"
    
    # Should have proper confirmation message
    assert_select "a[data-confirm='Are you sure you want to deactivate this product? It will no longer be available for purchase.']"
  end

  test "activate button has proper styling and confirmation" do
    @product.update!(status: "inactive")
    get product_path(@product)
    assert_response :success
    
    # Activate button should have green styling
    assert_select "a.bg-green-600[href='#{activate_product_path(@product)}']"
    
    # Should have proper confirmation message
    assert_select "a[data-confirm='Activate this product to make it available for purchase?']"
  end

  test "route helpers generate correct paths" do
    # Test product routes
    assert_equal "/products/#{@product.id}/activate", activate_product_path(@product)
    assert_equal "/products/#{@product.id}/deactivate", deactivate_product_path(@product)
    
    # Test product variant routes
    assert_equal "/products/#{@product.id}/variants/#{@variant.id}/activate", activate_product_variant_path(@product, @variant)
    assert_equal "/products/#{@product.id}/variants/#{@variant.id}/deactivate", deactivate_product_variant_path(@product, @variant)
  end

  test "product cannot be accessed via PATCH method" do
    # Old PATCH method should not work
    patch "/products/#{@product.id}/deactivate"
    assert_response :not_found
    
    patch "/products/#{@product.id}/activate"  
    assert_response :not_found
  end

  test "product variant cannot be accessed via PATCH method" do
    # Old PATCH method should not work
    patch "/products/#{@product.id}/variants/#{@variant.id}/deactivate"
    assert_response :not_found
    
    patch "/products/#{@product.id}/variants/#{@variant.id}/activate"
    assert_response :not_found
  end
end