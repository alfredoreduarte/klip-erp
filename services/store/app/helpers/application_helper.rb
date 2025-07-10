module ApplicationHelper
  require 'uri'

  def auto_scroll_frame
    tag.script <<~JS.html_safe
      document.addEventListener("turbo:load", () => {
        const frame = document.getElementById("messages_scroller");
        if (frame) frame.scrollTop = frame.scrollHeight;
      });
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
end
