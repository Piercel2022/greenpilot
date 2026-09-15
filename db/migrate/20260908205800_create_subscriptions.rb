class CreateSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriptions, id: :uuid do |t|
      t.references :organization,
                   type: :uuid,
                   null: false,
                   foreign_key: true,
                   index: { unique: true }

      t.references :plan,
                   type: :uuid,
                   null: false,
                   foreign_key: true

      t.string :status, null: false, default: "trialing"
      t.string :billing_interval, null: false, default: "monthly"

      t.string :stripe_customer_id
      t.string :stripe_subscription_id

      t.datetime :current_period_start
      t.datetime :current_period_end
      t.datetime :trial_ends_at
      t.datetime :canceled_at

      t.timestamps
    end

    add_index :subscriptions,
              :stripe_customer_id,
              unique: true

    add_index :subscriptions,
              :stripe_subscription_id,
              unique: true
  end
end