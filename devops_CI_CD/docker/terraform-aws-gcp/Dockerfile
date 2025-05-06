FROM ubuntu:22.04

USER root

# Install basic tools
RUN apt-get update && apt-get install -y \
    unzip \
    curl \
    wget \
    software-properties-common \
    gnupg \
    lsb-release \
    ca-certificates \
    apt-transport-https \
    git \
    python3-pip

# Install Terraform
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
    > /etc/apt/sources.list.d/hashicorp.list && \
    apt-get update && apt-get install -y terraform

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && ./aws/install && \
    rm -rf awscliv2.zip aws

# Install Google Cloud SDK
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" \
    > /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor \
    -o /usr/share/keyrings/cloud.google.gpg && \
    apt-get update && apt-get install -y google-cloud-sdk

# Clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Set default shell (Jenkins executes commands here)
ENTRYPOINT ["/bin/bash", "-c", "tail -f /dev/null"]
