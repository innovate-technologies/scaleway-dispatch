NAME =			debian-dispatch
VERSION =		latest
VERSION_ALIASES =	1.12.0 1.12 1
TITLE =			Docker
DESCRIPTION =		Docker + etcd + dispatch
SOURCE_URL =		https://github.com/innovate-technologies/scaleway-dispatch
DEFAULT_IMAGE_ARCH =	x86_64

IMAGE_VOLUME_SIZE =	50G
IMAGE_BOOTSCRIPT =	docker
IMAGE_NAME =		debian-dispatch


## Image tools  (https://github.com/scaleway/image-tools)
all:	docker-rules.mk
docker-rules.mk:
	wget -qO - https://j.mp/scw-builder | bash
-include docker-rules.mk
## Here you can add custom commands and overrides
