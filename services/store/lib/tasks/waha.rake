require "base64"

namespace :waha do
  desc "Start WAHA session and save QR screenshot to file (usage: rake waha:pair[session_name])"
  task :pair, [:session] => :environment do |_, args|
    session = args[:session] || "default"

    puts "Starting WAHA session '#{session}'..."
    begin
      WAHA.start_session(name: session)
    rescue WahaClient::Error => e
      puts "Warning: #{e.message} (continuing to fetch QR)"
    end

    img_data = WAHA.screenshot(session: session)
    file_path = Rails.root.join("waha_qr_#{session}.png")
    File.binwrite(file_path, img_data)
    puts "QR code saved to #{file_path}. Open this image and scan it with WhatsApp → Linked devices."
  end

  desc "Sync chats overview for all WAHA sessions and update last_message_at (usage: rake waha:sync_chats_overview)"
  task :sync_chats_overview => :environment do
    puts "Fetching chats overview from WAHA for all sessions..."
    WahaSession.find_each do |session|
      begin
        session.sync_chats_overview!
        puts " → Synced session '#{session.name}'"
      rescue StandardError => e
        warn " ! Failed to sync session '#{session.name}': #{e.message}"
      end
    end
    puts "Done."
  end
end