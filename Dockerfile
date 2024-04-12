# syntax = docker/dockerfile:experimental
ARG base_image

FROM concourse/golang-builder AS builder
WORKDIR /src
COPY go.mod /src/go.mod
COPY go.sum /src/go.sum
RUN --mount=type=cache,target=/root/.cache/go-build go get -d ./...
COPY . /src
ENV CGO_ENABLED 0
RUN go build -o /assets/task ./cmd/task
RUN go build -o /assets/build ./cmd/build

FROM moby/buildkit:v0.11.0 AS task
COPY --from=builder /assets/task /usr/bin/
COPY --from=builder /assets/build /usr/bin/
COPY bin/setup-cgroups /usr/bin/

FROM $(base_image) as base
COPY --from=task /usr/bin /usr/bin/
ENTRYPOINT ["task"]

FROM base
