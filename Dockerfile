## -*- docker-image-name: "scaleway/ubuntu-coreos:latest" -*-
FROM scaleway/debian:amd64-stretch
# following 'FROM' lines are used dynamically thanks do the image-builder
# which dynamically update the Dockerfile if needed.
#FROM scaleway/debian:armhf-stretch	# arch=armv7l
#FROM scaleway/debian:arm64-stretch	# arch=arm64
#FROM scaleway/debian:i386-stretch		# arch=i386
#FROM scaleway/debian:mips-stretch		# arch=mips
MAINTAINER Maartje Eyskens <maartje@innovatete.ch> (@meyskens)


# Prepare rootfs for image-builder
RUN /usr/local/sbin/builder-enter


# Install packages
RUN apt-get -q update                   \
 && apt-get --force-yes -y -qq upgrade  \
 && apt-get --force-yes install -y -q build-essential tar \
 && apt-get clean

# Install Docker
RUN curl https://get.docker.com | bash

# Install Go
RUN apt-get -y -t jessie-backports install golang-go  && \
    echo "export GOPATH=/usr/src/spouse" >> ~/.bashrc && \
    mkdir /usr/src/spouse

# Install Etcd
RUN cd /usr/src/ && git clone https://github.com/coreos/etcd.git -b release-2.3 && \
    cd /usr/src/etcd && \
    ./build && \
    ln -s /usr/src/etcd/bin/* /usr/bin/ && \
    mkdir /var/lib/etcd

# Install Flannel
RUN export GOPATH=/usr/src/spouse && \
    mkdir -p /usr/src/spouse/src/github.com/coreos/ && \
    cd /usr/src/ && git clone https://github.com/coreos/flannel.git /usr/src/spouse/src/github.com/coreos/flannel && \
    cd /usr/src/spouse/src/github.com/coreos/flannel && git checkout v0.6.2 && \
    go get && \
    make dist/flanneld && \
    ln -s /usr/src/spouse/src/github.com/coreos/flannel/dist/flanneld /usr/bin/flanneld



# Installing UFW
RUN apt-get -y install ufw && \
    ufw default allow incoming

# Installing Dispatch
RUN case "${ARCH}" in                                                                                 \
    armv7l|armhf|arm)                                                                                 \
      curl -Ls https://github.com/innovate-technologies/Dispatch/releases/download/0.0.3/dispatchd-linux-arm > /usr/bin/dispatchd && \
      chmod +x /usr/bin/dispatchd                                                                   \
      ;;                                                                                              \
    amd64|x86_64)                                                                                     \
      curl -Ls https://github.com/innovate-technologies/Dispatch/releases/download/0.0.3/dispatchd-linux-amd64 > /usr/bin/dispatchd && \
      chmod +x /usr/bin/dispatchd                                                                   \
      ;;                                                                                              \
    *)                                                                                                \
      echo "Unhandled architecture: ${ARCH}."; exit 1;                                                \
      ;;                                                                                              \
    esac                                                                                              

COPY ./overlay/ /

RUN systemctl disable docker; systemctl enable docker

# Clean rootfs from image-builder
RUN /usr/local/sbin/builder-leave
