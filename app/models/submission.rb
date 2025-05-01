class Submission < ApplicationRecord
  has_many :submission_books, dependent: :destroy
  
  validates :uuid, presence: true, uniqueness: true
  validate :must_have_three_books, on: :create
  
  accepts_nested_attributes_for :submission_books,
                              reject_if: :all_blank,
                              allow_destroy: true
  
  before_validation :generate_uuid, on: :create
  
  private
  
  def generate_uuid
    self.uuid = SecureRandom.uuid
  end
  
  def must_have_three_books
    return if submission_books.reject(&:marked_for_destruction?).size == 3
    errors.add(:base, "投稿には3冊の本が必要です")
  end
end
