require "i18n"
require "mongoid"
require "sinatra/base"
require "sinatra/asset_pipeline"
require "monatomic/helper"
require "sinatra/reloader"

module Monatomic
  class Application < Sinatra::Base

    configure do
      I18n.load_path += Dir[File.join(settings.root, 'locales', '*.yml')]
      I18n.config.exception_handler = -> (exception, locale, key, options) { key.humanize }
      set :app_name, "Monatomic CMS"
      set :db_name, -> { app_name.gsub(" ", "_").downcase }
      set :sessions, key: "monatomic.session"
      set :pagination_size, 25
      set :assets_precompile, %w(application.js application.css *.png *.jpg *.svg *.eot *.ttf *.woff)

      register Sinatra::AssetPipeline
    end

    configure :development do
      Moped.logger.level = 0
      set :run, true
      set :session_secret, "development_secret"
      begin
        require "sass"
        require "coffee_script"
        require "sinatra/reloader"
        require "better_errors"
        use BetterErrors::Middleware
        BetterErrors.application_root = File.expand_path(".")
        register Sinatra::Reloader
        Dir["**/*.rb"].each { |f| also_reload f }
      rescue LoadError
      end
    end

    helpers Monatomic::Helper

    def self.connect!
      Mongoid.configure.connect_to(db_name)
    end
  end
end
