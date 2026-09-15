class CreatePlans < ActiveRecord::Migration[8.1]
  def change
    create_table :plans, id: :uuid do |t|
      t.string :name, null: false
      t.string :slug, null: false

      t.integer :monthly_price_cents, null: false, default: 0
      t.integer :yearly_price_cents, null: false, default: 0

      t.integer :max_users, null: false, default: 1

      t.boolean :active, null: false, default: true

      t.string :stripe_product_id
      t.string :stripe_monthly_price_id
      t.string :stripe_yearly_price_id

      t.timestamps
    end

    add_index :plans, :slug, unique: true
    add_index :plans, :active
  end
end