# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2025_04_28_075131) do
  create_table "submission_books", force: :cascade do |t|
    t.integer "submission_id", null: false
    t.string "title", null: false
    t.string "author", null: false
    t.string "cover_url", null: false
    t.integer "book_order", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["submission_id", "book_order"], name: "index_submission_books_on_submission_id_and_book_order", unique: true
    t.index ["submission_id"], name: "index_submission_books_on_submission_id"
  end

  create_table "submissions", force: :cascade do |t|
    t.string "uuid", null: false
    t.text "comment"
    t.string "generated_image_path"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uuid"], name: "index_submissions_on_uuid", unique: true
  end

  add_foreign_key "submission_books", "submissions"
end
