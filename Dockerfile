FROM ruby:3.3.4

RUN gem install bundler

WORKDIR /btc_sender

COPY . /btc_sender/
COPY Gemfile Gemfile.lock /btc_sender/
COPY btc_sender.gemspec /btc_sender/

RUN bundle install

CMD ["/bin/bash"]
