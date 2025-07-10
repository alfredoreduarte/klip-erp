module ApplicationHelper
  def auto_scroll_frame
    tag.script <<~JS.html_safe
      document.addEventListener("turbo:load", () => {
        const frame = document.getElementById("messages_scroller");
        if (frame) frame.scrollTop = frame.scrollHeight;
      });
    JS
  end
end
