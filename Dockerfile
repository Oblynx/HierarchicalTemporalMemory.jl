FROM fedora:latest

### Install Julia ###
RUN dnf install -y \
    cmake \
    curl \
    findutils \
    gcc \
    gcc-c++ \
    gcc-gfortran \
    git \
    m4 \
    make \
    patch \
    perl \
    pkgconfig \
    python \
    wget \
    which \
    xz \
    openssl \
    bzip2 \
    && dnf clean all

ENV JULIA_PATH /usr/local/julia
RUN cd /tmp && \
    git clone https://github.com/JuliaLang/julia.git && \
    cd /tmp/julia && \
    git checkout release-0.6 && \
    echo 'MARCH=native' >> Make.user && \
    echo "prefix=$JULIA_PATH" >> Make.user && \
    mkdir "$JULIA_PATH";
RUN cd /tmp/julia && \
    make -j8 && \
    make install && \
    cd /tmp && \
    rm -rf julia

ENV PATH $JULIA_PATH/bin:$PATH
CMD ["julia"]


### custom ###

RUN dnf update -y && dnf install -y sudo

RUN export uid=1000 gid=1000 && \
    mkdir -p "/home/developer" && \
    echo "developer:x:${uid}:${gid}:Developer,,,:/home/developer:/bin/bash" >> /etc/passwd && \
    echo "developer:x:${uid}:" >> /etc/group && \
    echo "developer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer && \
    chown ${uid}:${gid} -R /home/developer
USER developer
ENV HOME /home/developer

# Setup julia packages
COPY ./src/env_setup.jl /htm.jl/src/
RUN julia -e 'include("/htm.jl/src/env_setup.jl")'

# Setup GR
RUN sudo dnf install -y \
    python-matplotlib ipython \
    texlive-collection-latex PyQt4-devel wxGTK-devel ghostscript-devel \
    glfw-devel zeromq-devel mupdf-devel jbig2dec-devel openjpeg2-devel \
    libjpeg-turbo-devel

WORKDIR "/htm.jl/src"
CMD ["julia"]
