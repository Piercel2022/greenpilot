class CreateTeams < ActiveRecord::Migration[8.1]
def change
create_table :teams, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
t.references :organization,
null: false,
type: :uuid,
foreign_key: true

  t.string :name, null: false
  t.string :code, null: false
  t.text :description
  t.string :color

  t.boolean :active, null: false, default: true

  t.timestamps
end

add_index :teams,
          [:organization_id, :code],
          unique: true

add_index :teams,
          [:organization_id, :name]

end
end
