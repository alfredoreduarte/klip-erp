class MediaFile < ApplicationRecord
  belongs_to :message

  # Attach file using Active Storage
  has_one_attached :file

  validates :filename, presence: true
  validates :mimetype, presence: true

  # Check if file is an image
  def image?
    mimetype&.start_with?('image/')
  end

  # Check if file is a video
  def video?
    mimetype&.start_with?('video/')
  end

  # Check if file is audio
  def audio?
    mimetype&.start_with?('audio/')
  end

  # Get the URL for the attached file
  def url
    file.attached? ? file : nil
  end
end
