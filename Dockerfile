FROM alpine:latest
MAINTAINER Steve Morrissey <uberamd@gmail.com>

ADD --chown=1001:1001 . /

WORKDIR /
USER 1001

CMD ["/hugo", "--config=config.toml", "-v"]
