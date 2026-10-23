class List < ApplicationRecord
  belongs_to :owner, class_name: "User"

  has_many :shares, dependent: :destroy
  has_many :groups, through: :shares
  has_many :items, dependent: :destroy

  validates :name, presence: true

  scope :visible_to, ->(user) do
    where(id: Share.where(group_id: user.memberships.select(:group_id)).select(:list_id))
      .or(where(owner: user))
      .or(where(owner_id: user.guardianships.select(:dependant_id)))
  end

  def visible_to?(user)
    List.visible_to(user).exists?(id)
  end

  def owned_by?(user)
    owner == user
  end

  def editable_by?(user)
    user.looks_after?(owner)
  end
end
