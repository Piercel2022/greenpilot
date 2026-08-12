class CreateJobs < ActiveRecord::Migration[8.1]
def change
create_table :jobs, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
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

  t.references :quote,
               type: :uuid,
               foreign_key: true

  t.references :team,
               type: :uuid,
               foreign_key: true

  t.references :vehicle,
               type: :uuid,
               foreign_key: true

  t.string :title, null: false
  t.text :description

  t.string :job_type, null: false
  t.string :status, null: false, default: "planned"
  t.string :priority, null: false, default: "normal"

  t.date :scheduled_date

  t.datetime :scheduled_start_at
  t.datetime :scheduled_end_at

  t.integer :estimated_duration_minutes
  t.integer :actual_duration_minutes

  t.string :weather_risk, null: false, default: "unknown"
  t.text :weather_notes

  t.integer :travel_duration_minutes
  t.decimal :travel_distance_km, precision: 10, scale: 2

  t.string :address
  t.decimal :latitude, precision: 10, scale: 7
  t.decimal :longitude, precision: 10, scale: 7

  t.datetime :started_at
  t.datetime :completed_at
  t.datetime :cancelled_at

  t.text :cancellation_reason
  t.text :internal_notes
  t.text :customer_notes

  t.timestamps
end

add_index :jobs,
          [:organization_id, :status]

add_index :jobs,
          [:organization_id, :scheduled_date]

add_index :jobs,
          [:organization_id, :team_id, :scheduled_date]

add_index :jobs,
          [:organization_id, :vehicle_id, :scheduled_date]

add_index :jobs,
          [:organization_id, :customer_id]

add_index :jobs,
          [:organization_id, :site_id]

add_index :jobs,
          [:organization_id, :quote_id]

end
end
