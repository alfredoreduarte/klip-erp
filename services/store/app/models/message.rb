class Message < ApplicationRecord
  belongs_to :chat, touch: true

  enum direction: { incoming: 0, outgoing: 1 }

  validates :wa_message_id, presence: true, uniqueness: true
  validates :message_type, presence: true

  after_create_commit :broadcast_message

  private

  def broadcast_message
    # Broadcast to a Turbo Stream identified by the chat
    broadcast_append_later_to chat, target: "chat_#{chat.id}_messages", partial: "messages/message", locals: { message: self }
  end
end