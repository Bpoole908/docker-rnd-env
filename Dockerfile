ARG UBUNTU_VERSION=18.04
ARG CUDA=10.1
ARG CUDNN=7.6.5.32

FROM nvidia/cuda:${CUDA}-cudnn7-runtime-ubuntu${UBUNTU_VERSION}

ARG HOST_USER="dev"
ARG HOST_UID="1000"
ARG HOST_GID="100"

RUN apt-get update && apt-get install -yq --no-install-recommends \
    git \ 
    wget \
    ca-certificates \
    locales \
    fonts-liberation \
    libopenmpi-dev \
    gcc \
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

RUN conda config --system --prepend channels conda-forge \
    && conda config --system --prepend channels anaconda \
    && conda config --system --set auto_update_conda false \
    && conda config --system --set show_channel_urls true  \
    && conda install --quiet --yes conda="${CONDA_VERSION%.*}.*" \
    && conda update --all --quiet --yes \
    && conda clean --all -f -y 

COPY ./requirements.txt ./requirements.txt

RUN pip install --upgrade pip \
    && pip install  -r requirements.txt --no-cache-dir \
    && rm requirements.txt
    
# Move all permissions to HOST_USER
RUN chown -R $HOST_USER:$HOST_GID /home/$HOST_USER/* \
    &&  chown -R $HOST_USER:$HOST_GID /home/$HOST_USER/.[^.]*

USER $HOST_USER

CMD bash
