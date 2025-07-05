require "faraday"

class WahaClient
  class Error < StandardError; end

  def initialize(base_url: ENV.fetch("WAHA_BASE_URL", "http://waha:3000/api"))
    @conn = Faraday.new(url: base_url) do |f|
      f.request :json
      f.response :json, parser_options: { symbolize_names: true }
      f.adapter Faraday.default_adapter
    end
  end

  def send_text(phone_number:, text:, session: "default")
    post("/sendText", {
      chatId: "#{phone_number}@c.us",
      text: text,
      session: session
    })
  end

  def start_session(name: "default")
    post("/sessions", { name: name })
  end

  def screenshot(session: "default")
    @conn.get("/screenshot", { session: session }).body
  end

  # Returns raw QR string (data used to generate QR)
  def qr_data(session: "default")
    res = @conn.get("/qr", { session: session })
    raise Error, "QR not ready" unless res.success?
    res.body[:qr] || res.body
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