# adapted from https://gist.githubusercontent.com/pierreprinetti/eef186f743f31055afb47cd2b50fe3fd/raw/9d52ab93ae5c51a56fe4323712969cba03d14b7f/Dockerfile

# Accept the Go version for the image to be set as a build argument.
# Default to Go 1.11
ARG GO_VERSION=1.11

# First stage: build the executable.
FROM golang:${GO_VERSION}-alpine AS builder

# Create the user and group files that will be used in the running container to
# run the process as an unprivileged user.
RUN mkdir /user && \
    echo 'nobody:x:65534:65534:nobody:/:' > /user/passwd && \
    echo 'nobody:x:65534:' > /user/group

# Install the Certificate-Authority certificates for the app to be able to make
# calls to HTTPS endpoints.
# Git is required for fetching the dependencies.
# tzdata for time module.
RUN apk add --no-cache ca-certificates git tzdata

# Set the working directory outside $GOPATH to enable the support for modules.
WORKDIR /src

# Fetch dependencies first; they are less susceptible to change on every build
# and will therefore be cached for speeding up the next build
COPY ./go.mod ./go.sum ./
RUN go mod download

# Copy the code from the context.
COPY ./*.go ./

# Build the executable to `/app`.
RUN CGO_ENABLED=0 go build \
    -o /app .

# Final stage: the running container.
FROM scratch AS final

# Copy the user and group files from the first stage.
COPY --from=builder /user/group /user/passwd /etc/

# Copy the Certificate-Authority certificates for enabling HTTPS.
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy the tzdata for time.LoadLocation() to work.
COPY --from=builder /usr/share/zoneinfo/ /usr/share/zoneinfo/

# Copy the compiled executable from the first stage.
COPY --from=builder /app /app

# Declare the port on which the webserver will be exposed.
# As we're going to run the executable as an unprivileged user, we can't bind
# to ports below 1024.
EXPOSE 8080

# Perform any further action as an unprivileged user.
USER nobody:nobody

# Run the compiled binary.
ENTRYPOINT ["/app"]