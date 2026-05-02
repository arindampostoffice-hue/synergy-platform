FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /work-graph-service .

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=builder /work-graph-service /work-graph-service
EXPOSE 8080
USER nonroot:nonroot
ENTRYPOINT ["/work-graph-service"]
