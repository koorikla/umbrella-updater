FROM alpine:latest

# Install dependencies
RUN apk add --no-cache bash yq && \
    apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/community helm

# Copy the script to the container
COPY script.sh /usr/local/bin/

# Set the working directory
WORKDIR /usr/local/bin

# Make the script executable
RUN chmod +x script.sh

# Set the entrypoint to the script
ENTRYPOINT ["./script.sh"]