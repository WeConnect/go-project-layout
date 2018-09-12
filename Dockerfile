FROM golang:alpine AS baseGo
  ENV CGO_ENABLED 0
  RUN apk --no-cache add git bzr mercurial
  RUN go get -u github.com/golang/dep/...
  RUN go get -u github.com/derekparker/delve/cmd/dlv
  COPY . $GOPATH/src/github.com/WeConnect/go-project-layout
  WORKDIR $GOPATH/src/github.com/WeConnect/go-project-layout
  RUN dep ensure -v --vendor-only
  RUN go build -gcflags='all=-N -l' -o sample cmd/sample/sample.go

FROM scratch AS debug
  LABEL stage=debug
  COPY --from=baseGo /go/bin/dlv /
  COPY --from=baseGo /go/src/github.com/WeConnect/go-project-layout/cmd/sample /
  ENTRYPOINT ["/dlv", "--listen=:40000", "--headless=true", "--api-version=2", "exec", "/sample"]

FROM scratch AS mock
  LABEL stage=mock

FROM scratch AS release
  COPY --from=baseGo /go/src/github.com/WeConnect/go-project-layout/cmd/sample/sample /
  ENTRYPOINT ["./sample"]

FROM golang:alpine AS dev-env
  LABEL stage=dev-env
  COPY --from=baseGo /go /go
  WORKDIR $GOPATH/src/github.com/WeConnect/go-project-layout/cmd/sample
  ENTRYPOINT ["./sample"]

FROM release
