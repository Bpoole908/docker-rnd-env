version=${1-latest}  
user=${2-1000:100}  

alias make="docker run \
    --volume=$(pwd)/mnt:/home/dev/workspace \
    --volume=/tmp/.X11-unix:/tmp/.X11-unix \
    --volume=/etc/localtime:/etc/localtime:ro \
    --name rnd-env \
    --user $user \
    --gpus 1 \
    -dit \
    -p 8888:8888 \
    -p 0.0.0.0:6006:6006 \
    -e DISPLAY=unix$DISPLAY \
    bpoole908/base-rnd-env:$version"

alias attach="docker run \
    --volume=$(pwd)/mnt:/home/dev/workspace \
    --volume=/tmp/.X11-unix:/tmp/.X11-unix \
    --volume=/etc/localtime:/etc/localtime:ro \
    --rm \
    --name rnd-env-tmp \
    --user $user \
    --gpus 1 \
    -dit \
    -e DISPLAY=unix$DISPLAY \
    -p 8888:8888 \
    -p 6006:6006 \
    bpoole908/base-rnd-env:$version \
    && docker attach rnd-env-tmp"