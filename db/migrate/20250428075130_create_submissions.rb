class CreateSubmissions < ActiveRecord::Migration[7.2]
  def change
    create_table :submissions do |t|
      t.string :uuid, null: false
      t.text :comment
      t.string :generated_image_path

      t.timestamps
    end

    add_index :submissions, :uuid, unique: true
  end
end
