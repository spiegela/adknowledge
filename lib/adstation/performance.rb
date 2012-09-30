require "faraday"
require "faraday_middleware"
require "faraday_middleware/parse_oj"
require "active_support/core_ext/module/delegation"

module Adstation
  class Performance
    include Enumerable

    attr_reader :measures, :dimensions, :filter, :options, :sort_option,
                :pivot_options, :records

    delegate :[], to: :records

    URL  = "http://api.publisher.adknowledge.com/performance"
    BASE = {token: Adstation.token}
    VALID_MEASURES = [
      :revenue, :schedules, :clicks, :paid_clicks, :valid_clicks,
      :invalid_clicks, :test_clicks, :domestic_paid_clicks,
      :domestic_unpaid_clicks, :foreign_paid_clicks, :foreign_unpaid_clicks,
      :foreign_clicks, :badip_clicks, :badagent_clicks, :badreferrer_clicks,
      :ecpm, :epc, :source_expense, :source_profit, :affiliate_percent,
      :gross_revenue, :ppc, :adjustments, :promotions, :referrals,
      :expense_accruals, :adjustment_accruals, :promotion_accruals,
      :referral_accruals, :accruals, :total_payment, :sent_amount,
      :domain_group, :source_account_name, :records
    ]

    VALID_DIMENSIONS = [
      :product_guid, :report_date, :report_hour, :report_30min, :report_15min,
      :is_accrued, :revenue_type, :source_product_guid, :list_id,
      :source_account_name, :domain_group_id, :domain_group, :report_time,
      :subid, :country_cd, :accrual_date, :suppress_date, :suppress_md5,
      :suppress_type
    ]

    VALID_FILTERS = [:start_date, :end_date] + VALID_DIMENSIONS

    VALID_PIVOT_KEYS = [:pivot, :sum, :count]

    def initialize
      @measures   = {}
      @dimensions = {}
      @filter     = {}
      @options    = {}
      @pivot_options = {}
    end

    def each
      if block_given?
        records.each do |doc|
          yield doc
        end
      else
        to_enum
      end
    end

    def select *selection
      unless (selection - VALID_MEASURES).empty?
        raise ArgumentError, "Invalid measurement selection"
      end
      @measures.merge! Hash[selection.zip([1] * selection.count)]
      self
    end

    def group_by *groupings
      unless (groupings - VALID_DIMENSIONS).empty?
        raise ArgumentError, "Invalid dimension grouping"
      end
      @dimensions.merge! Hash[groupings.zip([1] * groupings.count)]
      self
    end

    def where criteria
      unless(criteria.keys - VALID_FILTERS).empty?
        raise ArgumentError, "Invalid filter criteria"
      end
      criteria.each{|k,v| criteria[k] = v.to_s}
      @filter.merge! criteria
      self
    end

    def limit limit
      unless limit.is_a? Fixnum
        raise ArgumentError, "Limit must be an integer"
      end
      @options[:limit] = limit
      self
    end

    def sort sort_option
      unless sort_option.is_a? Fixnum
        raise ArgumentError, "Sort option must be an integer"
      end
      @sort_option = sort_option
      self
    end

    def full full
      unless !!full == full #Boolean check
        raise ArgumentError, "Full option must be a boolean"
      end
      @options[:full] = full
      self
    end

    def nocache nocache
      unless !!nocache == nocache #Boolean check
        raise ArgumentError, "NoCache option must be a boolean"
      end
      @options[:nocache] = nocache
      self
    end

    def display_all display_all
      unless !!display_all == display_all #Boolean check
        raise ArgumentError, "display_all option must be a boolean"
      end
      @options[:display_all] = display_all
      self
    end

    def pivot pivot_opt
      case pivot_opt
      when Symbol
        unless valid_pivot_values.include? pivot_opt
          raise ArgumentError, "Pivotted field must be a grouped dimension"
        end
        @pivot_options[:pivot] = pivot_opt
      when Hash
        unless (pivot_opt.values - VALID_MEASURES).empty?
          raise ArgumentError, "Pivotted value must be a measurement"
        end
        unless (pivot_opt.keys - [:sum, :count]).empty?
          raise ArgumentError, "Pivot must be sum or count"
        end
        @pivot_options = pivot_opt
      else
        raise ArgumentError, "Pivot options must be a symbol or hash"
      end
      self
    end

    def query_params
      p = BASE.merge(filter_params).
        merge(options_params).
        merge(pivot_params)
      p.merge!(measures: measures_param) unless measures.empty?
      p.merge!(dimensions: dimensions_param) unless dimensions.empty?
      p.merge!(sort: sort_option) if sort_option
      p
    end

    def records
      results.body["data"] if results.body.has_key?("data")
    end


    private

    def results
      @results ||= conn.get do |req|
        req.url "/performance", query_params
      end
    end

    def conn
      @conn ||= Faraday.new(:url => URL) do |b|
        b.response :json
        b.adapter  Faraday.default_adapter
      end
    end

    def valid_pivot_values
      dimensions.keys + ["*"]
    end

    def measures_param
      measures.keys.join(",")
    end

    def dimensions_param
      dimensions.keys.join(",")
    end

    def filter_params
      filter
    end

    def options_params
      options.inject({}) do |res,k,v|
        k = :all if k == :display_all
        res[k] = v ? "1" : "0"
        res
      end
    end

    def pivot_params
      pivot_options
    end
  end
end
