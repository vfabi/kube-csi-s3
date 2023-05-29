FROM --platform=$BUILDPLATFORM golang:1.16-alpine as gobuild
# FROM --platform=$BUILDPLATFORM golang:1.19-alpine as gobuild
ARG TARGETARCH

WORKDIR /build
ADD go.mod go.sum /build/
RUN go mod download -x
ADD cmd /build/cmd
ADD pkg /build/pkg
RUN CGO_ENABLED=0 GOOS=linux GOARCH=${TARGETARCH} go build -a -ldflags '-extldflags "-static"' -o ./s3driver ./cmd/s3driver


FROM --platform=$BUILDPLATFORM debian:buster-slim
LABEL maintainers="Vadim Fabi"
LABEL description="kube-csi-s3"

ARG TARGETARCH
# ARG TARGETPLATFORM
# ARG BUILDPLATFORM
ARG RCLONE_VERSION=v1.54.1

# S3FS and some other dependencies
RUN apt-get update && \
  apt-get install -y s3fs curl unzip && \
  rm -rf /var/lib/apt/lists/*

# Rclone
RUN cd /tmp && \
    curl -O https://downloads.rclone.org/${RCLONE_VERSION}/rclone-${RCLONE_VERSION}-linux-${TARGETARCH}.zip && \
    ls -la /tmp && \
    unzip /tmp/rclone-${RCLONE_VERSION}-linux-${TARGETARCH}.zip && \
    mv /tmp/rclone-*-linux-${TARGETARCH}/rclone /usr/bin && \
    rm -r /tmp/rclone*


COPY --from=gobuild /build/s3driver /s3driver
ENTRYPOINT ["/s3driver"]