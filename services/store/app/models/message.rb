class Message < ApplicationRecord
  belongs_to :chat, touch: true
  has_many :media_files, dependent: :destroy

  enum :direction, { incoming: 0, outgoing: 1 }

  validates :wa_message_id, presence: true, uniqueness: true
  validates :message_type, presence: true

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