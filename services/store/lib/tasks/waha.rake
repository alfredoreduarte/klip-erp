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
end