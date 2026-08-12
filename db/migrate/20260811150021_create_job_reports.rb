class CreateJobReports < ActiveRecord::Migration[8.1]
def change
create_table :job_reports, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
t.references :organization,
null: false,
type: :uuid,
foreign_key: true

  t.references :job,
               null: false,
               type: :uuid,
               foreign_key: true

  t.text :summary
  t.text :work_performed
  t.text :observations
  t.text :recommendations

  t.string :customer_signature
  t.datetime :customer_signed_at

  t.datetime :generated_at
  t.datetime :sent_to_customer_at

  t.timestamps
end

add_index :job_reports,
          [:organization_id, :job_id]

add_index :job_reports,
          [:organization_id, :generated_at]

add_index :job_reports,
          [:organization_id, :sent_to_customer_at]

end
end
