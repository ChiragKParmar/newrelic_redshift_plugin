NewRelic Redshift Plugin
========================


A NewRelic Redshift Plugin

The New Relic Redshift Plugin enables integrated monitoring of your Redshift database in a custom NewRelic dashboard. Currently the following metrics are recorded:

* Database Memory Statistics 
	-Total Disk Space
	-Free Space
	-Percentage Utilized
* Table Statistics
	-Total Rows Per Table
	-Sorted Rows Per Table
	-Unsorted Rows Per Table
	-Percentage of Unsorted Region Per Table
	-Size of Table in Proportion to the Cluster Size
	-Staleness of the Table Stats (real size vs size recorded in stats)

More metrics coming! 

----
## Requirements



### Proxy host

You need a host to install the plugin on that is able to poll the desired Redshift database. That
host also needs Ruby (tested with 2.2.0), and support for rubygems.


## Installation and Running

1. 
	a. 	1. Install this gem from RubyGems:
      ```gem install newrelic_redshift_plugin```
		2. Create an installation directory (like /opt/newrelic/redshift ).

	b. 	1. Download the latest newrelic_redshift_plugin-X.Y.Z.tar.gz from [the tag list](https://github.com/ChiragKParmar/newrelic_redshift_plugin/tags)
		2. Extract the downloaded archive to the location you want to run the Redshift agent from
		3. Run bundle install to install required gems

2. In the installation directory, execute

      ```./bin/redshift_plugin install -l LICENSE_KEY```

   using the license key from your New Relic account.
3. Edit the `config/newrelic_plugin.yml` file generated in step 4. Setup host/port/user/password/dbname/schema for your redshift connection.
4. Execute

      ```./bin/redshift_plugin run```
5. Wait a few minutes for New Relic to begin processing the data sent from your agent.

6. Log into your New Relic account [here](http://newrelic.com) and click on Redshift on the left hand nav bar to start seeing your Redshift metrics.


##Source Code
This plugin can be found at [here](https://github.com/ChiragKParmar/newrelic_redshift_plugin/)


## Support

Please use Github issue for support. [git issue tracking](https://github.com/ChiragKParmar/newrelic_redshift_plugin/issues)


### Frequently Asked Questions

**Q: What is the default polling time ?**

**A:** Default polling period is 60 seconds.

**Q: How can I change the default polling time ?**

**A:** You can change the default value by editing [the newrelic_plugin.yml](https://github.com/ChiragKParmar/newrelic_redshift_plugin/blob/master/config/newrelic_plugin_template.yml#L12) and 
Please read [Newrelic's note on time periods for metrics](https://docs.newrelic.com/docs/plugins/plugin-developer-resources/developer-reference/metric-data-plugin-api#metric_duration)


## Contributing

Pull requests welcome!

1. Fork it ( https://github.com/ChiragKParmar/newrelic_redshift_plugin/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

----
## More Metrics Coming Soon!!!


