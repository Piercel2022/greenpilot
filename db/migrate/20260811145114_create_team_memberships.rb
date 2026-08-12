class CreateTeamMemberships < ActiveRecord::Migration[8.1]
def change
create_table :team_memberships, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
t.references :organization,
null: false,
type: :uuid,
foreign_key: true

  t.references :team,
               null: false,
               type: :uuid,
               foreign_key: true

  t.references :user,
               null: false,
               type: :uuid,
               foreign_key: true

  t.string :role, null: false, default: "member"

  t.date :start_date
  t.date :end_date

  t.boolean :active, null: false, default: true

  t.timestamps
end

add_index :team_memberships,
          [:team_id, :user_id],
          unique: true

add_index :team_memberships,
          [:organization_id, :user_id]

add_index :team_memberships,
          [:organization_id, :team_id]

add_index :team_memberships,
          [:organization_id, :active]

end
end

