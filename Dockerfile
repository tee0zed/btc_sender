FROM ruby:2.7

WORKDIR /btc_sender

COPY Gemfile Gemfile.lock /btc_sender/

RUN bundle install

COPY . /btc_sender/

CMD ["bin/cli"]
