# syntax=docker/dockerfile:experimental
FROM ubuntu:jammy

# Install system packages
RUN set -ex && \
    export DEBIAN_FRONTEND=noninteractive && \
    apt-get update -yq && \
    apt-get upgrade -yq && \
    apt-get install -yq --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        python2.7 \
        python2.7-dev \
        libpython2.7 \
        sqlite \
        libsqlite3-dev \
        libssl-dev \
        net-tools \
        swig \
        wget

# Workaround to get libssl1.1 in Ubuntu 22 - https://askubuntu.com/questions/1403619/mongodb-install-fails-on-ubuntu-22-04-depends-on-libssl1-1-but-it-is-not-insta
RUN wget --no-verbose http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2_amd64.deb && \
    dpkg -i libssl1.1_1.1.1f-1ubuntu2_amd64.deb && \
    rm libssl1.1_1.1.1f-1ubuntu2_amd64.deb

# APT cleanup
RUN apt-get autoremove -yq && \
    apt-get clean -yq && \
    rm -rf /var/lib/apt/lists/* /var/cache/*

# Manual install of pip as python2-pip no longer exists in Ubuntu 22
RUN curl -s https://bootstrap.pypa.io/pip/2.7/get-pip.py | /usr/bin/python2.7

# Manual install of APSW as python2-apsw no longer exists in Ubuntu 22
# Using version of APSW which still supports Python 2 (at least this is my assumption, this step is taken from AUR acestream-engine package)
# Taking from GitHub archive and then building as this version doesn't seem to be on PyPi
RUN wget --no-verbose https://github.com/rogerbinns/apsw/archive/3.33.0-r1.tar.gz && \
    tar -xzvf 3.33.0-r1.tar.gz && \
    rm 3.33.0-r1.tar.gz && \
    cd apsw-3.33.0-r1 && \
    /usr/bin/python2.7 setup.py build && \
    /usr/bin/python2.7 setup.py install && \
    cd .. && \
    rm -r apsw-3.33.0-r1

# Install other "python2-*" required packages no longer available in Ubuntu (setuptools seems to be already included in the get-pip.py install)
RUN /usr/bin/python2.7 -m pip install m2crypto lxml

# Install Ace Stream
# https://wiki.acestream.media/Download#Linux
RUN mkdir -p /opt/acestream && \
    wget --no-verbose --output-document acestream.tgz "https://download.acestream.media/linux/acestream_3.1.49_ubuntu_18.04_x86_64.tar.gz" && \
    echo "d2ed7bdc38f6a47c05da730f7f6f600d48385a7455d922a2688f7112202ee19e acestream.tgz" | sha256sum --check && \
    tar --extract --gzip --directory /opt/acestream --file acestream.tgz && \
    rm -rf acestream.tgz && \
    /opt/acestream/start-engine --version

# Acestream 3.1.49 install is missing library files,
# but we can grab these from a previous release.
# http://oldforum.acestream.media/index.php?topic=12448.msg26872
RUN wget --no-verbose --output-document acestream.tgz "https://download.acestream.media/linux/acestream_3.1.16_ubuntu_16.04_x86_64.tar.gz" && \
    echo "452bccb8ae8b5ff4497bbb796081dcf3fec2b699ba9ce704107556a3d6ad2ad7 acestream.tgz" | sha256sum --check && \
    tar --extract --gzip --strip-components 1 --directory /tmp --file acestream.tgz && \
    cp /tmp/lib/acestreamengine/py*.so /opt/acestream/lib/acestreamengine/ && \
    cp /tmp/lib/*.so* /usr/lib/x86_64-linux-gnu/ && \
    rm -rf tmp/* acestream.tgz

# Overwrite disfunctional Ace Stream web player with a working videojs player,
# Access at http://127.0.0.1:6878/webui/player/<acestream id>
COPY player.html /opt/acestream/data/webui/html/player.html

# Prep dir
RUN mkdir /acelink

COPY acestream.conf /opt/acestream/acestream.conf
ENTRYPOINT ["/opt/acestream/start-engine", "@/opt/acestream/acestream.conf"]

HEALTHCHECK CMD wget -q -t1 -O- 'http://127.0.0.1:6878/webui/api/service?method=get_version' | grep '"error": null'

EXPOSE 6878
EXPOSE 8621
