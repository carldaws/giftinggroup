class Membership::Row
  attr_reader :membership

  delegate :group, :admin?, :dependant?, to: :membership

  def initialize(membership, viewer:, viewer_admin:)
    @membership, @viewer, @viewer_admin = membership, viewer, viewer_admin
    @sign_in_link = membership.sign_in_link_creatable_by?(viewer)
    @removable = membership.removable_by?(viewer)
  end

  def person
    membership.user
  end

  def yours?
    person == @viewer
  end

  def admin_toggle?
    @viewer_admin && !dependant?
  end

  def sign_in_link?
    @sign_in_link
  end

  def removable?
    @removable
  end

  def menu?
    @viewer_admin || removable? || sign_in_link?
  end

  def divider?
    removable? && (admin_toggle? || sign_in_link?)
  end
end
