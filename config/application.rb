require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module Gifting
  class Application < Rails::Application
    config.load_defaults 8.1

    config.autoload_lib(ignore: %w[assets tasks])

    config.time_zone = "London"

    config.x.mail_from = ENV.fetch("MAIL_FROM", "gifting.group <hello@gifting.group>")
  end
end
