# ComfyUI Docker Build File v1.0.1 by John Aldred
# https://www.johnaldred.com
# https://github.com/kaouthia

# Use a minimal Python base image (adjust version as needed)
FROM python:3.12-slim-bookworm

# Allow passing in your host UID/GID (defaults 1000:1000)
ARG UID=1000
ARG GID=1000

# Install OS deps and create the non-root user
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      git \
      libgl1 \
      libglx-mesa0 \
      libglib2.0-0 \
      fonts-dejavu-core \
      fontconfig \
      build-essential \
      cmake \
 && groupadd --gid ${GID} appuser \
 && useradd --uid ${UID} --gid ${GID} --create-home --shell /bin/bash appuser \
 && rm -rf /var/lib/apt/lists/*

RUN pip install insightface 

 # Copy and enable the startup script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Switch to non-root user
USER $UID:$GID

# make ~/.local/bin available on the PATH so scripts like tqdm, torchrun, etc. are found
ENV PATH=/home/appuser/.local/bin:$PATH

# Set the working directory
WORKDIR /app

# Clone the ComfyUI repository (replace URL with the official repo)
RUN git clone https://github.com/comfyanonymous/ComfyUI.git

# Ensure User Directory exists
RUN mkdir -p /app/ComfyUI/user/default/workflows

# Change directory to the ComfyUI folder
WORKDIR /app/ComfyUI

# Install ComfyUI dependencies
# (Optional) Clean up pip cache to reduce image size
RUN pip install -U pip setuptools wheel && \
    pip install --no-cache-dir -r requirements.txt && \
    pip install triton && \
    pip cache purge

# Install Sage Attention from source
#RUN pip install sage-attention 
RUN git clone https://github.com/thu-ml/SageAttention.git && \
    cd SageAttention  && \
    export EXT_PARALLEL=4 NVCC_APPEND_FLAGS="--threads 8" MAX_JOBS=32 # Optional && \
    python setup.py install && \
    cd .. && \
    pip cache purge

# Expose the port that ComfyUI will use (change if needed)
EXPOSE 8188

# Run entrypoint first, then start ComfyUI
ENTRYPOINT ["/entrypoint.sh"]
CMD ["python","/app/ComfyUI/main.py","--listen","0.0.0.0"]
#CMD ["python","/app/ComfyUI/main.py","--use-sage-attention","--listen","0.0.0.0"]
