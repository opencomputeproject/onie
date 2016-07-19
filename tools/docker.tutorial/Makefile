# Build the Docker image for people to use as a build image
# Only maintainers need this ... everyone else should use the 
# top level Makefile

ifndef ONL
$(error Need to define $$ONL variable to use this Makefile)
endif

VERSION=latest


# needed to get SSH agent credential forwarding
ifdef SSH_AUTH_SOCK
ssh_dir = $(shell dirname $$SSH_AUTH_SOCK)
SSH_AGENT=-v $(ssh_dir):$(ssh_dir) -e SSH_AUTH_SOCK=$$SSH_AUTH_SOCK
else
SSH_AGENT=
endif

DOCKER=docker
IMAGE=opennetworklinux/routing-tutorial


all: docker_run

docker_build: docker_check
	ln -f ../../builds/kvm/i386/onl/loader-i386.iso .
	sudo ln -f ../../builds/swi/i386/all/onl-*-i386-kvm-*.swi onl-i386-kvm.swi
	$(DOCKER) build -t $(IMAGE):$(VERSION) .

docker_run: docker_check
	#$(DOCKER) pull $(IMAGE):$(VERSION)
	$(DOCKER) run --privileged -t -i \
        -h "tutorial" \
        $(SSH_AGENT) \
        $(IMAGE):$(VERSION) 

# DANGER - destructively kills all containers and images - DO NOT USE
docker_nuke_all: docker_check
	@echo Before
	@echo ------------------------
	$(DOCKER) info
	$(DOCKER) rm `docker ps -aq` || true
	$(DOCKER) rmi `docker images -aq` || true
	@echo After
	@echo ------------------------
	$(DOCKER) info

docker_push: docker_check
	$(DOCKER) push $(IMAGE)

docker_check: 
	@which $(DOCKER) || echo STOP : you need to install docker.io first

clean:
	rm -f kvm-router-demo.sh loader-i386.iso onl-i386-kvm.swi
