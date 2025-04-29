class SubmissionBook < ApplicationRecord
  belongs_to :submission

  validates :title, presence: true
  validates :author, presence: true
  validates :cover_url, presence: true
  validates :book_order, presence: true,
                        numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 3 },
                        uniqueness: { scope: :submission_id, message: "同じ順番の本は登録できません" }

  default_scope { order(:book_order) }
end
