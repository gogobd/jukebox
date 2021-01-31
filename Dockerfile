FROM nvidia/cuda

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

COPY . /app
WORKDIR /app

## Code server
RUN mkdir -p ~/.local/lib ~/.local/bin
RUN curl -fL https://github.com/cdr/code-server/releases/download/v3.8.0/code-server-3.8.0-linux-amd64.tar.gz | tar -C ~/.local/lib -xz
RUN mv ~/.local/lib/code-server-3.8.0-linux-amd64 ~/.local/lib/code-server-3.8.0
RUN ln -s ~/.local/lib/code-server-3.8.0/bin/code-server ~/.local/bin/code-server
RUN PATH="~/.local/bin:$PATH"

# Fix broken python plugin # https://github.com/cdr/code-server/issues/2341
RUN mkdir -p ~/.local/share/code-server/ && mkdir -p ~/.local/share/code-server/User && echo "{\"extensions.autoCheckUpdates\": false, \"extensions.autoUpdate\": false}" > ~/.local/share/code-server/User/settings.json 
RUN wget https://github.com/microsoft/vscode-python/releases/download/2020.10.332292344/ms-python-release.vsix \
 && ~/.local/bin/code-server --install-extension ./ms-python-release.vsix || true

# Correct version for python
RUN conda create -n app_python python=3.7
SHELL ["conda", "run", "-n", "app_python", "/bin/bash", "-c"]

# Required: Sampling
RUN conda install pysoundfile=0.10.3.post1 mpi4py=3.0.3 pytorch=1.4 torchvision=0.5 cudatoolkit=10.0 -c pytorch -c conda-forge
RUN cd /app && pip install -r requirements.txt && pip install -e .

# if this fails, try: pip install mpi4py==3.0.3

# Required: Training
RUN conda install av=7.0.01 -c conda-forge 
RUN pip install ./tensorboardX
 
## Optional: Apex for faster training with fused_adam
#RUN conda install pytorch=1.1 torchvision=0.3 cudatoolkit=10.0 -c pytorch
#RUN pip install -v --no-cache-dir --global-option="--cpp_ext" --global-option="--cuda_ext" ./apex

CMD ~/.local/bin/code-server --bind-addr 0.0.0.0:8080 /app

# docker build -t jukebox .
# docker run -v /host/directory/data:/data -p 8080:8080 -p 5001:5000 --ipc=host --gpus all -e SHELL=/bin/bash -it jukebox

