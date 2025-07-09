class Shipment < ApplicationRecord
  belongs_to :order
  
  validates :tracking_number, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[pending picked_up in_transit delivered failed] }
  validates :cost, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :weight, numericality: { greater_than: 0 }, allow_nil: true
  validates :weight_unit, inclusion: { in: %w[kg g lb oz] }
  
  scope :pending, -> { where(status: 'pending') }
  scope :picked_up, -> { where(status: 'picked_up') }
  scope :in_transit, -> { where(status: 'in_transit') }
  scope :delivered, -> { where(status: 'delivered') }
  scope :failed, -> { where(status: 'failed') }
  scope :by_carrier, ->(carrier) { where(carrier_name: carrier) }
  
  def pending?
    status == 'pending'
  end
  
  def picked_up?
    status == 'picked_up'
  end
  
  def in_transit?
    status == 'in_transit'
  end
  
  def delivered?
    status == 'delivered'
  end
  
  def failed?
    status == 'failed'
  end
  
  def transit_time
    return nil unless shipped_at && delivered_at
    
    ((delivered_at - shipped_at) / 1.day).round(1)
  end
  
  def add_tracking_event(event_type, description, location = nil)
    events = tracking_events || []
    events << {
      timestamp: Time.current,
      event_type: event_type,
      description: description,
      location: location
    }
    
    update!(tracking_events: events)
  end
  
  def mark_as_shipped!
    update!(status: 'in_transit', shipped_at: Time.current)
    add_tracking_event('shipped', 'Package shipped')
  end
  
  def mark_as_delivered!
    update!(status: 'delivered', delivered_at: Time.current)
    add_tracking_event('delivered', 'Package delivered')
    order.mark_as_delivered!
  end
end