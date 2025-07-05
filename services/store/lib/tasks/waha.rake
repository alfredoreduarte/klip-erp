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

    begin
      qr_string = WAHA.qr_data(session: session)
      qrcode = RQRCode::QRCode.new(qr_string)
      puts qrcode.as_ansi(module_size: 1)
      puts "Scan the above QR with WhatsApp → Linked devices."
    rescue WahaClient::Error => e
      puts "Could not fetch QR: #{e.message}. Falling back to screenshot..."
      img_data = WAHA.screenshot(session: session)
      file_path = Rails.root.join("waha_qr_#{session}.png")
      File.binwrite(file_path, img_data)
      puts "QR code saved to #{file_path}. Open this image and scan it."
    end
  end
end