FROM alpine:latest
MAINTAINER Steve Morrissey <uberamd@gmail.com>

ADD . /

USER 1001
EXPOSE 1313

CMD ["/hugo", "server", "--port=1313", "--bind=0.0.0.0", "--appendPort=false", "--config=config.toml", "-v", "--disableLiveReload=true", "--baseURL=https://www.stevem.io/"]
