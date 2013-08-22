require 'faraday'
require 'addressable/uri'
require 'faraday_middleware/response/parse_xml'
require 'active_support/core_ext/module/delegation'
require 'nokogiri'

module Adknowledge
  class Integrated
    include Enumerable

    attr_reader :request, :recipients
    attr_accessor :idomain, :cdomain, :subid, :test

    delegate :[], to: :recipients

    URL     = 'http://integrated.adstation.com'
    API_VER = '1.3'

    VALID_FIELDS = [
      :recipient, :list, :domain, :subid, :sendingdomain, :sendingip,
      :numberofrecipients, :redirect, :countrycode, :metrocode, :state,
      :postalcode, :gender, :dayofbirth, :monthofbirth, :yearofbirth
    ]

    MANDATORY_FIELDS = [ :recipient, :list, :domain ]

    # Create integrated query object
    #
    # @param parameters
    # @option [Symbol] domain set both click-domain and image-domain to the
    # same domain name for the request
    # @option [Symbol] cdomain set the click-domain for the request
    # @option [Symbol] idomain set the image-domain for the request
    # @option [Symbol] subid set the subid for the request
    # @option [Symbol] test set the test flag for the request
    def initialize params={}
      @records = []
      @mapped  = false
      params.each do |k,v|
        send("#{k}=", v)
      end
    end

    # Set the array of recipients to map
    #
    # @param [Array] recipients an array of hashes containing recipient details
    # @return [String] prepared XML request for recipient array
    def recipients= recipient_hashes
      @recipients = recipient_hashes
      doc = Nokogiri::XML::Builder.new do |root|
        root.request do |req|
          recipient_hashes.each do |recipient_hash|
            email_hash = recipient_hash.select{|x| VALID_FIELDS.include? x}
            email_xml(email_hash, req)
          end
        end
      end
      @request = doc.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML).gsub("\n", '')
    end

    # Set integer value for faradays timeout
    #
    # @param [Integer] integer value for timeout
    # @return [Integer] stored integer value
    def timeout= timeout
      @timeout ||= timeout.to_i
    end

    # Map content for specified recipients
    #
    # @return [Boolean] map attempt submitted
    def map!
      unless Adknowledge.token
        raise ArgumentError, 'Adknowledge token required to perform queries'
      end

      merge_recipients! query_result
      @mapped = true
    end

    # Return all successfully mapped recipients
    #
    # @return [Array] mapped recipients
    def mapped_recipients
      return [] unless mapped?
      recipients.select{ |r| r['success'] == true }
    end

    # Return all errored recipients
    #
    # @return [Array] errored recipients
    def errored_recipients
      return [] unless mapped?
      recipients.select{ |r| r['success'] == false }
    end

    # Set both click-domain and image-domain
    #
    # @param [Symbol] domain
    # @return [Symbol] domain
    def domain= dom
      self.cdomain = self.idomain = dom
    end

    # Return the query params that will be sent to Adknowledge integrated API
    #
    # @return [Hash] query params
    def query_params
      { token:   Adknowledge.token,
        idomain: idomain,
        cdomain: cdomain,
        request: request,
        subid:   subid,
        test:    test ? 1 : 0
      }
    end

    # Return confirmation if the mapping query has been run yet
    #
    # @return [Boolean] mapped?
    def mapped?
      @mapped
    end

    private

    def merge_recipients! results
      case results['email']
      when Array
        results['email'].each{ |record| merge_recipient! record, true }
      when Hash
        merge_recipient! results['email'], true
      end

      case results['error']
      when Array
        results['error'].each { |record| merge_recipient! record, false }
      when Hash
        merge_recipient! results['error'], false
      end
    end

    def merge_recipient! record, success
      fields = success ? get_email(record) : get_error(record)
      recipients.find do |recipient|
        record["recipient"] == recipient[:recipient]
      end.merge! fields
    end

    def get_email record
      record.merge 'success' => true
    end

    def get_error record
      { 'success' => false,
        'error'   => record.select{|k,v| %w[str num].include? k}
      }
    end

    def query_result
      conn.post do |req|
        req.headers = headers
        req.body    = post_body
        req.url API_VER
        req.options = {
          timeout: @timeout,
          open_timeout: @timeout
        } if @timeout
      end.body
    end

    def conn
      @conn ||= Faraday.new(:url => URL) do |b|
        b.adapter  Faraday.default_adapter
        b.response :adknowledge
      end
    end

    def headers
      {:Accepts => 'application/xml', :'Accept-Encoding' => 'gzip'}
    end

    def post_body
      uri = Addressable::URI.new
      uri.query_values = query_params
      uri.query
    end

    def email_xml email_hash, doc
      unless (MANDATORY_FIELDS - email_hash.keys).empty?
        raise ArgumentError, 'One or more mandatory fields were not submitted'
      end
      doc.email do |email|
        email_hash.each do |field, value|
          email.send(field, value)
        end
      end
    end

  end
end
