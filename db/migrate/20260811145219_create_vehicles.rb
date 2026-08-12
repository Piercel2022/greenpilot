class CreateVehicles < ActiveRecord::Migration[8.1]
def change
create_table :vehicles, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
t.references :organization,
null: false,
type: :uuid,
foreign_key: true

  t.string :name, null: false
  t.string :registration_number, null: false
  t.string :vehicle_type
  t.string :brand
  t.string :model
  t.integer :year
  t.string :fuel_type
  t.decimal :fuel_consumption, precision: 8, scale: 2
  t.decimal :capacity, precision: 12, scale: 2

  t.boolean :active, null: false, default: true
  t.text :notes

  t.timestamps
end

add_index :vehicles,
          [:organization_id, :registration_number],
          unique: true

add_index :vehicles,
          [:organization_id, :name]

add_index :vehicles,
          [:organization_id, :active]

end
end
