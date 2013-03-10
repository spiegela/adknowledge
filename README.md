Adknowledge <a id='top'></a>
===========

A very Ruby client library for [Adknowledge](http://www.adknowledge.com) APIs

Right now it supports two API end-points:
* Integrated - pulls down creatives for recipients using ADK's integrated API
* Performance - report on product performance

Integrated
----------

Mapping content for recipients is super easy:

```ruby
# Start with an array of hashes for your recipients...
recipients = [
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

# Specify your auth token:
Adknowledge.token = "your token here"

# Create an Integrated object
mapper = Adknowledge::Integrated.new \
          domain: 'www.mydomain.com',
          subid: 1234,
          recipients: recipients

# Make stuff happen
mapper.map!

# Get yer results
mapper.each do |recipient|
  # your hash now has extra stuff
  # like:
  puts recipient['creative']['subject']
  puts recipient['creative']['body']
end

# Further short-cut with selections for mapped/errored
mapper.mapped_recipients.each do |recipient|
  # All of these were successful
end

mapper.errored_recipients.each do |recipient|
  # All of these errored :(
  puts recipient['error']['num']
  puts recipient['error']['str']
end
```

[Back to top](#top)
Performance
-----------

We also give you a nice ActiveRecord-inspired query interface

```ruby
# Specify your auth token:
Adknowledge.token = "your token here"

# Create a query object
perf = Adknowlege::Performance.new

perf.where(start_date: 1, domain_group: 'AOL Group').
     select(:revenue, :paid_clicks).
     group_by(:subid, :report_date)

perf.each do |row|
  # do something with the results
end
```

Supports the following query options:
* Select - Measures that you'd like to report
* Where - Filter criteria
* Group By - Dimensions to aggregate on
* Pivot - Advanced Pivot options
* No Cache - disable ADK default caching (60 seconds)
* Display All - Display dimensions even if they've been filtered
* Full - Return all days in the date range even if values are 0
* Sort - Column index to sort on
* Limit - Limit query to a number of rows

For more details see the specs, and [ADK documentation](https://publisher.adknowledge.com/help/documentation/chapter/data-pull-api)

[Back to top](#top)
TODO
----
There are several things currently unfinished:
* Error handling when requests are unsuccessful
* Options/convenience methods for parsing pivot query results
* Add an end-point for "lookup" API

How to Contribute
-----------------
* Fork this repository on Github
* Run the test suite - FYI: Auth tokens have been removed to protect the innocent
* Add code and tests
* Submit a pull request
* I'll merge if it looks good & passes
* Rinse
* Repeat
