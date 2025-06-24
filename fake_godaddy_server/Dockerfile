FROM ruby:3.2

WORKDIR /app

COPY Gemfile* ./
RUN bundle install

COPY server.rb .

CMD ["ruby", "server.rb"]
