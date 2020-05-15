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
        net-tools \
    && apt-get clean

# Install python miniconda3 + requirements
ENV MINICONDA_HOME /opt/miniconda
ENV PATH ${MINICONDA_HOME}/bin:${PATH}
RUN wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    && chmod +x Miniconda3-latest-Linux-x86_64.sh \
    && ./Miniconda3-latest-Linux-x86_64.sh -b -p "${MINICONDA_HOME}" \
    && rm Miniconda3-latest-Linux-x86_64.sh

# JupyterLab
RUN conda install -c conda-forge jupyterlab 

# Project dependencies
RUN apt-get install -y libsndfile1-dev

COPY . /jukebox
WORKDIR /jukebox

# Required: Sampling
RUN conda install mpi4py=3.0.3 && \
    conda install pytorch=1.4 torchvision=0.5 cudatoolkit=10.0 -c pytorch && \
    conda install -c conda-forge tensorboardx av=7.0.01 && \
    pip install -Ur requirements.txt && \
    pip install -e .

# # Optional: Apex for faster training with fused_adam
# RUN conda install -c conda-forge nvidia-apex

# Start container in notebook mode
CMD python -m http.server & jupyter lab --no-browser --ip 0.0.0.0 --port 8888 --allow-root

# docker build -t jukebox_nb .
# docker run -v /host/directory/data:/data -p 8000:8000 -p 8888:8888 --ipc=host --gpus all -e SHELL=/bin/bash -it jukebox_nb
