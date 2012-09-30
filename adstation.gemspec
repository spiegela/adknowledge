# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "adstation/version"

Gem::Specification.new do |s|
  s.name        = "adstation"
  s.version     = Adstation::VERSION
  s.authors     = ["Aaron Spiegel"]
  s.email       = ["spiegela@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Adknowledge Adstation API Tools}
  s.description = %q{A collection of web-api helpers and parsing utils for Adknowlege's Adstation API}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_development_dependency "pry"
  s.add_development_dependency "rspec"
  s.add_runtime_dependency "activesupport"
  s.add_runtime_dependency "oj"
  s.add_runtime_dependency "faraday"
  s.add_runtime_dependency "faraday_middleware"
  s.add_runtime_dependency "faraday_middleware-parse_oj"
end
