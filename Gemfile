source "http://rubygems.org"

# Specify your gem's dependencies in adstation.gemspec
gemspec

group :development, :test do
  platforms :jruby do
    gem 'gson'
    gem 'libxml-jruby'
  end

  platforms :mri do
    gem 'ox'
    gem 'oj'
  end
end
