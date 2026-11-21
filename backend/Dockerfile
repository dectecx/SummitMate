# syntax=docker/dockerfile:1
# Build context: backend/ (docker build -t summitmate-api backend)

FROM golang:1.27.4-alpine3.24 AS build
WORKDIR /src
ENV CGO_ENABLED=0
COPY go.mod go.sum ./
RUN go mod download
COPY . .
# Static binaries: api (HTTP server) and migrate (applies migrations/000001_init_schema.up.sql).
RUN go build -trimpath -ldflags="-s -w" -o /out/api ./cmd/api \
 && go build -trimpath -ldflags="-s -w" -o /out/migrate ./cmd/migrate

# distroless has no shell or curl, so no HEALTHCHECK here (Cloud Run does its own probes).
FROM gcr.io/distroless/static-debian13:nonroot
WORKDIR /app
COPY --from=build /out/api /out/migrate /app/
# `migrate` reads the SQL file relative to the working directory (/app).
COPY migrations /app/migrations
USER nonroot:nonroot
EXPOSE 8080
ENTRYPOINT ["/app/api"]
