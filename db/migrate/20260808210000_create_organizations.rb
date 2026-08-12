class CreateOrganizations < ActiveRecord::Migration[8.1]
def change
create_table :organizations, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
t.string :name, null: false
t.string :slug, null: false
t.text :description

  t.string :phone
  t.string :email
  t.string :address
  t.string :city
  t.string :postal_code
  t.string :country
  t.string :timezone, null: false, default: "Europe/Paris"

  t.boolean :active, null: false, default: true

  t.timestamps
   end

add_index :organizations, :slug, unique: true
add_index :organizations, :email, unique: true

   end
end
