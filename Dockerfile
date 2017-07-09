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

#Install golang
RUN echo "deb http://ppa.launchpad.net/longsleep/golang-backports/ubuntu xenial main" >>/etc/apt/sources.list && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 52B59B1571A79DBC054901C0F6BC817356A3D45E  && \
    apt-get update && apt-get install -y golang-1.8 && \
    ln -s /usr/lib/go-1.8/bin/* /usr/bin/

# Install Etcd
RUN cd /usr/src/ && git clone https://github.com/coreos/etcd.git -b release-2.3 && \
    cd /usr/src/etcd && \
    ./build && \
    ln -s /usr/src/etcd/bin/* /usr/bin/ && \
    mkdir /var/lib/etcd

# Install Flannel
RUN export GOPATH=/usr/local/go && \
    mkdir -p /usr/local/go/src/github.com/coreos/ && \
    git clone https://github.com/coreos/flannel.git /usr/local/go/src/github.com/coreos/flannel && \
    cd /usr/local/go/src/github.com/coreos/flannel && git checkout v0.6.2 && \
    go get && \
    make dist/flanneld && \
    ln -s /usr/local/go/src/github.com/coreos/flannel/dist/flanneld /usr/bin/flanneld


# Installing Dispatch
RUN case "${ARCH}" in                                                                                 \
    armv7l|armhf|arm)                                                                                 \
      curl -Ls https://github.com/innovate-technologies/Dispatch/releases/download/0.0.5/dispatchd-linux-arm > /usr/bin/dispatchd && \
      chmod +x /usr/bin/dispatchd                                                                   \
      ;;                                                                                              \
    amd64|x86_64)                                                                                     \
      curl -Ls https://github.com/innovate-technologies/Dispatch/releases/download/0.0.5/dispatchd-linux-amd64 > /usr/bin/dispatchd && \
      chmod +x /usr/bin/dispatchd                                                                   \
      ;;                                                                                              \
    *)                                                                                                \
      echo "Unhandled architecture: ${ARCH}."; exit 1;                                                \
      ;;                                                                                              \
    esac    

# Installing Dispatchctl
RUN case "${ARCH}" in                                                                                 \
    armv7l|armhf|arm)                                                                                 \
      curl -Ls https://github.com/innovate-technologies/Dispatch/releases/download/0.0.4/dispatchctl-linux-arm > /usr/bin/dispatchctl && \
      chmod +x /usr/bin/dispatchctl                                                                   \
      ;;                                                                                              \
    amd64|x86_64)                                                                                     \
      curl -Ls https://github.com/innovate-technologies/Dispatch/releases/download/0.0.4/dispatchctl-linux-amd64 > /usr/bin/dispatchctl && \
      chmod +x /usr/bin/dispatchctl                                                                   \
      ;;                                                                                              \
    *)                                                                                                \
      echo "Unhandled architecture: ${ARCH}."; exit 1;                                                \
      ;;                                                                                              \
    esac                                                                                              

COPY ./overlay/ /

RUN systemctl disable docker; systemctl enable docker

# Clean rootfs from image-builder
RUN /usr/local/sbin/builder-leave
