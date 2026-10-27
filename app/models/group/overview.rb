class Group::Overview
  attr_reader :group, :viewer

  def initialize(group, viewer:)
    @group, @viewer = group, viewer
  end

  def admin?
    @admin = group.admin?(viewer) unless defined?(@admin)
    @admin
  end

  def rows
    @rows ||= group.memberships.by_name.includes(user: :guardians).map { Membership::Row.new(it, viewer:, viewer_admin: admin?) }
  end

  def unread_count
    @unread_count ||= group.messages.for_everyone.unread_by(viewer).count
  end

  def occasions
    @occasions ||= begin
      upcoming = Occasion.visible_to(viewer).for_group(group).upcoming.soonest_first.includes(:person, :recipients)
      upcoming.coming_up.presence || upcoming.limit(1)
    end
  end

  def choice_for(occasion)
    choices[occasion]
  end

  private
    def choices
      @choices ||= viewer.gifts_to_choose(in_group: group).index_by(&:occasion)
    end
end
