class WahaSession < ApplicationRecord
  enum :status, {
    inactive: "inactive",
    pending_qr: "pending_qr",  # session started but not yet authenticated
    connected: "connected",   # authenticated and operational
    error: "error"             # encountered error
  }

  validates :name, presence: true, uniqueness: true

  has_many :chats, -> { where.not(wa_id: "status@broadcast") }, dependent: :nullify

  # Return the display label for status, could be improved later
  def status_label
    status.humanize
  end

  # Fetch chats overview from WAHA and update local Chat records with
  # last_message_at and basic metadata (name, unread count, etc.).
  def sync_chats_overview!
    client = WahaClient.new
    overview = client.chats_overview(session: name)

    overview.each do |chat_info|
      wa_id = chat_info[:id] || chat_info["id"] || chat_info[:chatId] || chat_info["chatId"]
      next if wa_id.blank?

      chat = chats.find_or_create_by!(wa_id: wa_id)

      # Update name if provided and current name missing
      new_name = chat_info[:name] || chat_info["name"] || chat_info[:contactName] || chat_info["contactName"]
      if new_name.present? && chat.name.blank?
        chat.update_column(:name, new_name)
      end

      # Update last_message_at if timestamp provided
      last_ts = chat_info[:lastMessageTimestamp] || chat_info["lastMessageTimestamp"] || chat_info[:lastMessageTime] || chat_info["lastMessageTime"]
      if last_ts.present?
        # WAHA returns Unix timestamp (seconds). Ensure integer.
        time_obj = Time.at(last_ts.to_i).utc rescue nil
        chat.touch_last_message!(time_obj) if time_obj
      end
    end
  rescue WahaClient::Error => e
    Rails.logger.warn "WAHA chats overview sync failed for session #{name}: #{e.message}"
  end
end