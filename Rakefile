require "bundler/gem_tasks"
require "monatomic/task"
require "pry" # for debug

namespace :example do
  Dir["examples/*.rb"].each do |name|
    taskname = name.match(/examples\/(.+).rb/)[1]
    desc "Run the example '#{name}'"
    task taskname do
      load name
    end
    task taskname + ":console" do
      load name
      Monatomic::Application.connect!
      Monatomic::Application.set :run, false
      pry
    end
  end
end
