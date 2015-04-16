require "monatomic/version"
require "monatomic/models"
require "monatomic/application"
require "monatomic/controller"

Sinatra::Delegator.target = Monatomic::Application
extend Sinatra::Delegator

at_exit do
  if Monatomic::Application.run?
    Monatomic::Application.connect!
    Monatomic::Application.run!
  end
end
