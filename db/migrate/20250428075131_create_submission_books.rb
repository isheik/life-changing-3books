class CreateSubmissionBooks < ActiveRecord::Migration[7.2]
  def change
    create_table :submission_books do |t|
      t.references :submission, null: false, foreign_key: true
      t.string :title
      t.string :author
      t.string :cover_url
      t.integer :book_order

      t.timestamps
    end
  end
end
