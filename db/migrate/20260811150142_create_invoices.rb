class CreateInvoices < ActiveRecord::Migration[8.1]
def change
create_table :invoices, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
t.references :organization,
null: false,
type: :uuid,
foreign_key: true

  t.references :customer,
               null: false,
               type: :uuid,
               foreign_key: true

  t.references :site,
               type: :uuid,
               foreign_key: true

  t.references :quote,
               type: :uuid,
               foreign_key: true

  t.references :job,
               type: :uuid,
               foreign_key: true

  t.string :number, null: false

  t.string :status,
           null: false,
           default: "draft"

  t.date :issue_date, null: false
  t.date :due_date

  t.datetime :paid_at

  t.decimal :subtotal,
            precision: 12,
            scale: 2,
            null: false,
            default: 0

  t.decimal :discount_amount,
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

  t.decimal :amount_paid,
            precision: 12,
            scale: 2,
            null: false,
            default: 0

  t.decimal :amount_due,
            precision: 12,
            scale: 2,
            null: false,
            default: 0

  t.string :payment_method
  t.string :payment_reference

  t.text :notes

  t.timestamps
end

add_index :invoices,
          [:organization_id, :number],
          unique: true

add_index :invoices,
          [:organization_id, :status]

add_index :invoices,
          [:organization_id, :customer_id]

add_index :invoices,
          [:organization_id, :issue_date]

add_index :invoices,
          [:organization_id, :due_date]

add_index :invoices,
          [:organization_id, :quote_id]

add_index :invoices,
          [:organization_id, :job_id]

end
end
