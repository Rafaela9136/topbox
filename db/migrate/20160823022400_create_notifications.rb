class CreateNotifications < ActiveRecord::Migration[5.0]

  def change
    create_table :notifications do |t|
      t.references :user, index: true
      t.references :notified_by, index: true
      t.references :shareable, index: true
      t.boolean :read, default: false
      t.timestamps null: false
    end
    add_foreign_key :notifications, :users, column: :notified_by_id
    add_foreign_key :notifications, :documents, column: :shareable_id_id
  end

end
