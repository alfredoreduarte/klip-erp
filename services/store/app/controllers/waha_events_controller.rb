class WahaEventsController < ApplicationController
  def index
    @events = WahaEvent.order(created_at: :desc).limit(200)
  end
end