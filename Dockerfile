FROM ruby:2.2
RUN mkdir /usr/src/app 
ADD . /usr/src/app/ 
WORKDIR /usr/src/app/ 

RUN bundle install
CMD erb newrelic_plugin.yml.erb > config/newrelic_plugin.yml ; /usr/src/app/bin/redshift_plugin run
