require "faraday"
require "cgi"

class WahaClient
  class Error < StandardError; end

  def initialize(base_url: ENV.fetch("WAHA_BASE_URL", "http://localhost:4000"))
    @conn = Faraday.new(url: base_url) do |f|
      f.request :json
      f.response :json, parser_options: { symbolize_names: true }
      f.adapter Faraday.default_adapter
    end
  end

  def send_text(phone_number:, text:, session: "default")
    post("/api/sendText", {
      chatId: "#{phone_number}@c.us",
      text: text,
      session: session
    })
  end

  # Create (or update) and start a WAHA session.
  #
  # The WAHA API allows including `start: true` in the payload when creating a
  # new session so that the session is started immediately.  For an existing
  # session we update the configuration (to ensure webhook + metadata are up to
  # date) and then explicitly restart it.
  #
  # Params
  # - name:        the WAHA session name
  # - metadata:    optional additional metadata to persist with the session
  #                (e.g. { "store.id" => 1 })
  # - webhook_url: URL that WAHA should POST events to (defaults to
  #                WAHA_WEBHOOK_URL env var or Rails host)
  def start_session(name: "default", metadata: {}, webhook_url: ENV.fetch("WAHA_WEBHOOK_URL", "http://store:3000/waha/webhooks"))
    payload = {
      name: name,
      start: true,
      config: {
        webhooks: [
          {
            url: webhook_url,
            events: ["message"]
          }
        ],
        metadata: metadata.presence
      }.compact
    }

    begin
      # Try to create and autostart the session.
      post("/api/sessions", payload)
    rescue Error
      # If it already exists, update configuration then restart.
      begin
        put("/api/sessions/#{name}", payload.except(:start))
      rescue Error
        # Ignore – maybe config didn't change.
      ensure
        post("/api/sessions/#{name}/restart", {})
      end
    end
  end

  def screenshot(session: "default")
    @conn.get("/api/screenshot", { session: session }).body
  end

  # Fetch current QR code for the given WAHA session.
  # Returns PNG binary data (format=image) so callers can stream or base64-encode it.
  # If you need the raw string value, pass format: "raw".
  def qr(session: "default", format: "image")
    headers = {}
    headers["Accept"] = "image/png" if format == "image"

    res = @conn.get("/api/#{session}/auth/qr", { format: format }, headers)

    raise Error, "WAHA error: #{res.status} #{res.body}" unless res.success?

    res.body
  rescue Faraday::Error => e
    raise Error, e.message
  end

  def delete_session(name: "default")
    res = @conn.delete("/api/sessions/#{name}")
    raise Error, "WAHA error: #{res.status} #{res.body}" unless res.success?

    res.body
  rescue Faraday::Error => e
    raise Error, e.message
  end

  def start_typing(phone_number:, session: "default")
    post("/api/startTyping", {
      chatId: "#{phone_number}@c.us",
      session: session
    })
  end

  # Inform WAHA that typing has stopped for the given chat.
  # According to WAHA docs this resets the presence status back to "available".
  def stop_typing(phone_number:, session: "default")
    post("/api/stopTyping", {
      chatId: "#{phone_number}@c.us",
      session: session
    })
  end

  # Fetch contact profile picture.
  # Returns a hash with key :picture (may be nil if not available).
  # WAHA endpoint: GET /api/contacts/profile-picture?contactId={wa_id}
  def contact_profile_picture(wa_id:, session: "default")
    res = @conn.get("/api/contacts/profile-picture", { contactId: wa_id })
    raise Error, "WAHA error: #{res.status} #{res.body}" unless res.success?

    # WAHA returns { profilePictureURL: "url" } or { profilePictureURL: null }
    picture_url = res.body[:profilePictureURL]

    { picture: picture_url }
  rescue Faraday::Error => e
    raise Error, e.message
  end

  private

  def post(path, payload)
    res = @conn.post(path, payload)
    raise Error, "WAHA error: #{res.status} #{res.body}" unless res.success?

    res.body
  rescue Faraday::Error => e
    raise Error, e.message
  end

  def put(path, payload)
    res = @conn.put(path, payload)
    raise Error, "WAHA error: #{res.status} #{res.body}" unless res.success?

    res.body
  rescue Faraday::Error => e
    raise Error, e.message
  end
end