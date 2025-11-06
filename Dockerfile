# ComfyUI Docker Build File v1.0.1 by John Aldred
# https://www.johnaldred.com
# https://github.com/kaouthia

# Use a minimal Python base image (adjust version as needed)
FROM python:3.13-slim-bookworm

# Allow passing in your host UID/GID (defaults 1000:1000)
ARG UID=1000
ARG GID=1000

# Install OS deps and 
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      git \
      libgl1 \
      libglx-mesa0 \
      libglib2.0-0 \
      fonts-dejavu-core \
      fontconfig \
      build-essential \
      cmake \
      wget \
      nano \
      acl && \
    wget -nv https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb && \
    dpkg -i cuda-keyring_1.1-1_all.deb && \
    wget https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-wsl-ubuntu.pin && \
    mv cuda-wsl-ubuntu.pin /etc/apt/preferences.d/cuda-repository-pin-600 && \
    wget -nv https://developer.download.nvidia.com/compute/cuda/13.0.2/local_installers/cuda-repo-wsl-ubuntu-13-0-local_13.0.2-1_amd64.deb && \
    dpkg -i cuda-repo-wsl-ubuntu-13-0-local_13.0.2-1_amd64.deb && \
    cp /var/cuda-repo-wsl-ubuntu-13-0-local/cuda-*-keyring.gpg /usr/share/keyrings/ && \
    apt-get update && \
    apt-get install -y cuda-toolkit-13-0 && \
    rm *.deb && \
    rm -rf /var/lib/apt/lists/*

# Create the non-root user
RUN groupadd --gid ${GID} appuser && \
    useradd --uid ${UID} --gid ${GID} --create-home --shell /bin/bash appuser 

# Set the working directory
WORKDIR /app

# Copy and enable the startup script
COPY entrypoint.sh /entrypoint.sh

# Ensure /app has appropriate permissions for the non-root user
RUN chmod +x /entrypoint.sh 
# && \
#     setfacl -R -m u:${UID}:rwx /app && \
#     setfacl -R -m u:${UID}:rwx /usr/local/lib/python3.13/site-packages && \
#     chown -R ${GID}:${UID} /app && chmod -R ug+rw /app

# make ~/.local/bin available on the PATH so scripts like tqdm, torchrun, etc. are found
ENV PATH=/home/appuser/.local/bin:$PATH

# Clone the ComfyUI repository (replace URL with the official repo)
RUN git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git

# Ensure User Directory exists
RUN mkdir -p /app/ComfyUI/user/default/workflows

# Change directory to the ComfyUI folder
WORKDIR /app/ComfyUI

# Install ComfyUI dependencies
RUN pip install -U setuptools wheel && \
    pip install insightface && \
    pip install triton && \
    pip install -U torch torchvision --index-url https://download.pytorch.org/whl/cu130 && \
    pip install --no-cache-dir -r requirements.txt && \
    pip cache purge

# Switch to non-root user
USER $UID:$GID

# Expose the port that ComfyUI will use (change if needed)
EXPOSE 8188

# Run entrypoint first, then start ComfyUI
ENTRYPOINT ["/entrypoint.sh"]
CMD ["python","/app/ComfyUI/main.py","--listen","0.0.0.0"]
#CMD ["python","/app/ComfyUI/main.py","--use-sage-attention","--listen","0.0.0.0"]
