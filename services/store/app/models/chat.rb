class Chat < ApplicationRecord
  has_many :messages, dependent: :destroy
  has_many :carts, dependent: :destroy
  belongs_to :waha_session, optional: true

  validates :wa_id, presence: true, uniqueness: true

  # Update last_message_at whenever a message is created
  def touch_last_message!(time = Time.current)
    update_column(:last_message_at, time)
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
end