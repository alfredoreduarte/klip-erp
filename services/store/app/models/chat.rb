class Chat < ApplicationRecord
  has_many :messages, dependent: :destroy

  validates :wa_id, presence: true, uniqueness: true

  # Update last_message_at whenever a message is created
  def touch_last_message!(time = Time.current)
    update_column(:last_message_at, time)
  end
end