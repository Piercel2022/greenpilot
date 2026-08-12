class CreateJobTimeEntries < ActiveRecord::Migration[8.1]
def change
create_table :job_time_entries, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
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

  t.datetime :started_at, null: false
  t.datetime :ended_at

  t.integer :duration_minutes

  t.string :entry_type, null: false, default: "work"

  t.text :notes

  t.timestamps
end

add_index :job_time_entries,
          [:job_id, :user_id, :started_at]

add_index :job_time_entries,
          [:organization_id, :job_id]

add_index :job_time_entries,
          [:organization_id, :user_id, :started_at]

add_index :job_time_entries,
          [:organization_id, :entry_type]

end
end
