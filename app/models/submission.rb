class Submission < ApplicationRecord
  has_many :submission_books, dependent: :destroy
  
  validates :uuid, presence: true, uniqueness: true
  validate :must_have_three_books
  
  before_validation :generate_uuid, on: :create
  
  private
  
  def generate_uuid
    self.uuid = SecureRandom.uuid
  end
  
  def must_have_three_books
    return if submission_books.size == 3
    errors.add(:base, "投稿には3冊の本が必要です")
  end
end
