FROM ubuntu:22.04

USER root

# ---------- Install basic tools and Python3/pip ----------
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
    python3-pip \
    sshpass \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# ---------- Install Ansible and Collections for AWS & GCP ----------
RUN pip3 install --upgrade pip setuptools wheel \
 && pip3 install ansible \
 && ansible-galaxy collection install amazon.aws google.cloud community.general

# ---------- Install AWS CLI v2 ----------
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
 && unzip awscliv2.zip \
 && ./aws/install \
 && rm -rf awscliv2.zip aws

# ---------- Install Google Cloud SDK ----------
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" \
      > /etc/apt/sources.list.d/google-cloud-sdk.list \
 && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg \
      | gpg --dearmor > /usr/share/keyrings/cloud.google.gpg \
 && apt-get update \
 && apt-get install -y google-cloud-sdk \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# ---------- Default command to keep container alive ----------
     
ENTRYPOINT ["/bin/bash", "-c", "tail -f /dev/null"]

    
