class Chat < ApplicationRecord
  has_many :messages, dependent: :destroy
  has_many :carts, dependent: :destroy
  belongs_to :waha_session, optional: true

  validates :wa_id, presence: true, uniqueness: true

  scope :non_broadcast, -> { where.not(wa_id: "status@broadcast") }
  scope :pinned, -> { where.not(pinned_at: nil) }
  scope :unpinned, -> { where(pinned_at: nil) }

  # Update last_message_at whenever a message is created
  def touch_last_message!(time = Time.current)
    update_column(:last_message_at, time)
  end

  # Pin the chat to the top
  def pin!
    update_column(:pinned_at, Time.current)
    broadcast_list_item
  end

  # Unpin the chat
  def unpin!
    update_column(:pinned_at, nil)
    broadcast_list_item
  end

  # Check if chat is pinned
  def pinned?
    pinned_at.present?
  end

  # Get pinned messages for this chat
  def pinned_messages
    messages.pinned.order(pinned_at: :desc)
  end

  # Sync pin states for all messages in this chat
  def sync_pin_states!
    session_name = waha_session&.name || "default"

    begin
      # Fetch all messages from WAHA to check pin states
      waha_messages = WahaClient.new.chat_messages(
        chat_id: wa_id,
        session: session_name,
        limit: 100
      )

      # Create a map of message IDs to their pin state
      pin_states = {}
      waha_messages.each do |msg|
        message_id = msg["id"]
        is_pinned = msg["pinned"] || msg["pinInfo"]&.present?
        pin_states[message_id] = is_pinned
      end

      # Update local messages based on WAHA state
      messages.find_each do |message|
        waha_pin_state = pin_states[message.wa_message_id]
        next if waha_pin_state.nil? # Message not found in WAHA response

        if waha_pin_state && !message.pinned?
          # Message is pinned in WAHA but not locally
          message.update_column(:pinned_at, Time.current)
          message.broadcast_replace_later_to self, target: "message_#{message.id}", partial: "messages/message", locals: { message: message }
        elsif !waha_pin_state && message.pinned?
          # Message is not pinned in WAHA but is locally
          message.update_column(:pinned_at, nil)
          message.broadcast_replace_later_to self, target: "message_#{message.id}", partial: "messages/message", locals: { message: message }
        end
      end
    rescue WahaClient::Error => e
      Rails.logger.error "Failed to sync pin states for chat #{id}: #{e.message}"
      # Don't raise - this is a sync operation, not critical
    end
  end

  # Get sort order for chat list (pinned first, then by latest message)
  def sort_order
    if pinned?
      [1, pinned_at] # Pinned chats first, sorted by pin time
    else
      [0, latest_message_timestamp] # Unpinned chats, sorted by latest message
    end
  end

  def active_cart
    carts.active.first
  end

  def find_or_create_cart
    active_cart || carts.create!(
      channel: 'whatsapp',
      status: 'active',
      expires_at: 24.hours.from_now
    )
  end

  def refresh_profile!(session_name = "default")
    client = WahaClient.new
    begin
      res = client.contact_profile_picture(wa_id: wa_id, session: session_name)
      # Always update with the latest value from WAHA, even if nil
      update_column(:profile_pic_url, res[:picture])
    rescue WahaClient::Error => e
      Rails.logger.warn "Failed to fetch profile picture for #{wa_id}: #{e.message}"
    end
  end

  # Update name from message data if not already set
  def update_name_from_message!(push_name)
    return if name.present? || push_name.blank?

    update_column(:name, push_name)
  end

    # Sync messages from WAHA to ensure we have all messages (both incoming and outgoing)
  def sync_messages_from_waha!(session_name = "default")
    client = WahaClient.new

    begin
      # Fetch messages from WAHA (limit to 100 to avoid overwhelming the system)
      waha_messages = client.chat_messages(chat_id: wa_id, session: session_name, limit: 100)

            # Process each message from WAHA
      waha_messages.each do |msg_payload|
        # Skip if we already have this message or if message ID is missing
        message_id = msg_payload["id"] || msg_payload[:id]
        next if message_id.blank? || messages.exists?(wa_message_id: message_id)

        # Determine direction based on `fromMe` flag
        direction = msg_payload["fromMe"] || msg_payload[:fromMe] ? :outgoing : :incoming

        # Extract body text
        body_text = if msg_payload["body"].present?
                      msg_payload["body"]
                    elsif msg_payload[:body].present?
                      msg_payload[:body]
                    elsif msg_payload.dig("text", "body").present?
                      msg_payload.dig("text", "body")
                    elsif msg_payload.dig(:text, :body).present?
                      msg_payload.dig(:text, :body)
                    end

        # Create the message
        messages.create!(
          wa_message_id: message_id,
          direction: direction,
          message_type: (msg_payload["type"] || msg_payload[:type] || "text"),
          body: body_text,
          payload: msg_payload,
          sent_at: (Time.at(msg_payload["timestamp"] || msg_payload[:timestamp]).utc rescue nil)
        )
      end

      # Update last_message_at if we found messages
      if waha_messages.any?
        latest_timestamp = waha_messages.map { |msg| msg["timestamp"] }.compact.max
        if latest_timestamp
          touch_last_message!(Time.at(latest_timestamp).utc)
        end
      end

    rescue WahaClient::Error => e
      Rails.logger.warn "Failed to sync messages for #{wa_id}: #{e.message}"
    end
  end

  # Returns the most recent message for the chat based on sent_at or created_at.
  # Memoized to avoid multiple queries when rendering the chat list item partial.
  def latest_message
    @latest_message ||= messages.order(Arel.sql("COALESCE(sent_at, created_at) DESC")).first
  end

  # Timestamp of the latest activity in the chat. Prefers the message's sent_at/created_at,
  # falling back to last_message_at (maintained via WAHA chats overview sync).
  def latest_message_timestamp
    latest_message&.sent_at || latest_message&.created_at || last_message_at
  end

  # Broadcasts updates to chat list UIs so they reflect new messages and metadata in real-time.
  # The approach removes any existing list item for this chat (if present) and then prepends
  # the freshly rendered item to the chats list so ordering is kept by latest activity.
  def broadcast_list_item
    # Derive the same DOM id used in the chat list partial
    list_item_dom_id = ActionView::RecordIdentifier.dom_id(self, :list_item)

    # Remove existing list item (if any) so we don't end up with duplicates after prepending.
    broadcast_remove_to "chats", target: list_item_dom_id

    # Prepend the updated list item to the top of the chat lists subscribing to the `chats` stream.
    broadcast_prepend_later_to "chats",
                              target: "chats_list",
                              partial: "chats/chat_list_item",
                              locals: { chat: self }
  end
end