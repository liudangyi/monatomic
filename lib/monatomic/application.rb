require "coffee_script"
require "sinatra/base"
require "sinatra/asset_pipeline"
require "monatomic/helper"

module Monatomic
  class Application < Sinatra::Base
    register Sinatra::AssetPipeline

    set :db_name, "monatomic_cms"
    set :common_translation, {
      "Project name" => "Monatomic CMS",
    }
    set :sessions, key: "monatomic.session"

    configure :development do
      begin
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
      Mongoid.configure do |config|
        config.connect_to(db_name)
      end
    end
  end
end
