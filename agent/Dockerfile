# Copyright 2020 Adevinta

FROM golang:1.13-alpine

RUN apk add --no-cache --update git

# Download and compile vulcan-agent (for darwin and linux)
RUN mkdir /agent && \
    go get -d github.com/adevinta/vulcan-agent && \
    cd /go/src/github.com/adevinta/vulcan-agent && \
    go mod download && \
    GOOS=darwin GOARCH=amd64 go build -o /agent/vulcan-agent-darwin cmd/vulcan-agent-docker/main.go && \
    GOOS=linux  GOARCH=amd64 CGO_ENABLED=1 go build -a -tags netgo -ldflags '-w' -o /agent/vulcan-agent-linux cmd/vulcan-agent-docker/main.go

WORKDIR /agent

COPY run.sh .

CMD ["./run.sh"]
