Rails.application.config.to_prepare do
  WAHA = WahaClient.new
end