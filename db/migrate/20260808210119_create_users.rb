class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :organization, null: false, foreign_key: true, type: :uuid

      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email, null: false
      t.string :phone

      t.string :role, null: false, default: "member"
      t.boolean :active, null: false, default: true

      t.datetime :last_sign_in_at

      t.timestamps
    end

    add_index :users, :email, unique: true
  end
end
