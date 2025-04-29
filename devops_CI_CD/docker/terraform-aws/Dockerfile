# Base image: Jenkins inbound-agent
FROM jenkins/inbound-agent:latest

USER root

# ---------- Install basic tools ----------
RUN apt-get update && apt-get install -y \
    unzip \
    curl \
    wget \
    software-properties-common \
    gnupg \
    lsb-release \
    ca-certificates \
    apt-transport-https

# ---------- Install Terraform ----------
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor > /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" > /etc/apt/sources.list.d/hashicorp.list && \
    apt-get update && apt-get install -y terraform

# ---------- Install AWS CLI ----------
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws

# ---------- Clean up to reduce image size ----------
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Switch back to Jenkins user
USER jenkins
