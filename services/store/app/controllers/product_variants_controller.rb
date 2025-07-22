class ProductVariantsController < ApplicationController
  before_action :set_product
  before_action :set_variant, only: [:show, :edit, :update, :destroy, :activate, :deactivate, :duplicate]
  
  # GET /products/1/variants
  def index
    @variants = @product.product_variants.includes(:inventory_lots, :inventory_adjustments, image_attachment: :blob)
                        .order(:position, :name)
    
    @total_inventory = @variants.sum(:inventory_quantity)
    @total_value = @variants.sum { |v| v.inventory_quantity * (v.cost_price || 0) }
    @active_variants = @variants.count(&:active?)
  end
  
  # GET /products/1/variants/1
  def show
    @inventory_lots = @variant.inventory_lots.order(received_date: :desc)
    @recent_adjustments = @variant.inventory_adjustments.recent.limit(10)
    @recent_orders = @variant.order_items.joins(:order).limit(10)
    
    # Inventory analytics
    @total_received = @inventory_lots.sum(:quantity_received)
    @total_remaining = @inventory_lots.sum(:quantity_remaining)
    @expiring_soon = @inventory_lots.where('expiry_date <= ?', 30.days.from_now).where(status: 'active')
  end
  
  # GET /products/1/variants/new
  def new
    @variant = @product.product_variants.build
    @variant.position = (@product.product_variants.maximum(:position) || 0) + 1
  end
  
  # GET /products/1/variants/1/edit
  def edit
  end
  
  # POST /products/1/variants
  def create
    @variant = @product.product_variants.build(variant_params)
    
    if @variant.save
      redirect_to [@product, @variant], notice: 'Variant was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  # PATCH/PUT /products/1/variants/1
  def update
    if @variant.update(variant_params)
      redirect_to [@product, @variant], notice: 'Variant was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  # DELETE /products/1/variants/1
  def destroy
    if @variant.order_items.exists?
      redirect_to [@product, @variant], alert: 'Cannot delete variant with existing orders.'
    else
      @variant.destroy!
      redirect_to product_variants_path(@product), notice: 'Variant was successfully deleted.'
    end
  end
  
  # PATCH /products/1/variants/1/activate
  def activate
    @variant.update!(active: true)
    redirect_to [@product, @variant], notice: 'Variant activated.'
  end
  
  # PATCH /products/1/variants/1/deactivate
  def deactivate
    @variant.update!(active: false)
    redirect_to [@product, @variant], notice: 'Variant deactivated.'
  end
  
  # POST /products/1/variants/1/duplicate
  def duplicate
    new_variant = @variant.dup
    new_variant.sku = "#{@variant.sku}-COPY"
    new_variant.name = "#{@variant.name} (Copy)" if @variant.name.present?
    new_variant.inventory_quantity = 0 # Reset inventory
    new_variant.position = (@product.product_variants.maximum(:position) || 0) + 1
    
    if new_variant.save
      redirect_to [@product, new_variant], notice: 'Variant duplicated successfully.'
    else
      redirect_to [@product, @variant], alert: 'Failed to duplicate variant.'
    end
  end
  
  private
  
  def set_product
    @product = Product.find(params[:product_id])
  end
  
  def set_variant
    @variant = @product.product_variants.find(params[:id])
  end
  
  def variant_params
    params.require(:product_variant).permit(
      :sku, :barcode, :name, :price, :cost_price, :weight, :weight_unit,
      :position, :active, :requires_shipping, :track_inventory, :inventory_quantity,
      :inventory_policy, :fulfillment_service, :compare_at_price, :image,
      option_values: {}
    )
  end
end