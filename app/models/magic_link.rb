class MagicLink < ApplicationRecord
  CODE_LENGTH = 6
  LIFETIME = 15.minutes
  MAX_FAILED_ATTEMPTS = 5

  has_secure_token :token

  normalizes :email_address, with: ->(email_address) { email_address.strip.downcase }
  normalizes :code, with: ->(code) { code.gsub(/\D/, "") }

  validates :email_address, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  before_validation :assign_code_and_expiry, on: :create
  before_create :replace_earlier_links
  after_create_commit :deliver

  scope :active, -> { where(expires_at: Time.current..) }
  scope :expired, -> { where(expires_at: ...Time.current) }

  class << self
    def redeem_token(token)
      magic_link = active.find_by(token:)
      magic_link.redeem if magic_link.present?
    end

    def redeem_code(email_address:, code:)
      magic_link = active.find_by(email_address:)
      magic_link.redeem_code(code) if magic_link.present?
    end
  end

  def redeem
    destroy!
  end

  def redeem_code(attempt)
    if code_matches?(attempt)
      redeem
    else
      record_failed_attempt
      nil
    end
  end

  private
    def assign_code_and_expiry
      self.code = SecureRandom.random_number(10**CODE_LENGTH).to_s.rjust(CODE_LENGTH, "0")
      self.expires_at = LIFETIME.from_now
    end

    def replace_earlier_links
      MagicLink.where(email_address:).delete_all
    end

    def deliver
      MagicLinkMailer.sign_in(self).deliver_later
    end

    def code_matches?(attempt)
      ActiveSupport::SecurityUtils.secure_compare(code, self.class.normalize_value_for(:code, attempt))
    end

    def record_failed_attempt
      increment!(:failed_attempts)
      destroy! if failed_attempts >= MAX_FAILED_ATTEMPTS
    end
end
