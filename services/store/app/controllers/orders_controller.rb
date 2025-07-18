class OrdersController < ApplicationController
  before_action :set_order, only: [:show, :edit, :update, :destroy]

  def index
    @orders = Order.includes(:order_items, :product_variants).recent.limit(50)
  end

  def show
  end

  def new
    @order = Order.new
    @order.currency = 'USD'
    @order.channel = 'pos'
    @order.status = 'pending'
  end

  def create
    @order = Order.new(order_params)
    @order.channel = 'pos'
    @order.status = 'pending'

    # Handle cart items from JavaScript
    if params[:cart_items].present?
      cart_items = JSON.parse(params[:cart_items])
      
      cart_items.each do |item|
        product_variant = ProductVariant.find(item['productId'])
        @order.order_items.build(
          product_variant: product_variant,
          quantity: item['quantity'].to_i,
          unit_price: item['price'].to_f
        )
      end
    end

    if @order.save
      redirect_to @order, notice: 'Order was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @order.update(order_params)
      redirect_to @order, notice: 'Order was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @order.cancel! if @order.can_be_cancelled?
    redirect_to orders_url, notice: 'Order was cancelled.'
  end

  # API endpoints for dynamic functionality
  def search_products
    query = params[:q]
    products = Product.joins(:product_variants)
                     .where("products.name ILIKE ? OR products.category ILIKE ?", "%#{query}%", "%#{query}%")
                     .where(status: 'active')
                     .includes(:product_variants)
                     .limit(10)

    results = products.map do |product|
      product.product_variants.map do |variant|
        {
          id: variant.id,
          name: variant.display_name,
          price: variant.price,
          inventory: variant.inventory_quantity,
          thumbnail_url: variant.thumbnail_url,
          category: product.category
        }
      end
    end.flatten

    render json: results
  end

  def calculate_shipping
    city = params[:city]
    
    # Simple shipping calculation based on city
    shipping_costs = {
      'Asunción' => 5000,
      'Ciudad del Este' => 15000,
      'Encarnación' => 20000,
      'Pedro Juan Caballero' => 25000,
      'Concepción' => 18000
    }

    cost = shipping_costs[city] || 10000 # Default cost
    
    render json: { cost: cost, currency: 'PYG' }
  end

  def parse_google_maps_link
    url = params[:url]
    
    # Extract coordinates from Google Maps URL
    # This is a simplified parser - production would need more robust parsing
    if url&.include?('google.com/maps')
      # Try to extract lat,lng from various Google Maps URL formats
      coordinates = extract_coordinates_from_url(url)
      
      if coordinates
        # Here you would typically use a geocoding service to get the address
        # For now, we'll return a mock response
        render json: {
          address: "Extracted from Google Maps",
          city: "Asunción", 
          coordinates: coordinates
        }
      else
        render json: { error: "Could not parse Google Maps URL" }, status: :unprocessable_entity
      end
    else
      render json: { error: "Invalid Google Maps URL" }, status: :unprocessable_entity
    end
  end

  private

  def set_order
    @order = Order.find(params[:id])
  end

  def order_params
    params.require(:order).permit(
      :customer_name, :customer_surname, :customer_phone, :customer_email,
      :shipping_address, :shipping_city, :shipping_notes,
      :delivery_date, :delivery_time_start, :delivery_time_end,
      :payment_method, :customer_notes, :gift_wrap,
      :shipping_amount, :discount_amount, :currency
    )
  end

  def extract_coordinates_from_url(url)
    # Simple regex to extract coordinates from Google Maps URLs
    # Handles formats like: @-25.2637,-57.5759,15z or ll=-25.2637,-57.5759
    if match = url.match(/@(-?\d+\.?\d*),(-?\d+\.?\d*)/)
      return { lat: match[1].to_f, lng: match[2].to_f }
    elsif match = url.match(/ll=(-?\d+\.?\d*),(-?\d+\.?\d*)/)
      return { lat: match[1].to_f, lng: match[2].to_f }
    end
    
    nil
  end
end