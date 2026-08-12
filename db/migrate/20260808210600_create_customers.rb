class CreateCustomers < ActiveRecord::Migration[8.1]
def change
create_table :customers, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
t.references :organization,
null: false,
type: :uuid,
foreign_key: true

  t.string :first_name
  t.string :last_name
  t.string :company_name
  t.string :email
  t.string :phone
  t.string :mobile

  t.string :customer_type, null: false, default: "individual"
  t.text :notes
  t.boolean :active, null: false, default: true

  t.timestamps
end

add_index :customers, [:organization_id, :email]
add_index :customers, [:organization_id, :company_name]

end
end
