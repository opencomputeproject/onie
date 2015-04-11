# Build the Docker image for people to use as a build image
# Only maintainers need this ... everyone else should use the 
# top level Makefile

ifndef ONL
$(error Need to define $$ONL variable to use this Makefile)
endif

IMAGE=1.4


# needed to get SSH agent credential forwarding
ifdef SSH_AUTH_SOCK
ssh_dir = $(shell dirname $$SSH_AUTH_SOCK)
SSH_AGENT=-v $(ssh_dir):$(ssh_dir) -e SSH_AUTH_SOCK=$$SSH_AUTH_SOCK
else
SSH_AGENT=
endif


all: docker_run

docker_build:
	docker build -t bigswitch/onl-build:$(IMAGE) .

docker_run:
	# UNCOMMENT ME FOR PRODUCTION docker pull bigswitch/onl-build:$(IMAGE) .
	docker run -t -i -v $(ONL):$(ONL) -w $(ONL) $(SSH_AGENT) bigswitch/onl-build:$(IMAGE)

# DANGER - destructively kills all containers and images - DO NOT USE
docker_nuke_all:
	@echo Before
	@echo ------------------------
	docker info
	docker rm `docker ps -aq` || true
	docker rmi `docker images -aq` || true
	@echo After
	@echo ------------------------
	docker info

docker_push:
	docker push bigswitch/onl-build 
