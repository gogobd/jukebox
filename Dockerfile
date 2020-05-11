FROM nvidia/cuda:latest

# Install system dependencies
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        build-essential \
        curl \
        wget \
        git \
        unzip \
        screen \
        vim \
    && apt-get clean

# Install python miniconda3 + requirements
ENV MINICONDA_HOME /opt/miniconda
ENV PATH ${MINICONDA_HOME}/bin:${PATH}
RUN wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    && chmod +x Miniconda3-latest-Linux-x86_64.sh \
    && ./Miniconda3-latest-Linux-x86_64.sh -b -p "${MINICONDA_HOME}" \
    && rm Miniconda3-latest-Linux-x86_64.sh

# Code server
ENV SHELL /bin/bash
RUN wget -q https://github.com/cdr/code-server/releases/download/3.2.0/code-server-3.2.0-linux-x86_64.tar.gz \
    && tar -xzvf code-server-3.2.0-linux-x86_64.tar.gz && chmod +x code-server-3.2.0-linux-x86_64/code-server \
    && rm code-server-3.2.0-linux-x86_64.tar.gz

# Project dependencies
RUN apt-get install -y libsndfile1-dev

COPY . /jukebox
WORKDIR /jukebox

# Required: Sampling
RUN conda install mpi4py=3.0.3 && \
    conda install pytorch=1.4 torchvision=0.5 cudatoolkit=10.0 -c pytorch && \
    pip install -Ur requirements.txt && \
    pip install -e .

# Required: Training
RUN conda install av=7.0.01 -c conda-forge && \
    pip install ./tensorboardX

# Optional: Apex for faster training with fused_adam
# RUN conda install pytorch=1.1 torchvision=0.3 cudatoolkit=10.0 -c pytorch && \
RUN conda install -c conda-forge nvidia-apex

# Start container in notebook mode
CMD \
    /code-server-3.2.0-linux-x86_64/code-server --bind-addr 0.0.0.0:8080 /jukebox/

# docker build -t openai_jukebox .
# docker run -e PASSWORD='yourpassword' -p 6006:6006 -p 8080:8080 --ipc=host --gpus all -it openai_jukebox
