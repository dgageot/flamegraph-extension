# syntax=docker/dockerfile:1

FROM golang:1.19-alpine AS builder
ENV CGO_ENABLED=0
WORKDIR /backend
COPY vm/. .
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go build -trimpath -ldflags="-s -w" -o bin/service

FROM --platform=$BUILDPLATFORM node:18.9-alpine3.15 AS client-builder
WORKDIR /ui
# cache packages in layer
COPY ui/package.json /ui/package.json
COPY ui/package-lock.json /ui/package-lock.json
RUN --mount=type=cache,target=/usr/src/app/.npm \
    npm set cache /usr/src/app/.npm && \
    npm ci --legacy-peer-deps
# install
COPY ui /ui
RUN npm run build

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

FROM eclipse-temurin:11 as build-perf-map-agent
RUN apt update && apt-get install -y cmake g++ git
RUN git clone --depth=1 https://github.com/jvm-profiling-tools/perf-map-agent.git
WORKDIR /perf-map-agent
RUN cmake . && make

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
RUN apk add --no-cache bcc-tools openjdk12
ENV PATH=/usr/share/bcc/tools/:$PATH
RUN mkdir /out
COPY --link entrypoint.sh docker-compose.yaml metadata.json docker.svg flame.svg /
COPY --link --from=build-burn /burn/burn /bin/burn
COPY --link --from=extract-headers /usr/src/linux-headers-5.15.49-linuxkit /usr/src/linux-headers-5.15.49-linuxkit
COPY --link --from=build-perf-map-agent /perf-map-agent/out/* /
COPY --link --from=builder /backend/bin/service /
COPY --link --from=client-builder /ui/build ui
CMD /service -socket /run/guest-services/extension-flamegraph-extension.sock
