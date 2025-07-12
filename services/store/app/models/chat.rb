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
end