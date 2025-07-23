class InventoryLotsController < ApplicationController
  before_action :set_lot, only: [:show, :edit, :update, :destroy]
  
  # GET /inventory/lots
  def index
    @lots = InventoryLot.includes(:product_variant)
                       .order(received_date: :desc)
                       .limit(100)
    
    # Filters
    @lots = @lots.where(status: params[:status]) if params[:status].present?
    @lots = @lots.where(supplier_name: params[:supplier]) if params[:supplier].present?
    @lots = @lots.joins(:product_variant).where(product_variants: { sku: params[:sku] }) if params[:sku].present?
    
    if params[:expiring] == 'true'
      @lots = @lots.where('expiry_date <= ? AND status = ?', 30.days.from_now, 'active')
    end
    
    # Summary statistics
    @total_lots = @lots.count
    @active_lots = InventoryLot.where(status: 'active').count
    @expiring_lots = InventoryLot.where('expiry_date <= ? AND status = ?', 30.days.from_now, 'active').count
    @suppliers = InventoryLot.distinct.pluck(:supplier_name).compact.sort
    
    respond_to do |format|
      format.html
      format.json { render json: @lots.as_json(include: [:product_variant]) }
    end
  end
  
  # GET /inventory/lots/expiring
  def expiring
    @lots = InventoryLot.includes(:product_variant)
                       .where('expiry_date <= ? AND status = ?', 30.days.from_now, 'active')
                       .order(:expiry_date)
    
    respond_to do |format|
      format.html { render :index }
      format.json { render json: @lots.as_json(include: [:product_variant]) }
    end
  end
  
  # GET /inventory/lots/1
  def show
    @product_variant = @lot.product_variant
    @product = @product_variant.product
    @related_lots = @product_variant.inventory_lots.where.not(id: @lot.id).order(received_date: :desc).limit(5)
  end
  
  # GET /inventory/lots/new
  def new
    @lot = InventoryLot.new
    @product_variant = ProductVariant.find(params[:product_variant_id]) if params[:product_variant_id]
    @products = Product.includes(:product_variants).active.order(:name)
  end
  
  # GET /inventory/lots/1/edit
  def edit
    @products = Product.includes(:product_variants).active.order(:name)
  end
  
  # POST /inventory/lots
  def create
    @lot = InventoryLot.new(lot_params)
    
    if @lot.save
      redirect_to @lot, notice: 'Inventory lot was successfully created.'
    else
      @products = Product.includes(:product_variants).active.order(:name)
      render :new, status: :unprocessable_entity
    end
  end
  
  # PATCH/PUT /inventory/lots/1
  def update
    if @lot.update(lot_params)
      redirect_to @lot, notice: 'Inventory lot was successfully updated.'
    else
      @products = Product.includes(:product_variants).active.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end
  
  # DELETE /inventory/lots/1
  def destroy
    if @lot.quantity_remaining > 0 && @lot.active?
      redirect_to @lot, alert: 'Cannot delete lot with remaining inventory. Adjust to zero first.'
    else
      @lot.destroy!
      redirect_to inventory_lots_url, notice: 'Inventory lot was successfully deleted.'
    end
  end
  
  # POST /inventory/lots/bulk_receive
  def bulk_receive
    lots_data = params[:lots] || []
    created_lots = []
    errors = []
    
    lots_data.each_with_index do |lot_params, index|
      lot = InventoryLot.new(lot_params.permit(:product_variant_id, :quantity_received, :unit_cost, :supplier_name, :purchase_order_number, :expiry_date, :received_date))
      lot.quantity_remaining = lot.quantity_received
      lot.total_cost = lot.quantity_received * lot.unit_cost if lot.unit_cost
      lot.status = 'active'
      
      if lot.save
        created_lots << lot
      else
        errors << { index: index, errors: lot.errors.full_messages }
      end
    end
    
    if errors.empty?
      redirect_to inventory_lots_path, notice: "Successfully received #{created_lots.count} inventory lots."
    else
      flash[:alert] = "Received #{created_lots.count} lots with #{errors.count} errors."
      redirect_to inventory_lots_path
    end
  end
  
  private
  
  def set_lot
    @lot = InventoryLot.find(params[:id])
  end
  
  def lot_params
    params.require(:inventory_lot).permit(
      :product_variant_id, :quantity_received, :quantity_remaining, :unit_cost, :total_cost,
      :landed_cost_per_unit, :total_landed_cost, :received_date, :expiry_date,
      :supplier_name, :purchase_order_number, :status, cost_breakdown: {}, metadata: {}
    )
  end
end