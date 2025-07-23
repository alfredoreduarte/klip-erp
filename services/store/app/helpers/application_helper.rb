module ApplicationHelper
  require 'uri'

  def auto_scroll_frame
    tag.script <<~JS.html_safe
      (() => {
        const findScrollable = () => {
          // The turbo-frame containing messages is the scrollable element
          const frame = document.querySelector('turbo-frame[id$="_messages"]');
          if (frame) return frame;
          // Fallback to inner div (older logic)
          return document.getElementById("messages_scroller");
        };

        const scrollToBottom = (el = findScrollable()) => {
          if (el) el.scrollTop = el.scrollHeight;
        };

        // Initial call in case event already fired before script was parsed
        scrollToBottom();

        // When the full page (Turbo visit) finishes loading
        document.addEventListener("turbo:load", () => scrollToBottom());

        // When the messages turbo-frame updates (e.g., new message append)
        document.addEventListener("turbo:frame-load", (event) => {
          if (event.target && event.target.id && event.target.id.endsWith("_messages")) {
            scrollToBottom(event.target);
          }
        });
      })();
    JS
  end

  # Fallback auto_link implementation (Rails 7 removed built-in helper)
  # Converts URLs in plain text into clickable links.
  def auto_link(text, html: {})
    return "" if text.blank?

    attributes = html.map { |k, v| %(#{k}="#{ERB::Util.html_escape(v)}") }.join(" ")
    pattern = URI.regexp(%w[http https])

    text.gsub(pattern) do |url|
      %(<a href="#{ERB::Util.html_escape(url)}" #{attributes} target="_blank">#{ERB::Util.html_escape(url)}</a>)
    end.html_safe
  end

  # Formats a timestamp in WhatsApp-like style for chat lists
  # Today: HH:MM
  # Yesterday: 'Yesterday'
  # Within last week: weekday name (e.g., Thursday)
  # Older: 'Month Day' (e.g., May 1st)
  def whatsapp_chat_timestamp(time)
    return "" unless time
    now = Time.zone.now
    if time.to_date == now.to_date
      time.strftime("%H:%M")
    elsif time.to_date == (now.to_date - 1)
      "Yesterday"
    elsif time > now.beginning_of_week
      time.strftime("%A")
    else
      time.strftime("%b #{time.day.ordinalize}")
    end
  end

  def icon(name, **options)
    lucide_icon(name, **options)
  end

  # Construct proper WAHA file URL from media URL
  def waha_file_url(media_url)
    return nil if media_url.blank?

    # Extract filename from the media URL
    # WAHA URLs are typically like: http://localhost:3000/api/files/false_11111111111@c.us_AAAAAAAAAAAAAAAAAAAA.oga
    # or they might include session name like: http://localhost:3000/api/files/default/false_11111111111@c.us_AAAAAAAAAAAAAAAAAAAA.oga

    # Remove the base URL and get the path
    uri = URI(media_url)
    path = uri.path

    # Remove /api/files/ prefix and any session name
    file_path = path.gsub(/^\/api\/files\/[^\/]+\//, '').gsub(/^\/api\/files\//, '')

    # Construct the correct URL for our proxy
    "/api/files/#{file_path}"
  end
end
