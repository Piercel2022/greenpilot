class CreateServiceItems < ActiveRecord::Migration[8.1]
def change
create_table :service_items, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
t.references :organization,
null: false,
type: :uuid,
foreign_key: true

  t.references :service_category,
               null: false,
               type: :uuid,
               foreign_key: true

  t.string :name, null: false
  t.string :code, null: false
  t.text :description

  t.string :unit, null: false, default: "unit"
  t.decimal :default_quantity, precision: 12, scale: 3

  t.integer :estimated_duration_minutes

  t.decimal :labor_cost, precision: 12, scale: 2
  t.decimal :equipment_cost, precision: 12, scale: 2
  t.decimal :material_cost, precision: 12, scale: 2
  t.decimal :overhead_cost, precision: 12, scale: 2

  t.decimal :default_margin_percentage, precision: 5, scale: 2
  t.decimal :default_unit_price, precision: 12, scale: 2

  t.boolean :active, null: false, default: true
  t.integer :position, null: false, default: 0

  t.timestamps
end

add_index :service_items,
          [:organization_id, :code],
          unique: true

add_index :service_items,
          [:organization_id, :service_category_id]

add_index :service_items,
          [:organization_id, :name]

end
end
