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
end
