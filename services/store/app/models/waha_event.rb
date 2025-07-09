class WahaEvent < ApplicationRecord
  after_create_commit -> { broadcast_prepend_later_to "waha_events", partial: "waha_events/event", locals: { event: self }, target: "events_list" }

  def pretty_time
    created_at.strftime("%H:%M:%S")
  end
end