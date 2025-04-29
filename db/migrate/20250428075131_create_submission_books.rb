class CreateSubmissionBooks < ActiveRecord::Migration[7.2]
  def change
    create_table :submission_books do |t|
      t.references :submission, null: false, foreign_key: true
      t.string :title, null: false
      t.string :author, null: false
      t.string :cover_url, null: false
      t.integer :book_order, null: false

      t.timestamps
    end

    # 同じsubmissionの中でbook_orderは一意
    add_index :submission_books, [:submission_id, :book_order], unique: true
  end
end
