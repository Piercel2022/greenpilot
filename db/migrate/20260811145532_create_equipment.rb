class CreateEquipment < ActiveRecord::Migration[8.1]
def change
create_table :equipment, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
t.references :organization,
null: false,
type: :uuid,
foreign_key: true

  t.string :name, null: false
  t.string :equipment_type, null: false

  t.string :brand
  t.string :model
  t.string :serial_number

  t.date :purchase_date
  t.decimal :purchase_price, precision: 12, scale: 2

  t.string :status, null: false, default: "available"

  t.integer :maintenance_interval_days

  t.datetime :last_maintenance_at
  t.datetime :next_maintenance_at

  t.text :notes

  t.boolean :active, null: false, default: true

  t.timestamps
end

add_index :equipment,
          [:organization_id, :serial_number],
          unique: true,
          where: "serial_number IS NOT NULL"

add_index :equipment,
          [:organization_id, :equipment_type]

add_index :equipment,
          [:organization_id, :status]

add_index :equipment,
          [:organization_id, :active]

add_index :equipment,
          [:organization_id, :next_maintenance_at]

end
end

