# syntax=docker/dockerfile:1

FROM docker/for-desktop-kernel:5.15.49-13422a825f833d125942948cf8a8688cef721ead as kernel

FROM golang:1.19-alpine AS build-backend
ENV CGO_ENABLED=0
WORKDIR /backend
COPY --link vm/. .
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go build -trimpath -ldflags="-s -w" -o /backend

FROM --platform=$BUILDPLATFORM node:18.9-alpine3.15 AS build-ui
WORKDIR /ui
COPY --link ui/package.json /ui/package.json
COPY --link ui/package-lock.json /ui/package-lock.json
RUN --mount=type=cache,target=/usr/src/app/.npm \
    npm set cache /usr/src/app/.npm && \
    npm ci --force
COPY --link ui /ui
RUN npm run build

FROM golang:1.19.3-alpine3.16 as build-burn
WORKDIR /src
RUN wget -O src.tgz https://github.com/spiermar/burn/tarball/master
WORKDIR /burn
RUN tar xzvf /src/src.tgz --strip-components=1
RUN go mod init github.com/spiermar/burn && go mod tidy && go build

FROM eclipse-temurin:11 as build-perf-map-agent
RUN apt update && apt-get install -y cmake g++
WORKDIR /src
RUN wget -O src.tgz https://github.com/jvm-profiling-tools/perf-map-agent/tarball/master
RUN tar xzvf /src/src.tgz --strip-components=1
RUN cmake . && make

FROM busybox as extract-headers
COPY --link --from=kernel /kernel-dev.tar .
RUN tar xf kernel-dev.tar

FROM alpine:3.17
LABEL org.opencontainers.image.title="Flamegraph" \
    org.opencontainers.image.description="Automatic flamegraph extension" \
    org.opencontainers.image.vendor="David Gageot" \
    com.docker.desktop.extension.api.version="0.3.0" \
    com.docker.extension.screenshots="" \
    com.docker.extension.detailed-description="" \
    com.docker.extension.publisher-url="" \
    com.docker.extension.additional-urls="" \
    com.docker.extension.changelog=""
RUN apk add --no-cache bcc-tools openjdk12 procps
ENV PATH=/usr/share/bcc/tools/:$PATH
RUN mkdir /out
COPY --link entrypoint.sh docker-compose.yaml metadata.json flame.svg /
COPY --link --from=extract-headers /usr/src/linux-headers-5.15.49-linuxkit /usr/src/linux-headers-5.15.49-linuxkit
COPY --link --from=build-perf-map-agent /src/out/* /
COPY --link --from=build-burn /burn/burn /bin/burn
COPY --link --from=build-backend /backend /
COPY --link --from=build-ui /ui/build ui
CMD /backend -socket /run/guest-services/extension-flamegraph-extension.sock
