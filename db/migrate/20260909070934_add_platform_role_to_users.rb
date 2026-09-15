
class AddPlatformRoleToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :platform_role, :string
    add_index :users, :platform_role
  end
end