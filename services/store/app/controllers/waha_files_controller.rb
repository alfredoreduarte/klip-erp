class WahaFilesController < ApplicationController
  # Proxy file requests to WAHA service
  def proxy
    # Extract the path from the request (this includes session name if present)
    file_path = params[:path]

    Rails.logger.info "Proxying file request: #{file_path}"

    begin
      # Make request to WAHA using Faraday
      conn = Faraday.new(url: "http://waha:3000") do |f|
        f.response :logger, Rails.logger, { headers: false, bodies: false }
      end

      response = conn.get("/api/files/#{file_path}")

      Rails.logger.info "WAHA response status: #{response.status}"

      if response.success?
        # Forward the response headers properly
        response.headers.each do |name, value|
          next if name.downcase == 'transfer-encoding'
          response.headers[name] = value
        end

        # Send the file content with proper content type
        content_type = response.headers['content-type'] || 'application/octet-stream'

        send_data response.body,
                  type: content_type,
                  disposition: 'inline',
                  filename: File.basename(file_path)
      else
        Rails.logger.warn "File not found on WAHA: #{file_path} (Status: #{response.status})"
        Rails.logger.warn "This is expected behavior for WAHA free version - files are temporarily stored and cleaned up"
        render plain: 'File not available (temporarily stored media)', status: :not_found
      end
    rescue => e
      Rails.logger.error "Error proxying file request: #{e.message}"
      render plain: 'Error serving file', status: :internal_server_error
    end
  end
end