class CreateQuoteItems < ActiveRecord::Migration[8.1]
def change
create_table :quote_items, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
t.references :quote,
null: false,
type: :uuid,
foreign_key: true

  t.references :service_item,
               null: false,
               type: :uuid,
               foreign_key: true

  t.text :description, null: false

  t.decimal :quantity,
             precision: 12,
             scale: 3,
             null: false,
             default: 1

  t.string :unit, null: false, default: "unit"

  t.decimal :unit_price,
            precision: 12,
            scale: 2,
            null: false,
            default: 0

  t.decimal :discount_percentage,
            precision: 5,
            scale: 2,
            null: false,
            default: 0

  t.decimal :tax_rate,
            precision: 5,
            scale: 2,
            null: false,
            default: 20

  t.decimal :subtotal,
            precision: 12,
            scale: 2,
            null: false,
            default: 0

  t.decimal :tax_amount,
            precision: 12,
            scale: 2,
            null: false,
            default: 0

  t.decimal :total_amount,
            precision: 12,
            scale: 2,
            null: false,
            default: 0

  t.integer :estimated_duration_minutes

  t.decimal :labor_cost,
            precision: 12,
            scale: 2,
            null: false,
            default: 0

  t.decimal :equipment_cost,
            precision: 12,
            scale: 2,
            null: false,
            default: 0

  t.decimal :material_cost,
            precision: 12,
            scale: 2,
            null: false,
            default: 0

  t.decimal :estimated_cost,
            precision: 12,
            scale: 2,
            null: false,
            default: 0

  t.decimal :margin_amount,
            precision: 12,
            scale: 2,
            null: false,
            default: 0

  t.decimal :margin_percentage,
            precision: 5,
            scale: 2

  t.integer :position,
           null: false,
           default: 0

  t.timestamps
end

add_index :quote_items, [:quote_id, :position]
add_index :quote_items, [:quote_id, :service_item_id]

end
end

