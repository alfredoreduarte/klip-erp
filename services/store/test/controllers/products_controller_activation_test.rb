require "test_helper"

class ProductsControllerActivationTest < ActionController::TestCase
  setup do
    @controller = ProductsController.new
    @product = Product.create!(
      name: "Test Product for Controller",
      description: "Test product for controller activation tests",
      category: "Electronics", 
      status: "active"
    )
  end

  test "should deactivate product with POST" do
    assert @product.active?, "Product should start as active"
    
    post :deactivate, params: { id: @product.id }
    
    assert_redirected_to product_path(@product)
    assert_equal "Product deactivated.", flash[:notice]
    
    @product.reload
    assert_equal "inactive", @product.status
    assert_not @product.active?
  end

  test "should activate inactive product with POST" do
    @product.update!(status: "inactive")
    assert_not @product.active?, "Product should start as inactive"
    
    post :activate, params: { id: @product.id }
    
    assert_redirected_to product_path(@product)
    assert_equal "Product activated.", flash[:notice]
    
    @product.reload
    assert_equal "active", @product.status
    assert @product.active?
  end

  test "should handle activation of already active product gracefully" do
    assert @product.active?, "Product should start as active"
    
    post :activate, params: { id: @product.id }
    
    assert_redirected_to product_path(@product)
    assert_equal "Product activated.", flash[:notice]
    
    @product.reload
    assert @product.active?, "Product should remain active"
  end

  test "should handle deactivation of already inactive product gracefully" do
    @product.update!(status: "inactive")
    assert_not @product.active?, "Product should start as inactive"
    
    post :deactivate, params: { id: @product.id }
    
    assert_redirected_to product_path(@product)
    assert_equal "Product deactivated.", flash[:notice]
    
    @product.reload
    assert_not @product.active?, "Product should remain inactive"
  end

  test "should require product to exist for activation" do
    assert_raises(ActiveRecord::RecordNotFound) do
      post :activate, params: { id: 999999 }
    end
  end

  test "should require product to exist for deactivation" do
    assert_raises(ActiveRecord::RecordNotFound) do
      post :deactivate, params: { id: 999999 }
    end
  end

  test "activation and deactivation should work with string IDs" do
    # Test with string ID (common in routes)
    post :deactivate, params: { id: @product.id.to_s }
    assert_redirected_to product_path(@product)
    
    @product.reload
    assert_not @product.active?
    
    post :activate, params: { id: @product.id.to_s }
    assert_redirected_to product_path(@product)
    
    @product.reload
    assert @product.active?
  end

  test "should include product in before_action callback" do
    # Test that the before_action :set_product is working
    post :deactivate, params: { id: @product.id }
    
    # If before_action wasn't working, we'd get an error or exception
    assert_response :redirect
    # Test passes if no exception is raised and redirect happens
  end
end