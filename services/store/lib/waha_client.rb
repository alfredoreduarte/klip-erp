require "faraday"

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

  # Starts (or creates if it does not yet exist) a WAHA session.
  # According to WAHA API docs, the correct endpoint is
  # POST /api/sessions/:name/start
  # See error message returned by WAHA when calling /api/screenshot
  #   "We didn't find a session with name 'default'. Please start it first by using POST /api/sessions/default/start request"
  # We therefore call that endpoint directly and do not send any body payload.
  def start_session(name: "default")
    webhook_url = ENV.fetch("WAHA_WEBHOOK_URL", "http://store:3000/waha/webhooks")

    # Ensure the session has our webhook configured. We try to create or update
    # the session with the webhook configuration first, then start (or
    # restart) it.
    config_payload = {
      name: name,
      config: {
        webhooks: [
          {
            url: webhook_url,
            events: ["message"]
          }
        ]
      }
    }

    begin
      # Create session if it doesn't exist yet
      post("/api/sessions", config_payload)
    rescue Error => e
      # If already exists, update it to make sure webhook is set
      begin
        put("/api/sessions/#{name}", config_payload)
      rescue Error
        # Swallow – we'll still attempt to (re)start below
      end
    end

    # Finally start (or restart) the session so WAHA picks up the new config
    post("/api/sessions/#{name}/start", {})
  end

  def screenshot(session: "default")
    @conn.get("/api/screenshot", { session: session }).body
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