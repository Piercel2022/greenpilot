class CreateServiceCategories < ActiveRecord::Migration[8.1]
def change
create_table :service_categories, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
t.references :organization,
null: false,
type: :uuid,
foreign_key: true

  t.string :name, null: false
  t.string :code, null: false
  t.text :description
  t.string :category_type

  t.boolean :active, null: false, default: true
  t.integer :position, null: false, default: 0

  t.timestamps
end

add_index :service_categories,
          [:organization_id, :code],
          unique: true

add_index :service_categories,
          [:organization_id, :name]

end
end

