class CreateContactRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :contact_requests do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email, null: false
      t.string :company, null: false
      t.string :phone
      t.string :request_type, null: false
      t.text :message, null: false
      t.string :status, null: false, default: "new"

      t.timestamps
    end

    add_index :contact_requests, :email
    add_index :contact_requests, :status
    add_index :contact_requests, :request_type
    add_index :contact_requests, :created_at
  end
end