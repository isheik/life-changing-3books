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

    add_index :submission_books, [:submission_id, :book_order], unique: true
    
    # book_orderは1から3までの値のみ許可
    execute <<-SQL
      ALTER TABLE submission_books
      ADD CONSTRAINT check_book_order_range
      CHECK (book_order BETWEEN 1 AND 3)
    SQL
  end
end
