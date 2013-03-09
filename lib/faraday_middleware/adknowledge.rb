require 'faraday'
require 'zlib'

module FaradayMiddleware
  class Adknowledge < Faraday::Response::Middleware
    dependency 'multi_xml'
    dependency 'zlib'

    def on_complete env
      encoding = env[:response_headers]['content-encoding'].to_s.downcase

      return unless env[:body].is_a? String

      case encoding
      when 'gzip'
        env[:body] = Zlib::GzipReader.new(StringIO.new(env[:body]), encoding: 'ASCII-8BIT').read
        env[:response_headers].delete 'content-encoding'
      when 'deflate'
        env[:body] = Zlib::Inflate.inflate env[:body]
        env[:response_headers].delete 'content-encoding'
      end

      begin
        env[:body] = ::MultiXml.parse(env[:body])['result']
      rescue Faraday::Error::ParsingError
        env[:body]
      end
    end

  end
end

Faraday::Response.register_middleware adknowledge: FaradayMiddleware::Adknowledge
