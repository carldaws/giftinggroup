class Dashboard
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def lists
    @lists ||= [ user, *user.dependants.by_name ].map { Wishlist.new(it, viewer: user) }
  end

  def unread_chats
    @unread_chats ||= Message.unread_by(user).includes(:author, :group, subject: :user).chronologically
      .group_by { [ it.group, it.subject ] }
      .map { |(group, subject), messages| Message::UnreadChat.new(group:, subject:, messages:) }
      .sort_by { it.latest.created_at }.reverse
  end

  def gifts_to_choose
    @gifts_to_choose ||= user.gifts_to_choose
  end

  def splits
    @splits ||= user.splits_waiting
  end

  def to_buy
    shopping_list.reject(&:bought?)
  end

  def bought
    shopping_list.select { it.bought? && !it.given? }
  end

  def shopping?
    to_buy.any? || bought.any?
  end

  def groups
    @groups ||= user.groups.includes(:members).by_name
  end

  private
    def shopping_list
      @shopping_list ||= user.shopping_list
    end
end
