ARG UBUNTU_VERSION=18.04
ARG CUDA=10.1
ARG CUDNN=7.6.5.32

FROM nvidia/cuda:${CUDA}-cudnn7-devel-ubuntu${UBUNTU_VERSION}

ARG HOST_USER="dev"
ARG HOST_UID="1000"
ARG HOST_GID="100"

RUN apt-get update && apt-get install -yq --no-install-recommends \
    git \ 
    wget \
    bzip2 \
    ca-certificates \
    sudo \
    locales \
    fonts-liberation \
    libopenmpi-dev \
    openmpi-bin \
    libgtk2.0-0 \
    xvfb \
    libgconf-2-4 \
    libxtst6 \
    gcc \
    libnvinfer6=6.0.1-1+cuda10.1 \
    libnvinfer-dev=6.0.1-1+cuda10.1 \
    libnvinfer-plugin6=6.0.1-1+cuda10.1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# TODO: Works only sometimes and being build - find out why.
RUN sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' /etc/skel/.bashrc

RUN groupadd -r $HOST_USER \
    && useradd -d /home/$HOST_USER -g $HOST_GID -m -r -u $HOST_UID $HOST_USER

# If you want to make a directory to mount to create one inside workspace OR 
# mount directly to workspace.
WORKDIR /home/$HOST_USER/workspace

ENV HOME=/home/$HOST_USER \
    MINICONDA_VERSION=4.6.14 \
    CONDA_VERSION=4.6.14 \
    CONDA_DIR=/home/$HOST_USER/miniconda
# PATH must have be on its own line or CONDA_DIR will not be recognized
ENV PATH=$CONDA_DIR/bin:$PATH

RUN wget --quiet https://repo.continuum.io/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh && \
    /bin/bash Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh -b -p $CONDA_DIR && \
    rm Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh

COPY ./conda_requirements.txt ./conda_requirements.txt

RUN conda config --system --prepend channels conda-forge \
    && conda config --system --prepend channels anaconda \
    && conda config --system --set auto_update_conda false \
    && conda config --system --set show_channel_urls true  \
    && conda install --quiet --yes conda="${CONDA_VERSION%.*}.*" \
    && conda install --yes --file conda_requirements.txt \
    && conda update --all --quiet --yes \
    && conda clean --all -f -y 

COPY ./pip_requirements.txt ./pip_requirements.txt

RUN pip install --upgrade pip \
    && pip install  -r pip_requirements.txt --no-cache-dir \
    && rm pip_requirements.txt
    
# Move all permissions to HOST_USER
RUN chown -R $HOST_USER:$HOST_GID /home/$HOST_USER/* \
    &&  chown -R $HOST_USER:$HOST_GID /home/$HOST_USER/.[^.]*

USER $HOST_USER

CMD bash
