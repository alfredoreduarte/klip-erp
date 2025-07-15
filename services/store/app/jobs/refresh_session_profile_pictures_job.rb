class RefreshSessionProfilePicturesJob < ApplicationJob
  queue_as :default

  def perform
    WahaSession.find_each do |session|
      begin
        session.refresh_profile_picture!
        Rails.logger.info "Refreshed profile picture for session: #{session.name}"
      rescue => e
        Rails.logger.error "Failed to refresh profile picture for session #{session.name}: #{e.message}"
      end
    end
  end
end
