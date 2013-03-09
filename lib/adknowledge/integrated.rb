require 'faraday'
require 'ox'
require 'addressable/uri'
require 'faraday_middleware/response/parse_xml'
require 'active_support/core_ext/module/delegation'
require 'pry'

module Adknowledge
  class Integrated
    attr_reader :request, :recipients
    attr_accessor :idomain, :cdomain, :subid, :test

    include Enumerable

    delegate :[], to: :recipients

    URL     = 'http://integrated.adstation.com'
    API_VER = '1.3'

    VALID_FIELDS = [
      :recipient, :list, :domain, :subid, :sendingdomain, :sendingip,
      :numberofrecipients, :redirect, :countrycode, :metrocode, :state,
      :postalcode, :gender, :dayofbirth, :monthofbirth, :yearofbirth
    ]

    MANDATORY_FIELDS = [ :recipient, :list, :domain ]

    def initialize params={}
      @records = []
      @mapped  = false
      params.each do |k,v|
        send("#{k}=", v)
      end
    end

    def recipients= recipient_hashes
      @recipients = recipient_hashes
      doc = Ox::Document.new version: '1.0'
      req = Ox::Element.new 'request'
      doc << Ox::Instruct.new('xml version="1.0" encoding="UTF-8"') << req
      recipient_hashes.each do |recipient_hash|
        email_hash = recipient_hash.select{|x| VALID_FIELDS.include? x}
        req << email_xml(email_hash)
      end
      @request = Ox.dump(doc, indent: 0, with_instruct: true).gsub(/\n/, '')
    end

    def map!
      unless Adknowledge.token
        raise ArgumentError, 'Adknowledge token required to perform queries'
      end

      merge_recipients! query_result
      @mapped = true
    end

    def mapped_recipients
      return [] unless mapped?
      recipients.select{|r| r['success']}
    end

    def errored_recipients
      return [] unless mapped?
      recipients.select{|r| ! r['success']}
    end

    def domain= dom
      self.cdomain = self.idomain = dom
    end

    def query_params
      { token:   Adknowledge.token,
        idomain: idomain,
        cdomain: cdomain,
        request: request,
        subid:   subid,
        test:    test ? 1 : 0
      }
    end

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

    def email_xml email_hash
      unless (MANDATORY_FIELDS - email_hash.keys).empty?
        raise ArgumentError, 'One or more mandatory fields were not submitted'
      end
      e = Ox::Element.new(:email)
      email_hash.each do |field, value|
        e << field_xml(field, value)
      end
      e
    end

    def field_xml field, value
      Ox::Element.new(field) << value.to_s
    end

  end
end
