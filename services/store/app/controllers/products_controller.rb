class ProductsController < ApplicationController
  before_action :set_product, only: [:show, :edit, :update, :destroy, :activate, :deactivate, :duplicate]
  
  # GET /products
  def index
    @products = Product.includes(:product_variants, image_attachment: :blob)
                      .page(params[:page])
                      .per(20)
    
    # Filters
    @products = @products.where(status: params[:status]) if params[:status].present?
    @products = @products.where(category: params[:category]) if params[:category].present?
    @products = @products.where('name ILIKE ?', "%#{params[:search]}%") if params[:search].present?
    
    # Sort
    case params[:sort]
    when 'name'
      @products = @products.order(:name)
    when 'price_asc'
      @products = @products.order(:base_price)
    when 'price_desc'
      @products = @products.order(base_price: :desc)
    when 'created'
      @products = @products.order(created_at: :desc)
    else
      @products = @products.order(:name)
    end
    
    @categories = Product.distinct.pluck(:category).compact.sort
    @total_products = Product.count
    @active_products = Product.active.count
    @low_stock_count = ProductVariant.joins(:product).where(products: { track_inventory: true }).low_stock.count
  end
  
  # GET /products/1
  def show
    @variants = @product.product_variants.includes(:inventory_lots, :inventory_adjustments, image_attachment: :blob)
    @recent_adjustments = InventoryAdjustment.joins(:product_variant)
                                           .where(product_variants: { product_id: @product.id })
                                           .recent
                                           .limit(10)
    @total_inventory = @variants.sum(:inventory_quantity)
    @total_value = @variants.sum { |v| v.inventory_quantity * (v.cost_price || 0) }
  end
  
  # GET /products/new
  def new
    @product = Product.new
    @product.product_variants.build # Build one variant by default
  end
  
  # GET /products/1/edit
  def edit
  end
  
  # POST /products
  def create
    @product = Product.new(product_params)
    
    if @product.save
      redirect_to @product, notice: 'Product was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  # PATCH/PUT /products/1
  def update
    if @product.update(product_params)
      redirect_to @product, notice: 'Product was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  # DELETE /products/1
  def destroy
    if @product.product_variants.joins(:order_items).exists?
      redirect_to @product, alert: 'Cannot delete product with existing orders.'
    else
      @product.destroy!
      redirect_to products_url, notice: 'Product was successfully deleted.'
    end
  end
  
  # PATCH /products/1/activate
  def activate
    @product.update!(status: 'active')
    redirect_to @product, notice: 'Product activated.'
  end
  
  # PATCH /products/1/deactivate
  def deactivate
    @product.update!(status: 'inactive')
    redirect_to @product, notice: 'Product deactivated.'
  end
  
  # POST /products/1/duplicate
  def duplicate
    new_product = @product.dup
    new_product.name = "#{@product.name} (Copy)"
    
    if new_product.save
      # Duplicate variants
      @product.product_variants.each do |variant|
        new_variant = variant.dup
        new_variant.product = new_product
        new_variant.sku = "#{variant.sku}-COPY"
        new_variant.inventory_quantity = 0 # Reset inventory
        new_variant.save!
      end
      
      redirect_to new_product, notice: 'Product duplicated successfully.'
    else
      redirect_to @product, alert: 'Failed to duplicate product.'
    end
  end
  
  # GET /products/categories
  def categories
    @categories = Product.group(:category).count.sort_by { |name, count| -count }
    render json: @categories.map { |name, count| { name: name, count: count } }
  end
  
  # GET /products/low_stock
  def low_stock
    threshold = params[:threshold]&.to_i || 10
    @low_stock_variants = ProductVariant.joins(:product)
                                       .where(products: { track_inventory: true })
                                       .low_stock(threshold)
                                       .includes(:product, image_attachment: :blob)
                                       .order('inventory_quantity ASC')
    
    respond_to do |format|
      format.html
      format.json { render json: @low_stock_variants.as_json(include: :product) }
    end
  end
  
  # POST /products/bulk_import
  def bulk_import
    # TODO: Implement CSV/Excel import functionality
    redirect_to products_path, notice: 'Bulk import feature coming soon.'
  end
  
  # GET /products/export
  def export
    @products = Product.includes(:product_variants)
    
    respond_to do |format|
      format.csv do
        csv_data = generate_csv_export(@products)
        send_data csv_data, filename: "products_#{Date.current}.csv", type: 'text/csv'
      end
      format.json { render json: @products.as_json(include: :product_variants) }
    end
  end
  
  private
  
  def set_product
    @product = Product.find(params[:id])
  end
  
  def product_params
    params.require(:product).permit(
      :name, :description, :category, :brand, :base_price, :cost_price,
      :status, :track_inventory, :weight, :weight_unit, :length, :width, :height,
      :dimension_unit, :tax_category, :image,
      custom_attributes: {},
      metadata: {},
      product_variants_attributes: [
        :id, :sku, :barcode, :name, :price, :cost_price, :weight, :weight_unit,
        :position, :active, :requires_shipping, :track_inventory, :inventory_quantity,
        :inventory_policy, :fulfillment_service, :compare_at_price, :image, :_destroy,
        option_values: {}
      ]
    )
  end
  
  def generate_csv_export(products)
    require 'csv'
    
    CSV.generate(headers: true) do |csv|
      csv << [
        'Product Name', 'Category', 'Brand', 'Status', 'Base Price', 'Cost Price',
        'Variant SKU', 'Variant Name', 'Variant Price', 'Variant Cost', 'Inventory'
      ]
      
      products.each do |product|
        if product.product_variants.any?
          product.product_variants.each do |variant|
            csv << [
              product.name, product.category, product.brand, product.status,
              product.base_price, product.cost_price, variant.sku, variant.name,
              variant.price, variant.cost_price, variant.inventory_quantity
            ]
          end
        else
          csv << [
            product.name, product.category, product.brand, product.status,
            product.base_price, product.cost_price, '', '', '', '', ''
          ]
        end
      end
    end
  end
end