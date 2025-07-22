class SourcingOrdersController < ApplicationController
  before_action :set_sourcing_order, only: [:show, :edit, :update, :destroy, :submit, :approve, :receive, :cancel]
  
  # GET /sourcing
  def index
    @sourcing_orders = SourcingOrder.includes(:sourcing_order_items)
                                   .page(params[:page])
                                   .per(20)
                                   .order(created_at: :desc)
    
    # Filters
    @sourcing_orders = @sourcing_orders.where(status: params[:status]) if params[:status].present?
    @sourcing_orders = @sourcing_orders.where(supplier_name: params[:supplier]) if params[:supplier].present?
    
    # Status counts for dashboard
    @pending_count = SourcingOrder.where(status: 'draft').count
    @submitted_count = SourcingOrder.where(status: 'submitted').count
    @approved_count = SourcingOrder.where(status: 'approved').count
    @received_count = SourcingOrder.where(status: 'received').count
    
    @suppliers = SourcingOrder.distinct.pluck(:supplier_name).compact.sort
  end
  
  # GET /sourcing/pending
  def pending
    @sourcing_orders = SourcingOrder.where(status: 'submitted')
                                   .includes(:sourcing_order_items)
                                   .order(created_at: :asc)
    render :index
  end
  
  # GET /sourcing/approved
  def approved
    @sourcing_orders = SourcingOrder.where(status: 'approved')
                                   .includes(:sourcing_order_items)
                                   .order(created_at: :asc)
    render :index
  end
  
  # GET /sourcing/received
  def received
    @sourcing_orders = SourcingOrder.where(status: 'received')
                                   .includes(:sourcing_order_items)
                                   .order(received_date: :desc)
    render :index
  end
  
  # GET /sourcing/1
  def show
    @items = @sourcing_order.sourcing_order_items.includes(:product_variant)
    @total_items = @items.sum(:quantity)
    @total_cost = @items.sum { |item| (item.quantity || 0) * (item.unit_cost || 0) }
    @can_approve = @sourcing_order.status == 'submitted'
    @can_receive = @sourcing_order.status == 'approved'
  end
  
  # GET /sourcing/new
  def new
    @sourcing_order = SourcingOrder.new
    @sourcing_order.sourcing_order_items.build
    @low_stock_variants = ProductVariant.joins(:product)
                                       .where(products: { track_inventory: true })
                                       .low_stock(10)
                                       .includes(:product)
                                       .order('inventory_quantity ASC')
                                       .limit(20)
    @products = Product.includes(:product_variants).active.order(:name)
  end
  
  # GET /sourcing/1/edit
  def edit
    if @sourcing_order.status != 'draft'
      redirect_to @sourcing_order, alert: 'Can only edit draft orders.'
      return
    end
    @products = Product.includes(:product_variants).active.order(:name)
  end
  
  # POST /sourcing
  def create
    @sourcing_order = SourcingOrder.new(sourcing_order_params)
    @sourcing_order.status = 'draft'
    @sourcing_order.order_date = Date.current
    
    if @sourcing_order.save
      redirect_to @sourcing_order, notice: 'Sourcing order was successfully created.'
    else
      @products = Product.includes(:product_variants).active.order(:name)
      render :new, status: :unprocessable_entity
    end
  end
  
  # PATCH/PUT /sourcing/1
  def update
    if @sourcing_order.status != 'draft'
      redirect_to @sourcing_order, alert: 'Can only edit draft orders.'
      return
    end
    
    if @sourcing_order.update(sourcing_order_params)
      redirect_to @sourcing_order, notice: 'Sourcing order was successfully updated.'
    else
      @products = Product.includes(:product_variants).active.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end
  
  # DELETE /sourcing/1
  def destroy
    if @sourcing_order.status == 'draft'
      @sourcing_order.destroy!
      redirect_to sourcing_orders_url, notice: 'Sourcing order was successfully deleted.'
    else
      redirect_to @sourcing_order, alert: 'Cannot delete submitted orders.'
    end
  end
  
  # PATCH /sourcing/1/submit
  def submit
    if @sourcing_order.status == 'draft' && @sourcing_order.sourcing_order_items.any?
      @sourcing_order.update!(status: 'submitted', submitted_date: Date.current)
      redirect_to @sourcing_order, notice: 'Order submitted for approval.'
    else
      redirect_to @sourcing_order, alert: 'Cannot submit order.'
    end
  end
  
  # PATCH /sourcing/1/approve
  def approve
    if @sourcing_order.status == 'submitted'
      @sourcing_order.update!(status: 'approved', approved_date: Date.current)
      redirect_to @sourcing_order, notice: 'Order approved successfully.'
    else
      redirect_to @sourcing_order, alert: 'Cannot approve order.'
    end
  end
  
  # PATCH /sourcing/1/receive
  def receive
    if @sourcing_order.status == 'approved'
      @sourcing_order.transaction do
        # Create inventory lots for each item
        @sourcing_order.sourcing_order_items.each do |item|
          lot = item.product_variant.inventory_lots.create!(
            quantity_received: item.quantity,
            quantity_remaining: item.quantity,
            unit_cost: item.unit_cost,
            total_cost: item.quantity * item.unit_cost,
            received_date: Date.current,
            supplier_name: @sourcing_order.supplier_name,
            purchase_order_number: @sourcing_order.order_number,
            status: 'active'
          )
          
          # Create inventory adjustment record
          InventoryAdjustment.create!(
            product_variant: item.product_variant,
            adjustment_type: 'purchase',
            quantity: item.quantity,
            reason: "Purchase receipt from #{@sourcing_order.supplier_name}",
            reference_number: @sourcing_order.order_number,
            cost_impact: item.quantity * item.unit_cost,
            approved: true,
            approved_at: Time.current
          )
        end
        
        @sourcing_order.update!(status: 'received', received_date: Date.current)
      end
      
      redirect_to @sourcing_order, notice: 'Order received and inventory updated.'
    else
      redirect_to @sourcing_order, alert: 'Cannot receive order.'
    end
  end
  
  # PATCH /sourcing/1/cancel
  def cancel
    if ['draft', 'submitted'].include?(@sourcing_order.status)
      @sourcing_order.update!(status: 'cancelled', cancelled_date: Date.current)
      redirect_to @sourcing_order, notice: 'Order cancelled.'
    else
      redirect_to @sourcing_order, alert: 'Cannot cancel order.'
    end
  end
  
  private
  
  def set_sourcing_order
    @sourcing_order = SourcingOrder.find(params[:id])
  end
  
  def sourcing_order_params
    params.require(:sourcing_order).permit(
      :supplier_name, :supplier_email, :supplier_phone, :supplier_address,
      :order_number, :notes, :expected_delivery_date,
      sourcing_order_items_attributes: [
        :id, :product_variant_id, :quantity, :unit_cost, :notes, :_destroy
      ]
    )
  end
end