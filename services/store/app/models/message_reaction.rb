class MessageReaction < ApplicationRecord
  belongs_to :message

  validates :reaction, presence: true
  validates :user_wa_id, presence: true
  validates :user_wa_id, uniqueness: { scope: :message_id, message: "can only react once per message" }

  # Get the user's display name if available
  def user_display_name
    # This could be enhanced to look up user info from WAHA session
    user_wa_id.split('@').first
  end

  # Check if this reaction is from the current user (outgoing messages)
  def from_me?
    message.outgoing?
  end
end