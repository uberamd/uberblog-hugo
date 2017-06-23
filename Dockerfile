FROM alpine:latest
MAINTAINER Steve Morrissey <uberamd@gmail.com>

ADD . /

CMD ["/hugo", "server", "--port=1313", "--bind=0.0.0.0", "--appendPort=false", "--config=config.toml", "-v", "--disableLiveReload=true", "--baseURL=https://www.stevem.io/"]

EXPOSE 1313
