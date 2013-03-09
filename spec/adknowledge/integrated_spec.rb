require "spec_helper"

describe Adknowledge::Integrated do
  before do
    Adknowledge.token = '3a9f34d1eee18880bbc74254ddf06448'
  end

  let :email_hashes do
    [
      { recipient: '004c58927df600d73d58c817bafc2155',
        list: 9250,
        domain: 'hotmail.com',
        countrycode: 'US',
        state: 'MO'
      },
      { recipient: 'a2a8c7a5ce7c4249663803c7d040401f',
        list: 9250,
        domain: 'mail.com',
        countrycode: 'CA'
      }
    ]
  end

  let :request_xml do
    %q[
<?xml version="1.0" encoding="UTF-8"?>
<request>
<email>
<recipient>004c58927df600d73d58c817bafc2155</recipient>
<list>9250</list>
<domain>hotmail.com</domain>
<countrycode>US</countrycode>
<state>MO</state>
</email>
<email>
<recipient>a2a8c7a5ce7c4249663803c7d040401f</recipient>
<list>9250</list>
<domain>rr.com</domain>
<countrycode>CA</countrycode>
</email>
</request>].gsub(/\n/, '')
  end

  let :domain1 do
    "fga.example.com"
  end

  let :integrated do
    described_class.new domain: domain1,
                        subid: 101,
                        test: true,
                        recipients: email_hashes
  end

  context "#recipients=" do
    subject do
      described_class.new
    end

    context "valid" do

      let :email_hashes do
        [
          { recipient: '004c58927df600d73d58c817bafc2155',
            list: 9250,
            domain: 'hotmail.com',
            countrycode: 'US',
            state: 'MO'
          },
          { recipient: 'a2a8c7a5ce7c4249663803c7d040401f',
            list: 9250,
            domain: 'rr.com',
            countrycode: 'CA'
          }
        ]
      end

      before do
        subject.recipients = email_hashes
      end

      it "sets the request" do
        expect(subject.request).to eql request_xml
      end

      it "keeps the recipients" do
        expect(subject.recipients).to eql email_hashes
      end
    end # valid

    context "missing mandatory field" do

      let :email_hashes do
        [
          { recipient: '004c58927df600d73d58c817bafc2155',
            list: 9250
          },
          { recipient: 'a2a8c7a5ce7c4249663803c7d040401f',
            list: 9250,
            domain: 'rr.com',
            countrycode: 'CA'
          }
        ]
      end

      it "raises an exception" do
        expect{
          subject.recipients = email_hashes
        }.to raise_error ArgumentError
      end

    end # missing mandatory field

  end # #recipients=

  context "#query_params" do

    let :domain2 do
      "fga.examplemail.com"
    end

    context "with domain option" do

      let :query_params do
        { token: "3a9f34d1eee18880bbc74254ddf06448",
          idomain: domain1,
          cdomain: domain1,
          request: request_xml,
          subid: 101,
          test: 1
        }
      end

      subject do
        integrated.query_params
      end

      it "has the token" do
        expect(subject[:token]).to eql "3a9f34d1eee18880bbc74254ddf06448"
      end

      it "has the idomain" do
        expect(subject[:idomain]).to eql domain1
      end

      it "has the cdomain" do
        expect(subject[:cdomain]).to eql domain1
      end

      it "has the test option" do
        expect(subject[:test]).to eql 1
      end

      it "has the subid" do
        expect(subject[:subid]).to eql 101
      end

    end # with domain option

    context "with cdomain/idomian" do

      let :query_params do
        { token: "3a9f34d1eee18880bbc74254ddf06448",
          idomain: domain1,
          cdomain: domain2,
          request: request_xml,
          subid: 102,
          test: false
        }
      end

      let :integrated do
        described_class.new idomain: domain1,
                            cdomain: domain2,
                            subid: 102,
                            test: false,
                            recipients: email_hashes
      end

      subject do
        integrated.query_params
      end

      it "has the cdomain" do
        expect(subject[:cdomain]).to eql domain2
      end

      it "has the idomain" do
        expect(subject[:idomain]).to eql domain1
      end

    end

  end # #query_params

  context "before map" do

    context "#mapped?" do

      subject do
        integrated.mapped?
      end

      it "should be false" do
        expect(subject).to be_false
      end

    end # #mapped?

    context "#mapped_recipients" do

      subject do
        integrated.mapped_recipients
      end

      it "has no mapped recipients" do
        expect(subject).to be_empty
      end

    end # #mapped_recipients

    context "#errored_recipients" do

      subject do
        integrated.errored_recipients
      end

      it "has no errored recipients" do
        expect(subject).to be_empty
      end

    end # #errored_recipients

  end # before map

  context "after map" do

    context "single results" do

      before do
        VCR.use_cassette :map_single_success, record: :once do
          integrated.map!
        end
      end

      context "#mapped?" do

        subject do
          integrated.mapped?
        end

        it "should be true" do
          expect(subject).to be_true
        end

      end # #mapped?

      context "#mapped_recipients" do

        subject do
          integrated.mapped_recipients
        end

        it "has a mapped recipient" do
          expect(subject.size).to eql 1
        end

        it "has a creative" do
          expect(subject.first['creative']).to be_a Hash
          expect(subject.first['creative']['body']).to be_a String
          expect(subject.first['creative']['subject']).to eql "Faxes delivered to your email."
        end
      end

      context "#errored_recipients" do

        subject do
          integrated.errored_recipients
        end

        it "has an errored recipient" do
          expect(subject.size).to eql 1
        end

        it "has an error error" do
          expect(subject.first['error']).to be_a Hash
          expect(subject.first['error']['num']).to eql "10"
          expect(subject.first['error']['str']).to eql "Domain is suppressed\n"
        end

      end # #errored_recipients

    end # single results

    context "multiple results" do

      let :email_hashes do
        [
          { recipient: '004c58927df600d73d58c817bafc2155',
            list: 9250,
            domain: 'hotmail.com',
            countrycode: 'US',
            state: 'MO'
          },
          { recipient: '004c58927df600d73d58c817bafc2156',
            list: 9250,
            domain: 'aol.com'
          },
          { recipient: 'a2a8c7a5ce7c4249663803c7d040401f',
            list: 9250,
            domain: 'mail.com',
            countrycode: 'CA'
          },
          { recipient: 'a2a8c7a5ce7c4249663803c7d040401e',
            list: 9250,
            domain: 'mail.com'
          }
        ]
      end

      before do
        VCR.use_cassette :map_multi_success, record: :once do
          integrated.map!
        end
      end

      context "#mapped?" do

        subject do
          integrated.mapped?
        end

        it "should be true" do
          expect(subject).to be_true
        end

      end # #mapped?

      context "#mapped_recipients" do

        subject do
          integrated.mapped_recipients
        end

        it "has a mapped recipient" do
          expect(subject.size).to eql 2
        end

        it "has a creative" do
          expect(subject.first['creative']).to be_a Hash
          expect(subject.first['creative']['body']).to be_a String
          expect(subject.first['creative']['subject']).to eql "Early-bird cruise specials"
        end
      end

      context "#errored_recipients" do

        subject do
          integrated.errored_recipients
        end

        it "has an errored recipient" do
          expect(subject.size).to eql 2
        end

        it "has an error error" do
          expect(subject.first['error']).to be_a Hash
          expect(subject.first['error']['num']).to eql "10"
          expect(subject.first['error']['str']).to eql "Domain is suppressed\n"
        end

      end # #errored_recipients

    end # multiple results

  end # after map

end # Adknowledge::Integrated
