FROM ruby:2.6-alpine3.9

ENV BUNDLE_BIN="$GEM_HOME/bin"
ENV PATH $BUNDLE_BIN:$PATH
RUN mkdir -p "$BUNDLE_BIN"
RUN chmod 777 "$BUNDLE_BIN"

RUN echo "gem: --no-rdoc --no-ri" >> ~/.gemrc \
    && apk --update add --virtual build-dependencies build-base \
    && apk --update add bash openssl zlib tzdata git openssh \
    && gem install bundler

RUN git clone --depth 1 https://github.com/Shelvak/FireAlerter.git /usr/src/firealerter
# RUN mkdir -p /usr/src/firealerter
# ADD . /usr/src/firealerter/

WORKDIR /usr/src/firealerter

RUN bundle install --jobs 8 --without test

VOLUME ["/logs"]

EXPOSE 9800

CMD ["bundle","exec","rake"]
