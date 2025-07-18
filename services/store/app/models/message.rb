class Message < ApplicationRecord
  belongs_to :chat, touch: true
  has_many :media_files, dependent: :destroy
  has_many :message_reactions, dependent: :destroy
  belongs_to :reply_to_message, class_name: 'Message', optional: true
  has_many :replies, class_name: 'Message', foreign_key: 'reply_to_message_id'

  enum :direction, { incoming: 0, outgoing: 1 }

  validates :wa_message_id, presence: true, uniqueness: true
  validates :message_type, presence: true

  scope :pinned, -> { where.not(pinned_at: nil) }
  scope :unpinned, -> { where(pinned_at: nil) }

  after_create :download_media_if_needed
  after_create_commit :broadcast_message, :update_chat_last_message_timestamp

  # Check if message has media
  def has_media?
    media_url.present?
  end

  # Get media URL from payload
  def media_url
    payload['mediaUrl'] ||
    payload.dig('media', 'url') ||
    payload['url'] ||
    payload['media_url']
  end

  # Get the first media file (for display)
  def media_file
    media_files.first
  end

  # Get reactions grouped by emoji
  def reactions_summary
    message_reactions.group(:reaction).count
  end

  # Check if user has reacted with specific emoji
  def reacted_by?(user_wa_id, reaction = nil)
    if reaction
      message_reactions.exists?(user_wa_id: user_wa_id, reaction: reaction)
    else
      message_reactions.exists?(user_wa_id: user_wa_id)
    end
  end

  # Get user's reaction to this message
  def user_reaction(user_wa_id)
    message_reactions.find_by(user_wa_id: user_wa_id)&.reaction
  end

  # Check if this is a reply message
  def reply?
    reply_to_message_id.present?
  end

  # Get reply context for display
  def reply_context
    return nil unless reply?
    reply_to_message
  end

  # Pin the message using WAHA API and update local state
  def pin!(duration: 86400)
    return if pinned?

    session_name = chat.waha_session&.name || "default"

    begin
      # Call WAHA API to pin the message
      WahaClient.new.pin_message(
        chat_id: chat.wa_id,
        message_id: wa_message_id,
        session: session_name,
        duration: duration
      )

      # Update local state
      update_column(:pinned_at, Time.current)

      # Broadcast the updated message
      broadcast_replace_later_to chat, target: "message_#{id}", partial: "messages/message", locals: { message: self }
    rescue WahaClient::Error => e
      Rails.logger.error "Failed to pin message #{id}: #{e.message}"
      raise e
    end
  end

  # Unpin the message using WAHA API and update local state
  def unpin!
    return unless pinned?

    session_name = chat.waha_session&.name || "default"

    begin
      # Call WAHA API to unpin the message
      WahaClient.new.unpin_message(
        chat_id: chat.wa_id,
        message_id: wa_message_id,
        session: session_name
      )

      # Update local state
      update_column(:pinned_at, nil)

      # Broadcast the updated message
      broadcast_replace_later_to chat, target: "message_#{id}", partial: "messages/message", locals: { message: self }
    rescue WahaClient::Error => e
      Rails.logger.error "Failed to unpin message #{id}: #{e.message}"
      raise e
    end
  end

  # Sync pin state with WAHA/WhatsApp
  def sync_pin_state!
    session_name = chat.waha_session&.name || "default"

    begin
      # Fetch current message state from WAHA
      message_data = WahaClient.new.get_message(
        chat_id: chat.wa_id,
        message_id: wa_message_id,
        session: session_name
      )

      # Check if message is pinned in WAHA
      is_pinned_in_waha = message_data["pinned"] || message_data["pinInfo"]&.present?

      # Update local state if it differs
      if is_pinned_in_waha && !pinned?
        update_column(:pinned_at, Time.current)
        broadcast_replace_later_to chat, target: "message_#{id}", partial: "messages/message", locals: { message: self }
      elsif !is_pinned_in_waha && pinned?
        update_column(:pinned_at, nil)
        broadcast_replace_later_to chat, target: "message_#{id}", partial: "messages/message", locals: { message: self }
      end
    rescue WahaClient::Error => e
      Rails.logger.error "Failed to sync pin state for message #{id}: #{e.message}"
      # Don't raise - this is a sync operation, not critical
    end
  end

  # Check if message is pinned
  def pinned?
    pinned_at.present?
  end

  private

  def broadcast_message
    # Broadcast to a Turbo Stream identified by the chat
    broadcast_append_later_to chat, target: "chat_#{chat.id}_messages", partial: "messages/message", locals: { message: self }
  end

  def update_chat_last_message_timestamp
    chat.touch_last_message!(sent_at || created_at)

    # Trigger a broadcast so any open chat lists refresh and reorder.
    chat.broadcast_list_item
  end

  def download_media_if_needed
    # Only download media for incoming messages with media
    Rails.logger.info "download_media_if_needed called for message #{id}"
    return unless incoming? && has_media?

    Rails.logger.info "Starting immediate download for message #{id}"
    # Download immediately instead of queuing to catch files before WAHA cleans them up
    DownloadMediaJob.perform_now(id)
  end
end