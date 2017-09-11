# src: https://github.com/nodejs/docker-node
# https://hub.docker.com/r/library/alpine/
FROM alpine:3.6

LABEL maintainer="support@chomchob.com"

# https://github.com/docker-library/docker
# from: https://github.com/docker-library/docker/tree/master/17.06

RUN apk add --no-cache \
		ca-certificates \
    git \
    openssh-client \
    ansible

ENV DOCKER_CHANNEL stable
ENV DOCKER_VERSION 17.06.2-ce
ENV KUBECTL_VERSION 1.6.6
ENV HELM_VERSION 2.6.0

ENV FILENAME="helm-v${HELM_VERSION}-linux-amd64.tar.gz"
# TODO ENV DOCKER_SHA256
# https://github.com/docker/docker-ce/blob/5b073ee2cf564edee5adca05eee574142f7627bb/components/packaging/static/hash_files !!
# (no SHA file artifacts on download.docker.com yet as of 2017-06-07 though)

RUN set -ex; \
# why we use "curl" instead of "wget":
# + wget -O docker.tgz https://download.docker.com/linux/static/stable/x86_64/docker-17.03.1-ce.tgz
# Connecting to download.docker.com (54.230.87.253:443)
# wget: error getting response: Connection reset by peer
	apk add --no-cache --virtual .fetch-deps \
		curl \
		tar \
	; \
	\
# this "case" statement is generated via "update.sh"
	apkArch="$(apk --print-arch)"; \
	case "$apkArch" in \
		x86_64) dockerArch='x86_64' ;; \
		s390x) dockerArch='s390x' ;; \
		*) echo >&2 "error: unsupported architecture ($apkArch)"; exit 1 ;;\
	esac; \
	\
	if ! curl -fL -o docker.tgz "https://download.docker.com/linux/static/${DOCKER_CHANNEL}/${dockerArch}/docker-${DOCKER_VERSION}.tgz"; then \
		echo >&2 "error: failed to download 'docker-${DOCKER_VERSION}' from '${DOCKER_CHANNEL}' for '${dockerArch}'"; \
		exit 1; \
	fi; \
	\
	tar --extract \
		--file docker.tgz \
		--strip-components 1 \
		--directory /usr/local/bin/ \
	; \
	rm docker.tgz; \
	\
  # install kubectl
  if ! curl -fL -o /usr/local/bin/kubectl "https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl"; then \
    echo >&2 "error: failed to download 'kubectl-${KUBECTL_VERSION}' from github"; \
    exit 1; \
  fi; \
  \
  chmod +x /usr/local/bin/kubectl; \
  # install helm
  # ref: https://github.com/dtzar/helm-kubectl
  if ! curl -fL -o /tmp/${FILENAME} "http://storage.googleapis.com/kubernetes-helm/${FILENAME}"; then \
    echo >&2 "error: failed to download 'helm-${HELM_VERSION}' from github"; \
    exit 1; \
  fi; \
  tar -zxvf /tmp/${FILENAME} -C /tmp; \
  mv /tmp/linux-amd64/helm /usr/local/bin/helm; \
  chmod +x /usr/local/bin/helm; \
  \
	apk del .fetch-deps; \
  rm -rf /tmp/*; \
	\
	dockerd -v; \
	docker -v; \
  kubectl version --client; \
  helm version --client

CMD ["sh"]
