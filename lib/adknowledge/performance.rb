require 'faraday'
require 'faraday_middleware'
require 'faraday_middleware/parse_oj'
require 'active_support/core_ext/module/delegation'

module Adknowledge
  class Performance
    include Enumerable

    attr_reader :measures, :dimensions, :filter, :sort_option, :pivot_options,
                :records, :options

    delegate :[], to: :records

    URL  = 'http://api.publisher.adknowledge.com/performance'

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
      :is_accrued, :revenue_type, :source_product_guid, :list_id, :product_id,
      :source_account_name, :domain_group_id, :domain_group, :report_time,
      :subid, :country_cd, :accrual_date, :suppress_date, :suppress_md5,
      :suppress_type
    ]

    VALID_FILTERS = [:start_date, :end_date] + VALID_DIMENSIONS

    VALID_PIVOT_KEYS = [:pivot, :sum, :count]

    DEFAULT_FILTER = {product_id: '2', product_guid: '*'}

    def initialize
      @measures   = {}
      @dimensions = {}
      @filter     = DEFAULT_FILTER.dup
      @options    = {}
      @pivot_options = {}
    end

    # Iterate the query results. Runs the query if it hasn't been already.
    #
    # @param [Block] block
    def each
      if block_given?
        records.each do |doc|
          yield doc
        end
      else
        to_enum
      end
    end

    # Specify the measure(s) to select in the query
    #
    # @param [Array] selection(s)
    # @return [Adknowledge::Performance] query object
    def select *selection
      @measures.merge! paramerize(selection, VALID_MEASURES, 'Invalid measurement selection')
      self
    end

    # Specify the dimension(s) to group measures by
    #
    # @param [Array] grouping(s)
    # @return [Adknowledge::Performance] query object
    def group_by *groupings
      @dimensions.merge! paramerize(groupings, VALID_DIMENSIONS, 'Invalid dimension group')
      self
    end

    # Specify the filter criteria to limit query by
    #
    # @param [Hash] criteria
    # @return [Adknowledge::Performance] query object
    def where criteria
      unless(criteria.keys - VALID_FILTERS).empty?
        raise ArgumentError, 'Invalid filter criteria'
      end
      criteria.each{|k,v| criteria[k] = v.to_s}
      @filter.merge! criteria
      self
    end

    # Specify a number of results to retrun
    #
    # @param [Integer] limit
    # @return [Adknowledge::Performance] query object
    def limit limit
      unless limit.is_a? Fixnum
        raise ArgumentError, 'Limit must be an integer'
      end
      @options[:limit] = limit.to_s
      self
    end

    # Specify the column index to sort by
    #
    # @param [Integer] sort_option
    # @return [Adknowledge::Performance] query object
    def sort sort_option
      unless sort_option.is_a? Fixnum
        raise ArgumentError, 'Sort option must be an integer'
      end
      @sort_option = sort_option.to_s
      self
    end

    # Specify whether to display the full set even if entries are 0
    #
    # @param [Boolean] full
    # @return [Adknowledge::Performance] query object
    def full full
      @options[:full] = booleanize 'Full', full
      self
    end

    # Disable caching of queries. By default queries are cached for 60 seconds
    #
    # @param [Boolean] nocache
    # @return [Adknowledge::Performance] query object
    def nocache nocache
      @options[:nocache] = booleanize 'NoCache', nocache
      self
    end

    # Force query to show filtered dimensions to be shown
    #
    # @param [Boolean] display_all
    # @return [Adknowledge::Performance] query object
    def display_all display_all
      @options[:all] = booleanize 'DisplayAll', display_all
      self
    end

    # Specify pivot options
    #
    # @param [Object] pivot Existing grouped field (as symbol) or Hash of options
    # @return [Adknowledge::Performance] query object
    def pivot pivot_opt
      case pivot_opt
      when Symbol
        unless valid_pivot_values.include? pivot_opt
          raise ArgumentError, 'Pivotted field must be a grouped dimension'
        end
        @pivot_options[:pivot] = pivot_opt.to_s
      when Hash
        unless (pivot_opt.values - VALID_MEASURES).empty?
          raise ArgumentError, 'Pivotted value must be a measurement'
        end
        unless (pivot_opt.keys - [:sum, :count]).empty?
          raise ArgumentError, 'Pivot must be sum or count'
        end
        @pivot_options = pivot_opt
      else
        raise ArgumentError, 'Pivot options must be a symbol or hash'
      end
      self
    end

    # Displays the query parameters passed to Adknowledge performance API
    #
    # @return [Hash] query parameters
    def query_params
      p = base_params.merge(filter_params).
        merge(options_params).
        merge(pivot_params)
      p.merge!(measures: measures_param) unless measures.empty?
      p.merge!(dimensions: dimensions_param) unless dimensions.empty?
      p.merge!(sort: sort_option) if sort_option
      p
    end

    # Return the query result records
    #
    # @return [Array] query result records
    def records
      unless Adknowledge.token
        raise ArgumentError, 'Adknowledge token required to perform queries'
      end
      results.body['data'] if results.body.has_key?('data')
    end


    private

    def base_params
      {token: Adknowledge.token}
    end

    def results
      @results ||= conn.get do |req|
        req.url '/performance.json', query_params
      end
    end

    def conn
      @conn ||= Faraday.new(:url => URL) do |b|
        b.response :oj
        b.adapter  Faraday.default_adapter
      end
    end

    def paramerize array, valid, error_str
      array = array.map{|x| x.to_sym} # handle strings & symbols equally
      unless (array - valid).empty?
        raise ArgumentError, error_str
      end
      Hash[array.zip([1] * array.count)]
    end

    def booleanize name, value
      unless !!value == value #Boolean check
        raise ArgumentError, "#{name} option must be a boolean"
      end
      value ? '1' : '0'
    end

    def valid_pivot_values
      dimensions.keys + ['*']
    end

    def measures_param
      measures.keys.join(',')
    end

    def dimensions_param
      dimensions.keys.join(',')
    end

    def options_params
      options
    end

    def filter_params
      filter
    end

    def pivot_params
      pivot_options
    end
  end
end
