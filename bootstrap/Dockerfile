# Copyright 2020 Adevinta

FROM alpine
RUN apk add --no-cache --update postgresql-client curl jq
WORKDIR /app
COPY . .
CMD ["./run.sh"]
