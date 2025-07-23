# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create sample products for testing the order system
puts "Creating sample products..."

# Electronics
electronics = [
  { name: "iPhone 15 Pro", category: "Electronics", brand: "Apple", price: 1299.99, cost: 899.99 },
  { name: "Samsung Galaxy S24", category: "Electronics", brand: "Samsung", price: 999.99, cost: 699.99 },
  { name: "MacBook Air M2", category: "Electronics", brand: "Apple", price: 1199.99, cost: 899.99 },
  { name: "iPad Pro", category: "Electronics", brand: "Apple", price: 799.99, cost: 599.99 },
  { name: "AirPods Pro", category: "Electronics", brand: "Apple", price: 249.99, cost: 149.99 }
]

electronics.each do |product_data|
  product = Product.find_or_create_by!(name: product_data[:name]) do |p|
    p.category = product_data[:category]
    p.brand = product_data[:brand]
    p.base_price = product_data[:price]
    p.cost_price = product_data[:cost]
    p.status = 'active'
    p.track_inventory = true
    p.weight = 0.5
    p.weight_unit = 'kg'
    p.length = 15
    p.width = 10
    p.height = 2
    p.dimension_unit = 'cm'
  end

  # Create variants for each product
  ["128GB", "256GB", "512GB"].each_with_index do |storage, index|
    ProductVariant.find_or_create_by!(
      product: product,
      name: storage
    ) do |pv|
      pv.price = product_data[:price] + (index * 100)
      pv.cost_price = product_data[:cost] + (index * 70)
      pv.inventory_quantity = rand(10..50)
      pv.active = true
      pv.weight = product.weight
      pv.sku = "#{product.name.upcase.gsub(/\s+/, '-')}-#{storage}"
    end
  end
end

# Clothing
clothing = [
  { name: "Camiseta Básica", category: "Ropa", brand: "Local", price: 25.00, cost: 12.00 },
  { name: "Jeans Clásicos", category: "Ropa", brand: "Denim Co", price: 65.00, cost: 35.00 },
  { name: "Zapatillas Deportivas", category: "Calzado", brand: "SportBrand", price: 120.00, cost: 70.00 },
  { name: "Vestido Casual", category: "Ropa", brand: "Fashion Plus", price: 80.00, cost: 45.00 }
]

clothing.each do |product_data|
  product = Product.find_or_create_by!(name: product_data[:name]) do |p|
    p.category = product_data[:category]
    p.brand = product_data[:brand]
    p.base_price = product_data[:price]
    p.cost_price = product_data[:cost]
    p.status = 'active'
    p.track_inventory = true
    p.weight = 0.3
    p.weight_unit = 'kg'
    p.length = 30
    p.width = 25
    p.height = 5
    p.dimension_unit = 'cm'
  end

  # Create size variants
  ["S", "M", "L", "XL"].each do |size|
    ProductVariant.find_or_create_by!(
      product: product,
      name: size
    ) do |pv|
      pv.price = product_data[:price]
      pv.cost_price = product_data[:cost]
      pv.inventory_quantity = rand(15..40)
      pv.active = true
      pv.weight = product.weight
      pv.sku = "#{product.name.upcase.gsub(/\s+/, '-')}-#{size}"
    end
  end
end

# Home & Garden
home_products = [
  { name: "Cafetera Express", category: "Hogar", brand: "KitchenPro", price: 150.00, cost: 90.00 },
  { name: "Aspiradora Robot", category: "Hogar", brand: "CleanBot", price: 300.00, cost: 180.00 },
  { name: "Set de Sartenes", category: "Cocina", brand: "CookWare", price: 85.00, cost: 50.00 },
  { name: "Lámpara LED", category: "Iluminación", brand: "BrightLight", price: 45.00, cost: 25.00 }
]

home_products.each do |product_data|
  product = Product.find_or_create_by!(name: product_data[:name]) do |p|
    p.category = product_data[:category]
    p.brand = product_data[:brand]
    p.base_price = product_data[:price]
    p.cost_price = product_data[:cost]
    p.status = 'active'
    p.track_inventory = true
    p.weight = 2.0
    p.weight_unit = 'kg'
    p.length = 25
    p.width = 20
    p.height = 15
    p.dimension_unit = 'cm'
  end

  # Create color/model variants
  ["Negro", "Blanco", "Plateado"].each do |color|
    ProductVariant.find_or_create_by!(
      product: product,
      name: color
    ) do |pv|
      pv.price = product_data[:price]
      pv.cost_price = product_data[:cost]
      pv.inventory_quantity = rand(8..25)
      pv.active = true
      pv.weight = product.weight
      pv.sku = "#{product.name.upcase.gsub(/\s+/, '-')}-#{color.upcase}"
    end
  end
end

puts "Created #{Product.count} products with #{ProductVariant.count} variants"
