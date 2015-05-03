# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'monatomic/version'

Gem::Specification.new do |spec|
  spec.name          = "monatomic"
  spec.version       = Monatomic::VERSION
  spec.authors       = ["Leedy Liu"]
  spec.email         = ["LeedyPKU@gmail.com"]

  spec.summary       = "A one-file CMS"
  spec.description   = "An extremely simple but powerful CMS built on Sinatra and Mongoid"
  spec.homepage      = "https://github.com/liudangyi/monatomic"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "mongoid", "~> 4.0"
  spec.add_dependency "sinatra", "~> 1.4"
  spec.add_dependency "sinatra-asset-pipeline", "~> 0.7"
  spec.add_dependency "rubyXL", "~> 3.3"

  spec.add_development_dependency "sinatra-contrib"
  spec.add_development_dependency "better_errors"
  spec.add_development_dependency "binding_of_caller"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "pry"
end
