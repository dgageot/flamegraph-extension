FROM golang:1.19.3-alpine3.16 as builder
WORKDIR /fibo
COPY . .
RUN go build

FROM scratch
COPY --from=builder /fibo/fibo /fibo
ENTRYPOINT ["/fibo"]