class MarketingCampaign < ApplicationRecord
  has_many :order_attributions, dependent: :destroy
  has_many :orders, through: :order_attributions
  
  validates :name, presence: true
  validates :platform, inclusion: { in: %w[facebook instagram google tiktok twitter] }
  validates :campaign_id, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[active paused completed cancelled] }
  validates :budget, :spent, :cost_per_click, :cost_per_conversion, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :impressions, :clicks, :conversions, numericality: { greater_than_or_equal_to: 0 }
  
  scope :active, -> { where(status: 'active') }
  scope :paused, -> { where(status: 'paused') }
  scope :completed, -> { where(status: 'completed') }
  scope :cancelled, -> { where(status: 'cancelled') }
  scope :by_platform, ->(platform) { where(platform: platform) }
  scope :running, -> { where(status: 'active').where('start_date <= ? AND (end_date IS NULL OR end_date >= ?)', Date.current, Date.current) }
  
  def active?
    status == 'active'
  end
  
  def paused?
    status == 'paused'
  end
  
  def completed?
    status == 'completed'
  end
  
  def cancelled?
    status == 'cancelled'
  end
  
  def running?
    active? && (start_date.nil? || start_date <= Date.current) && (end_date.nil? || end_date >= Date.current)
  end
  
  def click_through_rate
    return 0 if impressions == 0
    
    (clicks.to_f / impressions * 100).round(2)
  end
  
  def conversion_rate
    return 0 if clicks == 0
    
    (conversions.to_f / clicks * 100).round(2)
  end
  
  def return_on_ad_spend
    return 0 if spent == 0
    
    total_revenue = orders.sum(:total_amount)
    (total_revenue / spent).round(2)
  end
  
  def cost_per_acquisition
    return 0 if conversions == 0
    
    (spent / conversions).round(2)
  end
  
  def total_orders
    orders.count
  end
  
  def total_revenue
    orders.sum(:total_amount)
  end
  
  def profit
    total_revenue - spent
  end
  
  def profit_margin
    return 0 if total_revenue == 0
    
    (profit / total_revenue * 100).round(2)
  end
  
  def days_running
    return 0 unless start_date
    
    end_date_or_today = end_date || Date.current
    (end_date_or_today - start_date).to_i
  end
  
  def daily_spend
    return 0 if days_running == 0
    
    spent / days_running
  end
  
  def update_metrics!(metrics)
    update!(
      impressions: metrics[:impressions] || impressions,
      clicks: metrics[:clicks] || clicks,
      spent: metrics[:spent] || spent,
      conversions: metrics[:conversions] || conversions,
      cost_per_click: metrics[:cost_per_click] || cost_per_click,
      cost_per_conversion: metrics[:cost_per_conversion] || cost_per_conversion,
      performance_metrics: performance_metrics.merge(metrics[:performance_metrics] || {})
    )
  end
end