class CreateInvoiceItems < ActiveRecord::Migration[8.1]
def change
create_table :invoice_items, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
t.references :invoice,
null: false,
type: :uuid,
foreign_key: true

  t.references :service_item,
               type: :uuid,
               foreign_key: true

  t.text :description, null: false

  t.decimal :quantity,
            precision: 12,
            scale: 3,
            null: false,
            default: 1

  t.string :unit, null: false

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
            default: 0

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

  t.integer :position,
             null: false,
             default: 0

  t.timestamps
end

add_index :invoice_items,
          [:invoice_id, :position],
          unique: true

add_index :invoice_items,
          [:invoice_id, :service_item_id]

end
end
