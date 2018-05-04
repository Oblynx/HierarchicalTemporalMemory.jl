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

# New user is added to have the same uid as the X11 socket expects
RUN export uid=1000 gid=1000 && \
    mkdir -p "/home/developer" && \
    echo "developer:x:${uid}:${gid}:Developer,,,:/home/developer:/bin/bash" >> /etc/passwd && \
    echo "developer:x:${uid}:" >> /etc/group && \
    echo "developer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer && \
    chown ${uid}:${gid} -R /home/developer && \
    cp /root/.bash* /home/developer/ && \
    chown -R developer:developer /home/developer
USER developer
ENV HOME /home/developer

# Setup GR (huge libs...)
RUN sudo dnf install -y \
    python-matplotlib ipython \
    PyQt4-devel wxGTK-devel ghostscript-devel \
    glfw-devel zeromq-devel mupdf-devel jbig2dec-devel openjpeg2-devel libjpeg-turbo-devel
    #texlive-collection-latex \

# Setup julia packages
RUN julia -e 'Pkg.init()'
COPY ./REQUIRE /home/developer/.julia/v0.6/REQUIRE
COPY ./test/REQUIRE /home/developer/.julia/v0.6/test_REQUIRE
RUN sudo chown -R developer:developer /home/developer
RUN cat /home/developer/.julia/v0.6/test_REQUIRE >> /home/developer/.julia/v0.6/REQUIRE && \
    julia -e 'Pkg.resolve()'

WORKDIR "/htm.jl/"
CMD ["julia"]
