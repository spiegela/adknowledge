# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "adknowledge/version"

Gem::Specification.new do |s|
  s.name        = "adknowledge"
  s.version     = Adknowledge::VERSION
  s.authors     = ["Aaron Spiegel"]
  s.email       = ["spiegela@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Adknowledge API Tools}
  s.description = %q{A collection of web-api helpers and parsing utils for Adknowlege's APIs}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_development_dependency "pry"
  s.add_development_dependency "rspec"
  s.add_development_dependency "webmock"
  s.add_development_dependency "vcr"
  s.add_development_dependency "coveralls"
  s.add_runtime_dependency "rake"
  s.add_runtime_dependency "activesupport"
  s.add_runtime_dependency "multi_xml"
  s.add_runtime_dependency "multi_json"
  s.add_runtime_dependency "nokogiri"
  s.add_runtime_dependency "addressable"
  s.add_runtime_dependency "faraday"
  s.add_runtime_dependency "faraday_middleware-multi_json"
end
