# This line instructs Docker to create a stage of our container called base
FROM golang:1.21.4 as base

# Create another stage called "dev" that is based off of our "base" stage (so we have golang available to us)
FROM base as dev

# Install the air binary so we get live code-reloading when we save files
RUN curl -sSfL https://raw.githubusercontent.com/cosmtrek/air/master/install.sh | sh -s -- -b $(go env GOPATH)/bin

# Run the air command in the directory where our code will live
WORKDIR /opt/app/api
CMD ["air"]

# The first new stage of our container builds our binary using our base stage to ensure we have a Go environment to actually compile the project.
# The next (and final) stage is a minimalistic busybox image that copies in our outputted binary and puts it in a folder that is in the containers $PATH.
FROM base as built

WORKDIR /go/app/api
COPY . .

ENV CGO_ENABLED=0

RUN go get -d -v ./...
RUN go build -o /tmp/api-server ./*.go

FROM busybox

COPY --from=built /tmp/api-server /usr/bin/api-server
CMD ["api-server", "start"]
