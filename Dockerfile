FROM ubuntu:latest

### Install Julia ###

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		ca-certificates \
		curl \
    apt-utils
RUN apt-get install -y gpg
ENV JULIA_PATH /usr/local/julia

# https://julialang.org/juliareleases.asc
# Julia (Binary signing key) <buildbot@julialang.org>
ENV JULIA_GPG 3673DF529D9049477F76B37566E3C7DC03D6E495

# https://julialang.org/downloads/
ENV JULIA_VERSION 0.6.2

RUN set -ex; \
	\
# https://julialang.org/downloads/#julia-command-line-version
# https://julialang-s3.julialang.org/bin/checksums/julia-0.6.2.sha256
# this "case" statement is generated via "update.sh"
	dpkgArch="$(dpkg --print-architecture)"; \
	case "${dpkgArch##*-}" in \
		amd64) tarArch='x86_64'; dirArch='x64'; sha256='dc6ec0b13551ce78083a5849268b20684421d46a7ec46b17ec1fab88a5078580' ;; \
		armhf) tarArch='armv7l'; dirArch='armv7l'; sha256='1c37aa7cba7372d949a91de53f53609b1b0c9cbeca436eb2fe7f5083d9f62c82' ;; \
		arm64) tarArch='aarch64'; dirArch='aarch64'; sha256='19a8945bdb3d35b7bf0432a9e066fb7831d11d1c1acfe56abd8fcabbf1ebddb4' ;; \
		i386) tarArch='i686'; dirArch='x86'; sha256='099e39ad958aff2ef63841a812f5df62f8553aafc6dd33abb0eb0c67142c5e49' ;; \
		*) echo >&2 "error: current architecture ($dpkgArch) does not have a corresponding Julia binary release"; exit 1 ;; \
	esac; \
	\
	curl -fL -o julia.tar.gz     "https://julialang-s3.julialang.org/bin/linux/${dirArch}/${JULIA_VERSION%[.-]*}/julia-${JULIA_VERSION}-linux-${tarArch}.tar.gz"; \
	curl -fL -o julia.tar.gz.asc "https://julialang-s3.julialang.org/bin/linux/${dirArch}/${JULIA_VERSION%[.-]*}/julia-${JULIA_VERSION}-linux-${tarArch}.tar.gz.asc"; \
	\
	echo "${sha256} *julia.tar.gz" | sha256sum -c -; \
	\
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$JULIA_GPG"; \
	gpg --batch --verify julia.tar.gz.asc julia.tar.gz; \
	rm -rf "$GNUPGHOME" julia.tar.gz.asc; \
	\
	mkdir "$JULIA_PATH"; \
	tar -xzf julia.tar.gz -C "$JULIA_PATH" --strip-components 1; \
	rm julia.tar.gz


ENV PATH $JULIA_PATH/bin:$PATH

CMD ["julia"]


### custom ###

RUN apt-get update && apt-get -y install apt-utils
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

# Setup julia packages
COPY ./src/env_setup.jl /htm.jl/src/
RUN julia -e 'include("/htm.jl/src/env_setup.jl")'

# Additional julia-related system packages
RUN sudo apt-get -y install \
    libxt6 libxrender1 libgl1-mesa-glx \
    x11-apps mesa-utils libqt5widgets5 python-qt4-dev libglfw3-dev libwxgtk3.0-dev libzmq3-dev

WORKDIR "/htm.jl/src"
CMD ["julia"]
