# Build
#   docker build -f Dockerfile --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') -t luri/free-pascal .
# Build multi-arch Docker image
#   docker buildx build --platform linux/amd64,linux/arm64 -t luri/free-pascal:multiarch --push .

FROM ubuntu:20.04

SHELL ["/bin/bash", "-c"]

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq && \
    apt-get install -y build-essential binutils wget tzdata && \
    apt-get install -y apache2 git curl libtool zip nano sshpass ftp lftp && \
    apt-get install --fix-missing && \
    apt-get clean

# Apache Setup
ADD config/apache/000-default.conf /etc/apache2/sites-enabled/
RUN a2enmod cgi \
  && ln -s /etc/apache2/mods-available/rewrite.load /etc/apache2/mods-enabled/ \
  && ln -s /etc/apache2/mods-available/headers.load /etc/apache2/mods-enabled/ \
  && echo "Free Pascal for Docker" > /var/www/html/index.html \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Make port 80 available to the world outside this container
EXPOSE 80
EXPOSE 443

RUN mkdir -p /projects/
WORKDIR /projects
ADD ./app/ /app

ENV FPC_VERSION="3.2.2"

# Install Free Pascal dengan dukungan multi-arch
#RUN ARCH=$(uname -m)-linux && \
RUN ARCH=$(dpkg --print-architecture) && \
    cd /tmp && \
    if [ "$ARCH" = "amd64" ]; then \
        wget "https://onboardcloud.dl.sourceforge.net/project/freepascal/Linux/${FPC_VERSION}/fpc-${FPC_VERSION}.x86_64-linux.tar" -O fpc.tar; \
    elif [ "$ARCH" = "arm64" ]; then \
        wget "https://onboardcloud.dl.sourceforge.net/project/freepascal/Linux/${FPC_VERSION}/fpc-${FPC_VERSION}.aarch64-linux.tar" -O fpc.tar; \
    else \
        echo "Architecture not supported!" && exit 1; \
    fi && \
    tar xf fpc.tar && \
    cd fpc-${FPC_VERSION}* && \
    rm demo* doc* && \
    echo -e '\n' | ./install.sh && \
    rm -r /tmp/*


# FPC Download alternative
# - wget "ftp://ftp.freepascal.org/pub/fpc/dist/${FPC_VERSION}/${ARCH}/fpc-${FPC_VERSION}?${ARCH}.tar" -O fpc.tar && \
# - wget "https://onboardcloud.dl.sourceforge.net/project/freepascal/Linux/${FPC_VERSION}/fpc-${FPC_VERSION}.${ARCH}.tar" -O fpc.tar && \
# - wget "http://downloads.freepascal.org/fpc/dist/${FPC_VERSION}/${ARCH}/fpc-${FPC_VERSION}.${ARCH}.tar" -O fpc.tar && \
