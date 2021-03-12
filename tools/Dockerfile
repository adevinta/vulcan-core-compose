# Copyright 2021 Adevinta

FROM golang:1.13-alpine

# https://dl.min.io/client/mc/release/linux-amd64/mc
# In current repository:
# sha1sum mc
# 085ac3f94dadd15b85ec133506bab606d99d09eb

RUN apk add --no-cache --update curl jq git 

WORKDIR /tools
# Download, compile and install vulcan-core-cli
RUN git clone https://github.com/adevinta/vulcan-core-cli
RUN cd vulcan-core-cli && go mod download && go get ./... && cd -
# Download, compile and install security-overview
RUN apk add --no-cache --update git && git clone https://github.com/adevinta/security-overview
RUN cd security-overview && go mod download && go get ./... && cd -
RUN mv security-overview/_public_resources security-overview/resources ./

COPY . .

CMD ["./run.sh"]