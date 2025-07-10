class OrderAttribution < ApplicationRecord
  belongs_to :order
  belongs_to :marketing_campaign
  
  validates :attribution_type, inclusion: { in: %w[first_click last_click linear time_decay] }
  validates :attribution_weight, numericality: { greater_than: 0, less_than_or_equal_to: 1 }
  validates :attributed_revenue, :attributed_cost, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  
  scope :first_click, -> { where(attribution_type: 'first_click') }
  scope :last_click, -> { where(attribution_type: 'last_click') }
  scope :linear, -> { where(attribution_type: 'linear') }
  scope :time_decay, -> { where(attribution_type: 'time_decay') }
  scope :by_campaign, ->(campaign_id) { where(marketing_campaign_id: campaign_id) }
  scope :by_utm_source, ->(source) { where(utm_source: source) }
  scope :by_utm_campaign, ->(campaign) { where(utm_campaign: campaign) }
  
  def first_click?
    attribution_type == 'first_click'
  end
  
  def last_click?
    attribution_type == 'last_click'
  end
  
  def linear?
    attribution_type == 'linear'
  end
  
  def time_decay?
    attribution_type == 'time_decay'
  end
  
  def time_to_conversion
    return nil unless click_timestamp && conversion_timestamp
    
    ((conversion_timestamp - click_timestamp) / 1.hour).round(2)
  end
  
  def attribution_efficiency
    return 0 if attributed_cost == 0
    
    (attributed_revenue / attributed_cost).round(2)
  end
  
  def utm_params
    {
      utm_source: utm_source,
      utm_medium: utm_medium,
      utm_campaign: utm_campaign,
      utm_term: utm_term,
      utm_content: utm_content
    }.compact
  end
  
  def attribution_summary
    "#{attribution_type.humanize} (#{(attribution_weight * 100).round(1)}%)"
  end
end