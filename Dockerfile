FROM golang:alpine AS stage0
…

FROM golang:alpine AS stage1
go get -u github.com/derekparker/delve/cmd/dlv

FROM scratch AS debug
COPY --from=stage0 /binary0 /bin
COPY --from=stage1 $GOPATH/bin/dlv /bin
ENTRYPOINT ["dlv debug --headless --api-version=2 --log --listen=127.0.0.1:8181"]

FROM scratch AS release
COPY --from=stage0 /binary0 /bin

FROM golang:alpine AS dev-env
COPY --from=release / /
ENTRYPOINT ["./server"]

FROM golang:alpine AS test
COPY --from=release / /
RUN go test …

FROM release
