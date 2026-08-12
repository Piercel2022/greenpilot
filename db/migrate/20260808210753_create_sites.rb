class CreateSites < ActiveRecord::Migration[8.1]
def change
create_table :sites, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
t.references :organization,
null: false,
type: :uuid,
foreign_key: true

  t.references :customer,
               null: false,
               type: :uuid,
               foreign_key: true

  t.string :name, null: false
  t.string :site_type

  t.string :address_line1
  t.string :address_line2
  t.string :postal_code
  t.string :city
  t.string :country, null: false, default: "FR"

  t.decimal :latitude, precision: 10, scale: 7
  t.decimal :longitude, precision: 10, scale: 7
  t.decimal :surface_area, precision: 12, scale: 2

  t.text :notes
  t.boolean :active, null: false, default: true

  t.timestamps
end

add_index :sites, [:organization_id, :customer_id]
add_index :sites, [:organization_id, :name]

end
end
