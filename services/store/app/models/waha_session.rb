class WahaSession < ApplicationRecord
  enum :status, {
    inactive: "inactive",
    pending_qr: "pending_qr",  # session started but not yet authenticated
    connected: "connected",   # authenticated and operational
    error: "error"             # encountered error
  }

  validates :name, presence: true, uniqueness: true

  has_many :chats, dependent: :nullify

  # Return the display label for status, could be improved later
  def status_label
    status.humanize
  end
end