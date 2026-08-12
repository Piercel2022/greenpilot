class CreateJobAssignments < ActiveRecord::Migration[8.1]
def change
create_table :job_assignments, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
t.references :organization,
null: false,
type: :uuid,
foreign_key: true

  t.references :job,
               null: false,
               type: :uuid,
               foreign_key: true

  t.references :user,
               null: false,
               type: :uuid,
               foreign_key: true

  t.string :assignment_type, null: false, default: "primary"
  t.string :role, null: false, default: "worker"

  t.datetime :assigned_at
  t.datetime :accepted_at
  t.datetime :completed_at

  t.boolean :active, null: false, default: true

  t.text :notes

  t.timestamps
end

add_index :job_assignments,
          [:job_id, :user_id],
          unique: true

add_index :job_assignments,
          [:organization_id, :job_id]

add_index :job_assignments,
          [:organization_id, :user_id]

add_index :job_assignments,
          [:organization_id, :active]

end
end
