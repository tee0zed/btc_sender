FROM ruby:2.7.8
ENV BUNDLER_VERSION '2.4.22'
RUN gem install bundler -v "$BUNDLER_VERSION"

WORKDIR /btc_sender

COPY . /btc_sender/
COPY Gemfile Gemfile.lock /btc_sender/
COPY btc_sender.gemspec /btc_sender/

RUN bundle install

CMD ["/bin/bash"]
