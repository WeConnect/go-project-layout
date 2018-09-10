FROM golang:alpine AS baseGo
  RUN apk --no-cache add git bzr mercurial
  RUN go get -u github.com/golang/dep/...
  RUN go get -u github.com/derekparker/delve/cmd/dlv
  RUN go get -u github.com/onsi/ginkgo/ginkgo
  RUN go get -u github.com/onsi/gomega/...
  COPY . $GOPATH/src/github.com/WeConnect/go-project-layout
  WORKDIR $GOPATH/src/github.com/WeConnect/go-project-layout
  RUN dep ensure -v --vendor-only
  RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -installsuffix cgo -ldflags="-w -s" -o cmd/sample/sample cmd/sample/sample.go

FROM scratch AS debug
  LABEL stage=debug
  COPY --from=baseGo /go/src/github.com/WeConnect/go-project-layout .
  COPY --from=baseGo /go/bin/dlv /bin
  WORKDIR $GOPATH/src/github.com/WeConnect/go-project-layout/cmd/sample
  ENTRYPOINT ["dlv debug --headless --api-version=2 --log --listen=127.0.0.1:8181"]

FROM scratch AS mock
  LABEL stage=mock

FROM scratch AS release
  COPY --from=baseGo /go/src/github.com/WeConnect/go-project-layout/cmd/sample/sample /bin
  ENTRYPOINT ["./bin/sample"]

FROM golang:alpine AS dev-env
  LABEL stage=dev-env
  COPY --from=baseGo / /
  WORKDIR $GOPATH/src/github.com/WeConnect/go-project-layout/cmd/sample
  ENTRYPOINT ["./sample"]

FROM golang:alpine AS test
  LABEL stage=test
  COPY --from=release / /
  WORKDIR $GOPATH/src/github.com/WeConnect/go-project-layout
  ENTRYPOINT ["go test"]

FROM release
