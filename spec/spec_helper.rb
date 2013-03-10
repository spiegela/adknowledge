$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'adknowledge'
require 'rspec'
require 'vcr'
require 'coveralls'

VCR.configure do |c|
  c.hook_into :webmock
  c.cassette_library_dir = 'spec/cassettes'
  c.default_cassette_options = {
    decode_compressed_response: true,
    record: :once,
    match_requests_on: [ :method ]
  }
end

Coveralls.wear!
