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
end