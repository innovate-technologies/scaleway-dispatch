## -*- docker-image-name: "scaleway/ubuntu-coreos:latest" -*-
# following 'FROM' lines are used dynamically thanks do the image-builder
# which dynamically update the Dockerfile if needed.
#FROM scaleway/debian:amd64-stretch # arch=amd64
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
 && apt-get --force-yes install -y -q build-essential tar git \
 && apt-get clean

COPY ./overlay/docker-ce-debian-arm64.deb docker-ce-debian-arm64.deb

# Install Docker
RUN case "${ARCH}" in                                                                                 \
    armv7l|armhf|arm|amd64|x86_64)                                                                    \
      curl https://get.docker.com | bash                                                              \
      ;;                                                                                              \
    arm64|aarch64)                                                                                    \
      dpkg -i docker-ce-debian-arm64.deb                                                              \ 
      ;;                                                                                              \
    *)                                                                                                \
      echo "Unhandled architecture: ${ARCH}."; exit 1;                                                \
      ;;                                                                                              \
    esac    

RUN rm docker-ce-debian-arm64.deb

#Install golang
RUN apt-get update && apt-get install -y wget tar git
RUN wget -O -  "https://golang.org/dl/go1.9.linux-${ARCH}.tar.gz" | tar xzC /usr/local
ENV GOPATH /go
ENV PATH $PATH:/usr/local/go/bin:$GOPATH/bin

# Install Etcd
RUN wget -O - https://github.com/coreos/etcd/releases/download/v3.2.6/v3.2.6.tar.gz | tar -xz &&\
    cd etcd-* &&\
    ./build && \
    mv ./bin/* /usr/bin/ &&\
    rm -fr etcd-* 


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
      curl -Ls https://github.com/innovate-technologies/Dispatch/releases/download/0.0.7/dispatchd-linux-arm > /usr/bin/dispatchd && \
      chmod +x /usr/bin/dispatchd                                                                     \
      ;;                                                                                              \
    amd64|x86_64)                                                                                     \
      curl -Ls https://github.com/innovate-technologies/Dispatch/releases/download/0.0.7/dispatchd-linux-amd64 > /usr/bin/dispatchd && \
      chmod +x /usr/bin/dispatchd                                                                     \
      ;;                                                                                              \
    arm64|aarch64)                                                                                    \
      curl -Ls https://github.com/innovate-technologies/Dispatch/releases/download/0.0.7/dispatchd-linux-arm64 > /usr/bin/dispatchd && \
      chmod +x /usr/bin/dispatchd                                                                     \
      ;;                                                                                              \
    *)                                                                                                \
      echo "Unhandled architecture: ${ARCH}."; exit 1;                                                \
      ;;                                                                                              \
    esac    

# Installing Dispatchctl
RUN case "${ARCH}" in                                                                                 \
    armv7l|armhf|arm)                                                                                 \
      curl -Ls https://github.com/innovate-technologies/Dispatch/releases/download/0.0.7/dispatchctl-linux-arm > /usr/bin/dispatchctl && \
      chmod +x /usr/bin/dispatchctl                                                                   \
      ;;                                                                                              \
    amd64|x86_64)                                                                                     \
      curl -Ls https://github.com/innovate-technologies/Dispatch/releases/download/0.0.7/dispatchctl-linux-amd64 > /usr/bin/dispatchctl && \
      chmod +x /usr/bin/dispatchctl                                                                   \
      ;;                                                                                              \
    arm64|aarch64)                                                                                    \
      curl -Ls https://github.com/innovate-technologies/Dispatch/releases/download/0.0.7/dispatchctl-linux-arm64 > /usr/bin/dispatchctl && \
      chmod +x /usr/bin/dispatchctl                                                                   \
      ;;                                                                                              \
    *)                                                                                                \
      echo "Unhandled architecture: ${ARCH}."; exit 1;                                                \
      ;;                                                                                              \
    esac                                                                                              

COPY ./overlay/etc /etc

RUN systemctl disable docker; systemctl enable docker

# Clean rootfs from image-builder
RUN /usr/local/sbin/builder-leave
