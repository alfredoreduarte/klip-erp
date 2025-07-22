class OrdersController < ApplicationController
  before_action :set_order, only: [:show, :edit, :update, :destroy]
  skip_before_action :verify_authenticity_token, only: [:parse_google_maps_link, :calculate_shipping, :search_products]

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
    
    # Enhanced shipping calculation based on city
    shipping_costs = {
      'Asunción' => 5000,
      'Ciudad del Este' => 15000,
      'Encarnación' => 20000,
      'Pedro Juan Caballero' => 25000,
      'Concepción' => 18000,
      'Villarrica' => 12000,
      'Coronel Oviedo' => 14000,
      'Caaguazú' => 16000,
      'Pilar' => 22000,
      'San Lorenzo' => 6000,
      'Lambaré' => 6000,
      'Fernando de la Mora' => 5500,
      'Capiatá' => 7000,
      'Limpio' => 8000,
      'Luque' => 6500,
      'Mariano Roque Alonso' => 7500,
      'Ñemby' => 6500,
      'San Antonio' => 8500,
      'Villa Elisa' => 7000
    }

    cost = shipping_costs[city] || 10000 # Default cost for unlisted cities
    
    render json: { cost: cost, currency: 'PYG' }
  end

  def parse_google_maps_link
    url = params[:url]
    Rails.logger.info "Processing Google Maps URL: #{url}"
    
    if url&.include?('google.com/maps') || url&.include?('maps.google.com') || url&.include?('goo.gl/maps') || url&.include?('maps.app.goo.gl')
      
      # For shortened URLs, try to resolve them first
      resolved_url = url
      if url.include?('maps.app.goo.gl') || url.include?('goo.gl')
        resolved_url = resolve_shortened_url(url) || url
        Rails.logger.info "Resolved URL: #{resolved_url}"
      end
      
      # Try to extract address information from various Google Maps URL formats
      address_info = extract_address_from_url(resolved_url)
      coordinates = extract_coordinates_from_url(resolved_url)
      
      Rails.logger.info "Extracted coordinates: #{coordinates}"
      Rails.logger.info "Extracted address info: #{address_info}"
      
      if address_info&.any? { |k, v| v.present? } || coordinates
        # Use geocoding API to get accurate location info
        geocoded_info = geocode_coordinates(coordinates) if coordinates
        
        # Combine all sources of information
        final_address = geocoded_info&.dig(:address) || 
                       address_info&.dig(:address) || 
                       "Dirección extraída de Google Maps"
        
        final_city = geocoded_info&.dig(:city) || 
                    detect_city_from_coordinates(coordinates) || 
                    address_info&.dig(:city) || 
                    detect_city_from_url(resolved_url)
        
        result = {
          address: final_address,
          city: final_city,
          coordinates: coordinates,
          neighborhood: geocoded_info&.dig(:neighborhood) || address_info&.dig(:neighborhood),
          debug: {
            original_url: url,
            resolved_url: resolved_url,
            extracted_info: address_info,
            geocoded_info: geocoded_info
          }
        }
        
        Rails.logger.info "Final result: #{result}"
        render json: result
      else
        # Fallback: return a working response even if we can't parse the URL
        Rails.logger.warn "No location info extracted, using fallback"
        render json: {
          address: "Dirección desde Google Maps",
          city: "Asunción",
          coordinates: { lat: -25.2637, lng: -57.5759 },
          neighborhood: nil,
          debug: {
            original_url: url,
            resolved_url: resolved_url,
            fallback: true
          }
        }
      end
    else
      render json: { error: "Enlace de Google Maps inválido" }, status: :unprocessable_entity
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
      :payment_method, :customer_notes, :gift_wrap, :gift_message,
      :shipping_amount, :discount_amount, :currency,
      :recipient_name, :recipient_phone, :hide_prices, :is_gift_order
    )
  end

  def resolve_shortened_url(url)
    # Try to resolve shortened Google Maps URLs
    require 'net/http'
    require 'uri'
    
    begin
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if uri.scheme == 'https'
      http.open_timeout = 5
      http.read_timeout = 5
      
      # Follow redirects to get the full URL
      response = http.get(uri.path + (uri.query ? "?#{uri.query}" : ""))
      
      case response
      when Net::HTTPRedirection
        return response['location']
      when Net::HTTPSuccess
        # Check if the response contains a redirect in the HTML
        if response.body.include?('window.location')
          match = response.body.match(/window\.location\s*=\s*["']([^"']+)["']/)
          return match[1] if match
        end
      end
      
      nil
    rescue => e
      Rails.logger.warn "Failed to resolve shortened URL #{url}: #{e.message}"
      nil
    end
  end

  def extract_coordinates_from_url(url)
    # Enhanced regex to extract coordinates from Google Maps URLs
    # Handles multiple formats:
    # - @-25.2637,-57.5759,15z
    # - ll=-25.2637,-57.5759 
    # - !3d-25.2637!4d-57.5759
    # - !2d-57.5759!3d-25.2637
    # - /search/-25.269638,+-57.571348
    
    if match = url.match(/@(-?\d+\.?\d*),(-?\d+\.?\d*)/)
      return { lat: match[1].to_f, lng: match[2].to_f }
    elsif match = url.match(/ll=(-?\d+\.?\d*),(-?\d+\.?\d*)/)
      return { lat: match[1].to_f, lng: match[2].to_f }
    elsif match = url.match(/!3d(-?\d+\.?\d*)!4d(-?\d+\.?\d*)/)
      return { lat: match[1].to_f, lng: match[2].to_f }
    elsif match = url.match(/!2d(-?\d+\.?\d*)!3d(-?\d+\.?\d*)/)
      return { lat: match[2].to_f, lng: match[1].to_f }
    elsif match = url.match(/\/search\/(-?\d+\.?\d*),\s*\+?(-?\d+\.?\d*)/)
      return { lat: match[1].to_f, lng: match[2].to_f }
    elsif match = url.match(/\/search\/(-?\d+\.?\d*),(-?\d+\.?\d*)/)
      return { lat: match[1].to_f, lng: match[2].to_f }
    end
    
    nil
  end

  def extract_address_from_url(url)
    result = { address: nil, city: nil, neighborhood: nil }
    
    # Try to extract place name or address from the URL
    # Look for patterns like /place/Address+Name/ or data= parameters
    if match = url.match(/\/place\/([^\/\?&]+)/)
      address_part = URI.decode_www_form_component(match[1]).gsub('+', ' ')
      result[:address] = address_part
      
      # Try to extract city from the address
      result[:city] = detect_city_from_text(address_part)
    end
    
    # Look for data parameters that might contain address info
    if match = url.match(/data=([^&]+)/)
      data_part = URI.decode_www_form_component(match[1])
      result[:city] ||= detect_city_from_text(data_part)
    end
    
    result
  end

  def detect_city_from_url(url)
    # List of Paraguay cities to look for in the URL
    cities = [
      'Asunción', 'Ciudad del Este', 'Encarnación', 'Pedro Juan Caballero', 
      'Concepción', 'Villarrica', 'Coronel Oviedo', 'Caaguazú', 'Pilar',
      'San Lorenzo', 'Lambaré', 'Fernando de la Mora', 'Capiatá', 'Limpio',
      'Luque', 'Mariano Roque Alonso', 'Ñemby', 'San Antonio', 'Villa Elisa'
    ]
    
    decoded_url = URI.decode_www_form_component(url.downcase)
    
    cities.find { |city| decoded_url.include?(city.downcase.gsub(' ', '+')) || decoded_url.include?(city.downcase) }
  end

  def detect_city_from_text(text)
    # Same city detection but for extracted text
    cities = [
      'Asunción', 'Ciudad del Este', 'Encarnación', 'Pedro Juan Caballero', 
      'Concepción', 'Villarrica', 'Coronel Oviedo', 'Caaguazú', 'Pilar',
      'San Lorenzo', 'Lambaré', 'Fernando de la Mora', 'Capiatá', 'Limpio',
      'Luque', 'Mariano Roque Alonso', 'Ñemby', 'San Antonio', 'Villa Elisa'
    ]
    
    text_lower = text.downcase
    cities.find { |city| text_lower.include?(city.downcase) }
  end

  def geocode_coordinates(coordinates)
    return nil unless coordinates
    
    lat = coordinates[:lat]
    lng = coordinates[:lng]
    
    begin
      require 'net/http'
      require 'uri'
      require 'json'
      
      # Nominatim reverse geocoding API
      url = "https://nominatim.openstreetmap.org/reverse?format=json&lat=#{lat}&lon=#{lng}&zoom=18&addressdetails=1"
      uri = URI(url)
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 10
      http.read_timeout = 10
      
      # Set User-Agent as required by Nominatim
      request = Net::HTTP::Get.new(uri)
      request['User-Agent'] = 'Order Management System (Paraguay)'
      
      response = http.request(request)
      
      if response.code == '200'
        data = JSON.parse(response.body)
        Rails.logger.info "Geocoding response: #{data}"
        
        address_components = data['address']
        if address_components
          # Build formatted address
          address_parts = []
          
          # Add house number and street
          if address_components['house_number'] && address_components['road']
            address_parts << "#{address_components['road']} #{address_components['house_number']}"
          elsif address_components['road']
            address_parts << address_components['road']
          end
          
          # Add neighborhood/suburb if available
          neighborhood = address_components['neighbourhood'] || 
                        address_components['suburb'] || 
                        address_components['quarter']
          
          address_parts << neighborhood if neighborhood
          
          # Get city
          city = address_components['city'] || 
                 address_components['town'] || 
                 address_components['municipality'] || 
                 address_components['village']
          
          formatted_address = address_parts.join(', ')
          formatted_address = "#{formatted_address}, #{city}" if city && !formatted_address.include?(city)
          
          return {
            address: formatted_address.present? ? formatted_address : data['display_name'],
            city: city ? normalize_city_name(city) : nil,
            neighborhood: neighborhood,
            full_response: data
          }
        end
      else
        Rails.logger.warn "Geocoding API error: #{response.code} - #{response.body}"
      end
      
    rescue => e
      Rails.logger.error "Geocoding failed: #{e.message}"
    end
    
    nil
  end

  def detect_city_from_coordinates(coordinates)
    # This method is now simplified since geocode_coordinates does the heavy lifting
    geocoded_info = geocode_coordinates(coordinates)
    geocoded_info&.dig(:city)
  end

  def normalize_city_name(city_name)
    # List of Paraguay cities we support with shipping costs
    supported_cities = [
      'Asunción', 'Ciudad del Este', 'Encarnación', 'Pedro Juan Caballero', 
      'Concepción', 'Villarrica', 'Coronel Oviedo', 'Caaguazú', 'Pilar',
      'San Lorenzo', 'Lambaré', 'Fernando de la Mora', 'Capiatá', 'Limpio',
      'Luque', 'Mariano Roque Alonso', 'Ñemby', 'San Antonio', 'Villa Elisa'
    ]
    
    # Normalize the input city name
    normalized = city_name.strip
    
    # Try exact match first
    exact_match = supported_cities.find { |city| city.downcase == normalized.downcase }
    return exact_match if exact_match
    
    # Try partial matches for common variations
    partial_match = supported_cities.find do |city|
      city.downcase.include?(normalized.downcase) || 
      normalized.downcase.include?(city.downcase)
    end
    
    return partial_match if partial_match
    
    # Special cases for common variations
    case normalized.downcase
    when 'asuncion'
      return 'Asunción'
    when 'ciudad este', 'cde'
      return 'Ciudad del Este'
    when 'encarnacion'
      return 'Encarnación'
    when 'fernando mora'
      return 'Fernando de la Mora'
    when 'lambare'
      return 'Lambaré'
    when 'nemby'
      return 'Ñemby'
    when 'san lorenzo'
      return 'San Lorenzo'
    else
      # If no match found, return nil (will use default shipping)
      Rails.logger.info "City '#{normalized}' not found in supported cities list"
      return nil
    end
  end
end