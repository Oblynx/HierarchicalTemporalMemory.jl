FROM julia:latest

RUN apt-get update
RUN apt-get -y install apt-utils
RUN apt-get -y install sudo

RUN export uid=1000 gid=1000 && \
    mkdir -p "/home/developer" && \
    echo "developer:x:${uid}:${gid}:Developer,,,:/home/developer:/bin/bash" >> /etc/passwd && \
    echo "developer:x:${uid}:" >> /etc/group && \
    echo "developer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer && \
    chown ${uid}:${gid} -R /home/developer
USER developer
ENV HOME /home/developer

WORKDIR "/htm.jl/src"
CMD ["julia"]
