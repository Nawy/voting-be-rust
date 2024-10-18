# Define build arguments
ARG BIN_NAME=votingd
ARG PROJECT_NAME=voting-be

# Use the official Rust image as the base for the build stage
FROM rust:latest AS builder
ARG BIN_NAME
ARG PROJECT_NAME

# Install CA certificates
RUN mkdir -p /usr/local/share/ca-certificates/mycustom

# Set the working directory inside the container
WORKDIR /usr/$PROJECT_NAME

# Copy the Cargo.toml and Cargo.lock files to the container
COPY Cargo.toml Cargo.lock ./

# This build step will cache the dependencies so that they don't get recompiled unless they change
RUN cargo fetch

# Copy the entire project to the container
COPY src/ ./src/

# Build the project in release mode
RUN cargo build --release

# Use a smaller base image for the runtime
FROM debian:bookworm-slim

ARG BIN_NAME
ARG PROJECT_NAME

# Install necessary system dependencies
RUN apt-get update && apt-get install -y libssl-dev ca-certificates && rm -rf /var/lib/apt/lists/*

ENV BIN_NAME=$BIN_NAME
ENV PROJECT_NAME=$PROJECT_NAME

# Copy the build artifact from the builder stage
COPY --from=builder /usr/$PROJECT_NAME/target/release/$BIN_NAME /usr/local/bin/$BIN_NAME

# Set the entrypoint to the application
ENTRYPOINT ["/bin/sh", "-c", "/usr/local/bin/$BIN_NAME"]
