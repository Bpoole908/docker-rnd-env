ARG UBUNTU_VERSION=18.04
ARG CUDA=10.1
ARG CUDNN=7.6.5.32

FROM nvidia/cuda:${CUDA}-cudnn7-devel-ubuntu${UBUNTU_VERSION}

ARG HOST_USER="dev"
ARG HOST_UID="1000"
ARG HOST_GID="100"

ENV HOME=/home/$HOST_USER \
    MINICONDA_VERSION=4.6.14 \
    CONDA_VERSION=4.6.14 \
    CONDA_DIR=/home/$HOST_USER/miniconda
# PATH must have be on its own line or CONDA_DIR will not be recognized
ENV PATH=$CONDA_DIR/bin:$PATH

RUN groupadd -r $HOST_USER \
    && useradd -d /home/$HOST_USER -g $HOST_GID -m -r -u $HOST_UID $HOST_USER \
    && mkdir $HOME/workspace/ \
    && chown $HOST_USER:$HOST_GID $HOME/workspace/

# If you want to make a directory to mount to create one inside workspace OR 
# mount directly to workspace.
WORKDIR /home/$HOST_USER/workspace

RUN apt-get update && apt-get install -yq --no-install-recommends \
    vim \
    ssh \
    git \ 
    curl \
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
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && curl -sSL https://repo.continuum.io/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh -o miniconda.sh \
    && chown $HOST_USER:$HOST_GID ./miniconda.sh  

USER $HOST_USER
# RUN wget --quiet https://repo.continuum.io/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh && \
#     /bin/bash Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh -b -p $CONDA_DIR && \
#     rm Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh

RUN /bin/bash ./miniconda.sh -bp $CONDA_DIR \
    && rm miniconda.sh

COPY --chown=$HOST_USER ./conda_requirements.txt ./conda_requirements.txt

RUN conda config --system --prepend channels conda-forge \
    && conda config --system --prepend channels anaconda \
    && conda config --system --set auto_update_conda false \
    && conda config --system --set show_channel_urls true  \
    && conda install --quiet --yes conda="${CONDA_VERSION%.*}.*" \
    && conda install --yes --file conda_requirements.txt \
    && conda update --all --quiet --yes \
    && conda clean --all -f -y 

COPY --chown=$HOST_USER ./pip_requirements.txt ./pip_requirements.txt

RUN pip install --upgrade pip \
    && pip install  -r pip_requirements.txt --no-cache-dir \
    && rm pip_requirements.txt
    
# # Move all permissions to HOST_USER
# RUN chown -R $HOST_USER:$HOST_GID /home/$HOST_USER/* \
#     &&  chown -R $HOST_USER:$HOST_GID /home/$HOST_USER/.[^.]*

ENV SHELL=/bin/bash

RUN echo 'export PS1="\[🐳\] \[\033[1;36m\]\u@\[\033[1;32m\]\h:\[\033[1;34m\]\w\[\033[0m\]\$ "' >> $HOME/.bashrc

CMD bash
