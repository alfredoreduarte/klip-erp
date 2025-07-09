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
end