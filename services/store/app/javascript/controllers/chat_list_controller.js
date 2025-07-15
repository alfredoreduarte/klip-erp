import { Controller } from "@hotwired/stimulus";

// Keeps the "active" class on the chat that matches the current URL.
// This is needed because Turbo stream broadcasts re-render list items and
// the server-rendered partial cannot know which chat is currently open
// in each individual browser tab.
export default class extends Controller {
  static targets = ["item"];

  connect() {
    // Highlight immediately when the controller connects
    this.highlightActive();

    // Ensure we update the highlight after any Turbo Stream renders
    document.addEventListener("turbo:before-stream-render", this.handleStream);

    // Listen for navigation events to update active state
    document.addEventListener("turbo:load", this.handleNavigation);
    document.addEventListener("turbo:render", this.handleNavigation);
  }

  disconnect() {
    document.removeEventListener(
      "turbo:before-stream-render",
      this.handleStream
    );
    document.removeEventListener("turbo:load", this.handleNavigation);
    document.removeEventListener("turbo:render", this.handleNavigation);
  }

  handleStream = () => {
    // Wait till DOM update finished, then add a small delay to ensure
    // the new elements are fully rendered
    requestAnimationFrame(() => {
      // Add a small delay to ensure DOM is fully updated
      setTimeout(() => {
        this.highlightActive();
      }, 50);
    });
  };

  handleNavigation = () => {
    this.highlightActive();
  };

  highlightActive() {
    const currentPath = window.location.pathname;

    // Query for all chat list items in the current controller's scope
    const chatItems = Array.from(
      this.element.querySelectorAll('[data-chat-list-target="item"]')
    );

    chatItems.forEach((el) => {
      const href = el.getAttribute("href");
      if (href === currentPath) {
        el.classList.add("active");
        // Ensure the active element is visible by scrolling if needed
        if (!this.isElementVisible(el)) {
          el.scrollIntoView({ behavior: "smooth", block: "nearest" });
        }
      } else {
        el.classList.remove("active");
      }
    });
  }

  isElementVisible(element) {
    const rect = element.getBoundingClientRect();
    const containerRect = this.element.getBoundingClientRect();

    return rect.top >= containerRect.top && rect.bottom <= containerRect.bottom;
  }
}
