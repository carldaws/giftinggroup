class User < ApplicationRecord
  include Birthday, Deletable

  has_many :sessions, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :groups, through: :memberships
  has_many :items, foreign_key: :owner_id, inverse_of: :owner, dependent: :destroy
  has_many :interests, dependent: :destroy
  has_many :sizes, dependent: :destroy
  has_many :reservations, dependent: :destroy
  has_many :shares, dependent: :destroy
  has_many :readings, dependent: :destroy
  has_many :suggestions, class_name: "Item", foreign_key: :suggested_by_id, inverse_of: :suggested_by, dependent: :destroy
  has_many :authored_messages, class_name: "Message", foreign_key: :author_id, inverse_of: :author

  has_many :guardianships, foreign_key: :guardian_id, inverse_of: :guardian, dependent: :destroy
  has_many :dependants, through: :guardianships
  has_many :guardianships_as_dependant, class_name: "Guardianship", foreign_key: :dependant_id, inverse_of: :dependant, dependent: :destroy
  has_many :guardians, through: :guardianships_as_dependant

  has_secure_password validations: false, reset_token: false

  generates_token_for :sign_in_link, expires_in: 3.days do
    password_salt.to_s.last(10)
  end

  AVATAR_TONES = %w[ clay sage honey plum ].freeze
  AVATAR_CHARACTERS = %w[ tree gift santa snowman snowflake bow bell teddy cake balloon popper star pumpkin ghost leaf heart chick rabbit shamrock lantern diya penguin fox owl ].freeze

  normalizes :email_address, with: ->(email_address) { email_address.strip.downcase.presence }
  normalizes :avatar_character, with: ->(character) { character.presence }

  validates :name, presence: true
  validates :avatar_tone, inclusion: { in: 0...AVATAR_TONES.size }, allow_nil: true
  validates :avatar_character, inclusion: { in: AVATAR_CHARACTERS }, allow_nil: true
  validates :email_address, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_nil: true
  validates :email_address, presence: true, on: %i[ registration credentials ]
  validates :email_address, presence: true, if: -> { email_address_in_database.present? }
  validate :email_change_is_confirmed_with_password, if: -> { will_save_change_to_email_address? && email_address_in_database.present? }
  validates :password, presence: true, if: :signs_in?, unless: :password_digest?
  validates :password, presence: true, on: :credentials
  validates :password, length: { minimum: 8 }, allow_nil: true
  validate :password_fits_bcrypt, if: -> { password.present? }

  after_update :stop_being_looked_after, if: -> { saved_change_to_email_address? && signs_in? }
  after_update :sign_out_everywhere, if: :saved_change_to_password_digest?

  scope :by_name, -> { order(Arel.sql("lower(users.name)")) }
  scope :visible_to, ->(user) do
    where(id: Membership.where(group_id: user.memberships.select(:group_id)).select(:user_id))
      .or(where(id: user.id))
      .or(where(id: user.guardianships.select(:dependant_id)))
  end
  scope :who_can_split_gifts_to, ->(owner, with:) do
    where(id: Membership.where(group_id: owner.memberships.select(:group_id)).select(:user_id))
      .or(where(id: owner.guardianships_as_dependant.select(:guardian_id)))
      .where.not(email_address: nil)
      .where.not(id: [ owner.id, with.id ])
  end

  def visible_to?(user)
    User.visible_to(user).exists?(id)
  end

  def signs_in?
    email_address.present?
  end

  def first_name
    name.split.first
  end

  def setting_up?
    email_address_in_database.blank?
  end

  def groups_by_name
    @groups_by_name ||= groups.by_name.to_a
  end

  def avatar_tone_name
    AVATAR_TONES[avatar_tone.presence_in(0...AVATAR_TONES.size) || id % AVATAR_TONES.size]
  end

  def avatar_character_name
    avatar_character.presence_in(AVATAR_CHARACTERS)
  end

  def looks_after?(user)
    user == self || dependants.to_a.include?(user)
  end

  def possible_guardians
    User.where(id: Membership.where(group_id: memberships.select(:group_id)).select(:user_id))
      .where.not(email_address: nil)
      .where.not(id: guardianships_as_dependant.select(:guardian_id))
  end

  def dependants_outside(group)
    dependants.where.not(id: group.memberships.select(:user_id))
  end

  def shopping_list
    reservations = Reservation.visible_to(self).involving(self).includes(:user, :shares, :sharers, occasion: :person, item: :owner).reject(&:waiting?)
    dated, undated = reservations.partition { it.occasion.present? }

    dated.sort_by { [ it.occasion.date, it.item.owner.name.downcase ] } + undated.sort_by { it.item.owner.name.downcase }
  end

  def splits_waiting
    splits = Reservation.visible_to(self).splits.unbought
    splits.involving(self).or(splits.where.not(item: Item.where(owner: dependants)))
      .includes(:user, :shares, :sharers, item: [ :owner, { reservations: %i[ user sharers ] } ]).order(:created_at).select(&:waiting?)
  end

  def drop_gifts_no_longer_visible
    reservations.where.not(item: Item.visible_to(self)).find_each(&:give_up)
    shares.where.not(reservation: Reservation.visible_to(self)).destroy_all
  end

  def gifts_to_choose(within: 6.weeks, in_group: nil)
    occasions = Occasion.visible_to(self)
    occasions = occasions.for_group(in_group) if in_group.present?
    visible_ids = User.visible_to(self).ids

    occasions.upcoming.soonest_first.includes(:group, :person, :recipients)
      .lazy
      .map { |occasion| [ occasion, gift_recipients_for(occasion, in_group:, visible_ids:) ] }
      .select { |_, recipients| recipients.any? }
      .with_index
      .take_while { |(occasion, _), index| index.zero? || occasion.date <= Date.current + within }
      .map { |(occasion, recipients), _| Occasion::Choice.new(occasion:, still_to_choose: recipients - people_chosen_for(occasion), everyone: recipients) }
      .select { it.still_to_choose.any? }
      .to_a
  end

  def people_chosen_for(occasion)
    picks = Reservation.involving(self).where(occasion:).joins(:item)
    User.where(id: picks.merge(Item.listed).or(picks.where.not(bought_at: nil)).select("items.owner_id"))
  end

  def build_item(attributes, by:, asked_for: false)
    items.build(attributes).tap do |item|
      item.suggested_by = by unless by == self || (asked_for && by.looks_after?(self))
    end
  end

  def start_group(attributes)
    Group.new(attributes).tap do |group|
      group.memberships.build(user: self, admin: true)
      group.save
    end
  end

  private
    def gift_recipients_for(occasion, in_group:, visible_ids:)
      people = in_group.present? ? occasion.people_in(in_group) : occasion.people_for(self)
      people.select { it != self && visible_ids.include?(it.id) }
    end

    def stop_being_looked_after
      guardianships_as_dependant.destroy_all
    end

    def sign_out_everywhere
      sessions.destroy_all
    end

    def email_change_is_confirmed_with_password
      errors.add(:password_challenge, :invalid) unless BCrypt::Password.new(password_digest_in_database).is_password?(password_challenge.to_s)
    end

    def password_fits_bcrypt
      errors.add(:password, :too_long_for_bcrypt) if password.bytesize > ActiveModel::SecurePassword::MAX_PASSWORD_LENGTH_ALLOWED
    end
end
