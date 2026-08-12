class TeamMember < ApplicationRecord
  belongs_to :organization
  belongs_to :team
  belongs_to :user
end
