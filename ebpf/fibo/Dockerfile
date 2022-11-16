FROM golang:1.19.3-alpine3.16@sha256:d171aa333fb386089206252503bc6ab545072670e0286e3d1bbc644362825c6e as builder
WORKDIR /fibo
COPY . .
RUN go build

FROM scratch
COPY --from=builder /fibo/fibo /fibo
ENTRYPOINT ["/fibo"]