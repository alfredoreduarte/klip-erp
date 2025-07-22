class InventoryAdjustmentsController < ApplicationController
  before_action :set_adjustment, only: [:show, :edit, :update, :destroy]
  
  # GET /inventory/adjustments
  def index
    @adjustments = InventoryAdjustment.includes(:product_variant, :user, :approved_by_user)
                                     .recent
                                     .page(params[:page])
                                     .per(25)
    
    # Filters
    @adjustments = @adjustments.by_type(params[:type]) if params[:type].present?
    @adjustments = @adjustments.where(approved: params[:approved] == 'true') if params[:approved].present?
    @adjustments = @adjustments.joins(:product_variant).where(product_variants: { sku: params[:sku] }) if params[:sku].present?
    @adjustments = @adjustments.by_date_range(Date.parse(params[:start_date]), Date.parse(params[:end_date])) if params[:start_date].present? && params[:end_date].present?
    
    # Summary statistics
    @total_adjustments = @adjustments.count
    @pending_approval = InventoryAdjustment.pending_approval.count
    @adjustment_types = InventoryAdjustment::ADJUSTMENT_TYPES
    
    respond_to do |format|
      format.html
      format.json { render json: @adjustments.as_json(include: [:product_variant, :user]) }
    end
  end
  
  # GET /inventory/adjustments/1
  def show
    @product_variant = @adjustment.product_variant
    @product = @product_variant.product
  end
  
  # GET /inventory/adjustments/new
  def new
    @adjustment = InventoryAdjustment.new
    @product_variant = ProductVariant.find(params[:product_variant_id]) if params[:product_variant_id]
    @products = Product.includes(:product_variants).active.order(:name)
  end
  
  # GET /inventory/adjustments/1/edit
  def edit
    unless @adjustment.approved?
      @products = Product.includes(:product_variants).active.order(:name)
    else
      redirect_to @adjustment, alert: 'Cannot edit approved adjustments.'
    end
  end
  
  # POST /inventory/adjustments
  def create
    @adjustment = InventoryAdjustment.new(adjustment_params)
    # @adjustment.user = current_user if respond_to?(:current_user)
    
    if @adjustment.save
      if @adjustment.requires_approval?
        redirect_to @adjustment, notice: 'Adjustment created and sent for approval.'
      else
        @adjustment.approve!(nil) # Auto-approve if not required
        redirect_to @adjustment, notice: 'Inventory adjustment applied successfully.'
      end
    else
      @products = Product.includes(:product_variants).active.order(:name)
      render :new, status: :unprocessable_entity
    end
  end
  
  # PATCH/PUT /inventory/adjustments/1
  def update
    if @adjustment.approved?
      redirect_to @adjustment, alert: 'Cannot modify approved adjustments.'
      return
    end
    
    if @adjustment.update(adjustment_params)
      redirect_to @adjustment, notice: 'Adjustment was successfully updated.'
    else
      @products = Product.includes(:product_variants).active.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end
  
  # DELETE /inventory/adjustments/1
  def destroy
    if @adjustment.approved?
      redirect_to @adjustment, alert: 'Cannot delete approved adjustments.'
    else
      @adjustment.destroy!
      redirect_to inventory_adjustments_url, notice: 'Adjustment was successfully deleted.'
    end
  end
  
  # GET /inventory/adjustments/summary
  def summary
    start_date = params[:start_date]&.to_date || 30.days.ago
    end_date = params[:end_date]&.to_date || Date.current
    
    @adjustments_by_type = InventoryAdjustment.by_date_range(start_date, end_date)
                                             .total_adjustments_by_type
    
    @cost_impact_by_type = InventoryAdjustment.by_date_range(start_date, end_date)
                                             .total_cost_impact_by_type
    
    @top_adjusted_products = Product.joins(product_variants: :inventory_adjustments)
                                   .where(inventory_adjustments: { created_at: start_date..end_date })
                                   .group('products.name')
                                   .sum('inventory_adjustments.quantity')
                                   .sort_by { |_, qty| -qty.abs }
                                   .first(10)
    
    @recent_large_adjustments = InventoryAdjustment.by_date_range(start_date, end_date)
                                                  .where('ABS(quantity) > ?', 50)
                                                  .includes(:product_variant, :user)
                                                  .recent
                                                  .limit(20)
    
    respond_to do |format|
      format.html
      format.json do
        render json: {
          adjustments_by_type: @adjustments_by_type,
          cost_impact_by_type: @cost_impact_by_type,
          top_adjusted_products: @top_adjusted_products,
          recent_large_adjustments: @recent_large_adjustments.as_json(include: [:product_variant, :user])
        }
      end
    end
  end
  
  # POST /inventory/adjustments/bulk_create
  def bulk_create
    adjustments_data = params[:adjustments] || []
    created_adjustments = []
    errors = []
    
    adjustments_data.each_with_index do |adj_params, index|
      adjustment = InventoryAdjustment.new(adj_params.permit(:product_variant_id, :adjustment_type, :quantity, :reason, :notes))
      # adjustment.user = current_user if respond_to?(:current_user)
      
      if adjustment.save
        created_adjustments << adjustment
        adjustment.approve!(nil) unless adjustment.requires_approval?
      else
        errors << { index: index, errors: adjustment.errors.full_messages }
      end
    end
    
    if errors.empty?
      redirect_to inventory_adjustments_path, notice: "Successfully created #{created_adjustments.count} adjustments."
    else
      flash[:alert] = "Created #{created_adjustments.count} adjustments with #{errors.count} errors."
      redirect_to inventory_adjustments_path
    end
  end
  
  private
  
  def set_adjustment
    @adjustment = InventoryAdjustment.find(params[:id])
  end
  
  def adjustment_params
    params.require(:inventory_adjustment).permit(
      :product_variant_id, :adjustment_type, :quantity, :reason, :notes,
      :reference_number, :cost_impact, metadata: {}
    )
  end
end