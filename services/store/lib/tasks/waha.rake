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

  desc "Download media for existing messages that have media but no cached files (usage: rake waha:download_media)"
  task :download_media => :environment do
    puts "Finding messages with media that need downloading..."

    # Find messages with media URLs but no cached media files
    messages_with_media = Message.where("payload->>'mediaUrl' IS NOT NULL OR payload->'media'->>'url' IS NOT NULL")

    puts "Found #{messages_with_media.count} messages with media URLs"

    downloaded_count = 0
    failed_count = 0

    messages_with_media.find_each do |message|
      next if message.media_files.any? # Skip if already downloaded

      begin
        DownloadMediaJob.perform_now(message.id)
        downloaded_count += 1
        print "." if downloaded_count % 10 == 0
      rescue => e
        failed_count += 1
        puts "\nFailed to download media for message #{message.id}: #{e.message}"
      end
    end

    puts "\nDownloaded: #{downloaded_count}, Failed: #{failed_count}"
    puts "Done."
  end
end