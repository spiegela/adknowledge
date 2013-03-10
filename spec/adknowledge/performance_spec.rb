require 'spec_helper'

describe Adknowledge::Performance do
  before do
    Adknowledge.token = 'b6d8610998e883b3a460fd2fcf71ead4'
  end

  context '#select' do
    it 'changes metric selection' do
      expect{
        subject.select(:revenue)
      }.to change(subject, :measures).
           from({}).
           to({revenue:1})
    end

    it 'supports multiple selections' do
      expect{
        subject.select(:revenue, :paid_clicks)
      }.to change(subject, :measures).
           from({}).
           to({revenue:1, paid_clicks:1})
    end

    it 'supports chained selections' do
      subject.select(:revenue)
      expect{
        subject.select(:paid_clicks)
      }.to change(subject, :measures).
           from({revenue:1}).
           to({revenue:1, paid_clicks:1})
    end

    it 'errors on invalid measure' do
      expect{ subject.select(:unvalid) }.to raise_error(ArgumentError)
    end
  end # #select

  context '#group_by' do
    it 'changes the dimension groupings' do
      expect{
        subject.group_by(:subid)
      }.to change(subject, :dimensions).
           from({}).
           to({subid:1})
    end

    it 'supports multiple groupings' do
      expect{
        subject.group_by(:report_date, :revenue_type)
      }.to change(subject, :dimensions).
           from({}).
           to({report_date:1, revenue_type:1})
    end

    it 'supports chained groupings' do
      subject.group_by(:report_date)
      expect{
        subject.group_by(:revenue_type)
      }.to change(subject, :dimensions).
           from({report_date:1}).
           to({report_date:1, revenue_type:1})
    end

    it 'errors on invalid dimension' do
      expect{ subject.select(:inpossible) }.to raise_error(ArgumentError)
    end
  end # #group_by

  context '#where' do
    it 'changes the filter criteria' do
      expect{
        subject.where(start_date:0)
      }.to change(subject, :filter).
           from({product_guid: '*', product_id: '2'}).
           to({product_guid: '*', product_id: '2', start_date:'0'})
    end

    it 'supports chained filtering' do
      subject.where(start_date:0)
      expect{
        subject.where(domain_group:'AOL Group')
      }.to change(subject, :filter).
           from({product_guid: '*', product_id: '2', start_date:'0'}).
           to({product_guid: '*', product_id: '2', start_date:'0', domain_group:'AOL Group'})
    end

    it 'errors on invalid filter' do
      expect{ subject.where(revenue:0) }.to raise_error(ArgumentError)
    end
  end # #where

  context '#limit' do
    it 'sets the limit option' do
      expect{
        subject.limit(10)
      }.to change(subject, :options).
           from({}).
           to({limit:"10"})
    end

    it 'supports chaining' do
      expect(
        subject.limit(10)
      ).to be_a Adknowledge::Performance
    end

    it 'errors on invalid limit' do
      expect{ subject.limit(:test) }.to raise_error(ArgumentError)
    end
  end # #limit

  context '#sort' do
    it 'sets the sort option' do
      expect{
        subject.sort(3)
      }.to change(subject, :sort_option).
           from(nil).
           to("3")
    end

    it 'supports chaining' do
      expect(
        subject.sort(5)
      ).to be_a Adknowledge::Performance
    end

    it 'errors on invalid sort' do
      expect{ subject.limit('test') }.to raise_error(ArgumentError)
    end
  end # #sort

  context '#full' do
    it 'sets the full option' do
      expect{
        subject.full(true)
      }.to change(subject, :options).
           from({}).
           to({full:"1"})
    end

    it 'supports chaining' do
      expect(
        subject.full(false)
      ).to be_a Adknowledge::Performance
    end

    it 'errors on invalid full' do
      expect{ subject.full('test') }.to raise_error(ArgumentError)
    end
  end # #full

  context '#nocache' do
    it 'sets the nocache option' do
      expect{
        subject.nocache(true)
      }.to change(subject, :options).
           from({}).
           to({nocache:"1"})
    end

    it 'supports chaining' do
      expect(
        subject.nocache(false)
      ).to be_a Adknowledge::Performance
    end

    it 'errors on invalid nocache' do
      expect{ subject.nocache('test') }.to raise_error(ArgumentError)
    end
  end # #nocache

  context '#display_all' do
    it 'sets the display_all option' do
      expect{
        subject.display_all(true)
      }.to change(subject, :options).
           from({}).
           to({all:"1"})
    end

    it 'supports chaining' do
      expect(
        subject.display_all(false)
      ).to be_a Adknowledge::Performance
    end

    it 'errors on invalid display_all' do
      expect{ subject.display_all('test') }.to raise_error(ArgumentError)
    end
  end # #display_all

  context '#pivot' do
    before do
      subject.group_by :country_cd
    end

    it 'sets a basic pivot' do
      expect{
        subject.pivot :country_cd
      }.to change(subject, :pivot_options).
           from({}).
           to({pivot: "country_cd"})
    end

    it 'only allows a single basic pivot' do
      expect{ subject.pivot(:one, :two) }.to raise_error(ArgumentError)
    end

    it 'only allows grouped dimensions to be pivoted on' do
      expect{ subject.pivot(:report_date) }.to raise_error(ArgumentError)
    end

    it 'sets a sum pivot' do
      subject.group_by :country_cd
      expect{
        subject.pivot(sum: :revenue)
      }.to change(subject, :pivot_options).
           from({}).
           to({sum: :revenue})
    end

    it 'only allows measurements to be summed' do
      expect{ subject.pivot(sum: :ilresponsible) }.to raise_error(ArgumentError)
    end

    it 'replaces a previous pivot' do
      subject.pivot :country_cd
      expect{
        subject.pivot(sum: :paid_clicks)
      }.to change(subject, :pivot_options).
           from({pivot: "country_cd"}).
           to({sum: :paid_clicks})
    end

    it 'only allows "sum "or "count"' do
      expect{ subject.pivot unlogical: :paid_clicks }.to raise_error(ArgumentError)
    end
  end # #pivot

  context '#query_params' do

    let :performance do
      described_class.new.where(start_date:1).
        select(:revenue,:paid_clicks).
        where(domain_group: 'AOL Group').
        group_by(:subid, :report_date).
        pivot(:report_date).
        nocache(true).
        display_all(true).
        full(true).
        sort(2).
        limit(20)
    end

    let :query_params do
      { token:'b6d8610998e883b3a460fd2fcf71ead4',
        start_date:'1',
        measures:'revenue,paid_clicks',
        domain_group: 'AOL Group',
        dimensions:'subid,report_date',
        product_guid: '*',
        pivot: 'report_date',
        product_id: '2',
        nocache:'1',
        full:'1',
        sort:'2',
        all:'1',
        limit:'20'
      }
    end

    subject do
      performance.query_params
    end

    it 'creates query_params' do
      expect(subject).to eql(query_params)
    end
  end # #query_params

  context '#records' do

    let :performance do
      described_class.new.where(start_date:1).
        select(:revenue,:paid_clicks).
        group_by(:subid, :report_date).
        limit(20)
    end

    context "succesful" do

      let :records do
        VCR.use_cassette :performance do
          performance.records
        end
      end

      subject do
        records
      end

      it 'has results' do
        expect(subject).to be_an Array
      end

      it 'has the correct dimensions' do
        expect(subject.first).to have_key 'subid'
        expect(subject.first).to have_key 'report_date'
      end

      it 'has the correct measures' do
        expect(subject.first).to have_key 'paid_clicks'
        expect(subject.first).to have_key 'revenue'
      end

      it 'has the correct count' do
        expect(subject.size).to eql 20
      end

    end # successful

    context "unsuccessful" do

      let :error_str do
        "The email/password or token provided does not match a " +
          "valid account. Please try again."
      end

      it 'raises an exception' do
        VCR.use_cassette :performance_errored do
          expect{ performance.records }.
            to raise_error(Adknowledge::Exception, error_str)
        end
      end
    end

  end # #records

end
