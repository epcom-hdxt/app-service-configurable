#
# Copyright (c) 2019 Intel Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# wp 20200308 mac update

#build stage
ARG BASE=golang:1.15-alpine3.12
FROM ${BASE} AS builder

ARG ALPINE_PKG_BASE="make git gcc libc-dev libsodium-dev zeromq-dev"
ARG ALPINE_PKG_EXTRA=""

LABEL license='SPDX-License-Identifier: Apache-2.0' \
    copyright='Copyright (c) 2019: Intel'
RUN sed -e 's/dl-cdn[.]alpinelinux.org/mirrors.ustc.edu.cn/g' -i~ /etc/apk/repositories
RUN apk add --update --no-cache ${ALPINE_PKG_BASE} ${ALPINE_PKG_EXTRA}
ENV CGO_ENABLED=1 \
#    GO_EXTRA_BUILD_ARGS="-a -installsuffix cgo" \
    GOOS=linux \
    # GOARCH=arm64 \
    GOPROXY=https://goproxy.cn 
WORKDIR /app

COPY go.mod .
#RUN go env -w GOPRIVATE=github.com/epcom-hdxt/app-functions-sdk-go
# RUN git config --global url.https://github.com/epcom-hdxt/app-functions-sdk-go.insteadof ssh:git@github.com/epcom-hdxt/app-functions-sdk-go
RUN go mod download

COPY . .

ARG MAKE="make build"
RUN $MAKE

#final stage
FROM alpine:3.12
LABEL license='SPDX-License-Identifier: Apache-2.0' \
  copyright='Copyright (c) 2019: Intel'
LABEL Name=app-service-configurable Version=${VERSION}

RUN apk add --update --no-cache ca-certificates zeromq

COPY --from=builder /app/Attribution.txt /Attribution.txt
COPY --from=builder /app/LICENSE /LICENSE
COPY --from=builder /app/res/ /res/
COPY --from=builder /app/app-service-configurable /app-service-configurable

EXPOSE 48095

# Must always specify the profile using
# environment:
#   - EDGEX_PROFILE: <profile>
# or use
# command: "-profile=<profile>"
# If not you will recive error:
# SDK initialization failed: Could not load configuration file (./res/configuration.toml)...

ENTRYPOINT ["/app-service-configurable"]
CMD ["-cp=consul.http://edgex-core-consul:8500", "--registry", "--confdir=/res"]

