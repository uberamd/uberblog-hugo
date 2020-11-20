FROM alpine:latest
MAINTAINER Steve Morrissey <uberamd@gmail.com>
ADD . /
WORKDIR /
CMD ["/hugo", "--config=config.toml", "-v"]
