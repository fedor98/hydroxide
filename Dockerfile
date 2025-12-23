################################################%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
######
######
######	Dockerfile for Hydroxide / Proton Mail Server
######
######
################################################%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


################################################%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
###### Build Hydroxide	
################################################%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# builder OS
FROM golang:1-alpine AS builder

# update / dependencies  
RUN apk --update upgrade \
&& apk --no-cache --no-progress add git make gcc musl-dev \
&& rm -rf /var/cache/apk/*

# docker container settings
ENV GOPATH=/go

# copy source code into builder
WORKDIR /src
COPY . .

# Patch for iOS/macOS to work with Hydroxide
#   remove the following logic: if wantValue == "" && len(values) == 0
RUN sed -i \
  -e '/if wantValue == "" && len(values) == 0 {/{n;d}' \
  -e '/if wantValue == "" && len(values) == 0 {/d' \
  imap/mailbox.go

# build hydroxide
RUN go build ./cmd/hydroxide && go install ./cmd/hydroxide


################################################%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
###### Copy to container
################################################%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# container OS
FROM alpine:3.9

USER root

EXPOSE 1025
EXPOSE 1143

# update / dependencies
RUN apk --update upgrade \
    && apk --no-cache add ca-certificates bash openrc \
    && rm -rf /var/cache/apk/*

# email variables; either pass these from your docker-compose file OR uncomment and insert below
#ENV HYDROXIDEUSER you@youremail.here
#ENV HYDROXIDEPASS yourPasswordHere 

# copy hydroxide
COPY --from=builder /go/bin/hydroxide /usr/bin/hydroxide

COPY ./docker_shell_scripts/start.sh /start.sh
RUN chmod +x /start.sh

WORKDIR /

ENTRYPOINT ["/start.sh"] 
