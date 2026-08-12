class CreateQuotes < ActiveRecord::Migration[8.1]
def change
create_table :quotes, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
t.references :organization,
null: false,
type: :uuid,
foreign_key: true

  t.references :customer,
               null: false,
               type: :uuid,
               foreign_key: true

  t.references :site,
               null: false,
               type: :uuid,
               foreign_key: true

  t.string :number, null: false
  t.string :title, null: false
  t.text :description

  t.string :status, null: false, default: "draft"

  t.date :issue_date, null: false
  t.date :valid_until

  t.datetime :accepted_at
  t.datetime :rejected_at

  t.decimal :subtotal, precision: 12, scale: 2, null: false, default: 0
  t.decimal :discount_amount, precision: 12, scale: 2, null: false, default: 0
  t.decimal :tax_amount, precision: 12, scale: 2, null: false, default: 0
  t.decimal :total_amount, precision: 12, scale: 2, null: false, default: 0

  t.decimal :estimated_cost, precision: 12, scale: 2, null: false, default: 0
  t.decimal :estimated_margin_amount, precision: 12, scale: 2, null: false, default: 0
  t.decimal :estimated_margin_percentage, precision: 5, scale: 2

  t.text :notes

  t.timestamps
end

add_index :quotes,
          [:organization_id, :number],
          unique: true

add_index :quotes,
          [:organization_id, :customer_id]

add_index :quotes,
          [:organization_id, :site_id]

add_index :quotes,
          [:organization_id, :status]

add_index :quotes,
          [:organization_id, :issue_date]

end
end
