FROM alpine:3.4

RUN apk --update add ruby ca-certificates make

RUN gem install --no-ri --no-rdoc puppet hiera-eyaml

RUN adduser -D puppet

EXPOSE 8140

USER puppet
WORKDIR /home/puppet
COPY Makefile .
