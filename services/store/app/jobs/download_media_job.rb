class DownloadMediaJob < ApplicationJob
  queue_as :default

  def perform(message_id)
    puts "[DEBUG] DownloadMediaJob: Starting download for message \\#{message_id}"
    message = Message.find(message_id)
    Rails.logger.info "DownloadMediaJob: Starting download for message #{message_id}"

    # Extract media URL from message payload
    media_url = extract_media_url(message.payload)
    puts "[DEBUG] Extracted media URL: \\#{media_url}"
    Rails.logger.info "DownloadMediaJob: Extracted media URL: #{media_url}"

    unless media_url.present?
      puts "[DEBUG] No media URL found, returning."
      return
    end

    Rails.logger.info "Downloading media for message #{message_id}: #{media_url}"

    begin
      # Download media from WAHA
      conn = Faraday.new(url: "http://waha:3000") do |f|
        f.response :logger, Rails.logger, { headers: false, bodies: false }
      end

      # Extract the file path from the URL (including session name if present)
      uri = URI(media_url)
      file_path = uri.path.gsub(/^\/api\/files\//, '')

      Rails.logger.info "Requesting file from WAHA: /api/files/#{file_path}"
      response = conn.get("/api/files/#{file_path}")

      Rails.logger.info "WAHA response status: #{response.status}"

      if response.success?
        puts "[DEBUG] WAHA response success, status: \\#{response.status}"
        # Create media file record
        filename = File.basename(file_path)
        media_file = message.media_files.find_or_initialize_by(filename: filename)
        media_file.mimetype = response.headers['content-type'] || 'application/octet-stream'

        Rails.logger.info "Saving media file: #{filename} (#{media_file.mimetype})"

        # Attach the file using Active Storage
        media_file.file.attach(
          io: StringIO.new(response.body),
          filename: filename,
          content_type: media_file.mimetype
        )

        media_file.save!
        puts "[DEBUG] Successfully downloaded and stored media for message \\#{message_id}"
        Rails.logger.info "Successfully downloaded and stored media for message #{message_id}"
      else
        puts "[DEBUG] WAHA response failed, status: \\#{response.status}"
        Rails.logger.warn "Failed to download media for message #{message_id}: HTTP #{response.status}"
        Rails.logger.warn "Response body: #{response.body}"
      end
    rescue => e
      puts "[DEBUG] Exception: \\#{e.message}"
      Rails.logger.error "Error downloading media for message #{message_id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end

  private

  def extract_media_url(payload)
    # Try different possible locations for media URL
    payload['mediaUrl'] ||
    payload.dig('media', 'url') ||
    payload['url'] ||
    payload['media_url']
  end
end
