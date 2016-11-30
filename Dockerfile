FROM scratch
MAINTAINER Steve Morrissey <uberamd@gmail.com>

ADD . /

CMD ["/hugo", "server", "--port=1313", "--bind=0.0.0.0", "--appendPort=false"]

EXPOSE 1313
