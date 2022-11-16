# syntax=docker/dockerfile:1@sha256:9ba7531bd80fb0a858632727cf7a112fbfd19b17e94c4e84ced81e24ef1a0dbc

# docker run -it --rm --pid=host --privileged=true -v /lib/modules:/lib/modules dgageot/ebpf
# profile -adf -p $(pgrep fibo) 15 > profile
# /flame/FlameGraph/flamegraph.pl < profile --colors java --hash > flame.svg

FROM docker/for-desktop-kernel:5.15.49-13422a825f833d125942948cf8a8688cef721ead as kernel

FROM busybox as extract-headers
COPY --link --from=kernel /kernel-dev.tar .
RUN tar xf kernel-dev.tar

FROM golang:1.19.3-alpine3.16 as build-burn
WORKDIR /src
RUN wget -O src.tgz https://github.com/spiermar/burn/tarball/master
WORKDIR /burn
RUN tar xzvf /src/src.tgz --strip-components=1
RUN go mod init github.com/spiermar/burn && go mod tidy && go build

FROM alpine:3.16
RUN apk add --no-cache bcc-tools
ENV PATH=/usr/share/bcc/tools/:$PATH
VOLUME /lib/modules
RUN mkdir /out
COPY --link --from=build-burn /burn/burn /bin/burn
COPY --link --from=extract-headers /usr/src/linux-headers-5.15.49-linuxkit /usr/src/linux-headers-5.15.49-linuxkit
COPY --link entrypoint.sh /
