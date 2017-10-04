# src: https://github.com/nodejs/docker-node
# https://hub.docker.com/r/library/alpine/
FROM alpine:3.6

LABEL maintainer="support@chomchob.com"

# https://github.com/docker-library/docker
# from: https://github.com/docker-library/docker/tree/master/17.06

# install gcloud
# ref : https://github.com/GoogleCloudPlatform/cloud-sdk-docker

# install Helm
# ref: https://github.com/dtzar/helm-kubectl

RUN apk add --no-cache \
		ca-certificates \
    git \
    openssh-client \
    ansible \
    python

ENV INSTALL_DOCKER=1 \
    DOCKER_CHANNEL="stable" \
    DOCKER_VERSION="17.06.2-ce" \
    \
    INSTALL_GOOGLE_CLOUD_SDK=1 \
    CLOUD_SDK_VERSION="171.0.0" \
    CLOUD_SDK_FILENAME="google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz" \
    ADDITIONAL_COMPONENTS="app kubectl alpha beta" \
    \
    INSTALL_KUBECTL=0 \
    KUBECTL_VERSION="1.6.6" \
    \
    INSTALL_HELM=1 \
    HELM_VERSION="2.6.1" \
    HELM_FILENAME="helm-v${HELM_VERSION}-linux-amd64.tar.gz"

ENV PATH /google-cloud-sdk/bin:$PATH

# install deps
RUN set -ex; \
	apk add --no-cache --virtual .fetch-deps \
		curl \
		tar \
    bash \
	;

# install docker
RUN set -ex; \
	apk add --no-cache --virtual .fetch-deps \
		curl \
		tar \
    bash \
	; \
	\
  [[ $INSTALL_DOCKER -eq 1 ]] && \
  ( \
    apkArch="$(apk --print-arch)"; \
    case "$apkArch" in \
      x86_64) dockerArch='x86_64' ;; \
      s390x) dockerArch='s390x' ;; \
      *) echo >&2 "error: unsupported architecture ($apkArch)"; exit 1 ;;\
    esac; \
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
  ) \
  || echo 'skip install docker'; \
	\
  [[ $INSTALL_GOOGLE_CLOUD_SDK -eq 1 ]] && \
  ( \
    if ! curl -fL -o ${CLOUD_SDK_FILENAME} "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz"; then \
      echo >&2 "error: failed to download '${CLOUD_SDK_FILENAME}'"; \
      exit 1; \
    fi && \
    tar xzf ${CLOUD_SDK_FILENAME} && \
    rm ${CLOUD_SDK_FILENAME} && \
    ln -s /lib /lib64 && \
    google-cloud-sdk/install.sh \
      --usage-reporting=true \
      --path-update=true \
      --bash-completion=true \ 
      --rc-path=/.bashrc \
      --additional-components $ADDITIONAL_COMPONENTS; \
    gcloud config set core/disable_usage_reporting true && \
    gcloud config set component_manager/disable_update_check true && \
    gcloud config set metrics/environment github_docker_image \
  ) \
  || echo 'skip install google cloud sdk'; \
  \
  \
  [[ $INSTALL_KUBECTL -eq 1 ]] && \
  ( \
  if ! curl -fL -o /usr/local/bin/kubectl "https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl"; then \
    echo >&2 "error: failed to download 'kubectl-${KUBECTL_VERSION}' from github"; \
    exit 1; \
  fi; \
  \
  chmod +x /usr/local/bin/kubectl; \
  ) \
  || echo 'skip install helm'; \
  \
  \
  [[ $INSTALL_HELM -eq 1 ]] && \
  ( \
  if ! curl -fL -o /tmp/${HELM_FILENAME} "http://storage.googleapis.com/kubernetes-helm/${HELM_FILENAME}"; then \
    echo >&2 "error: failed to download 'helm-${HELM_VERSION}'"; \
    exit 1; \
  fi; \
  tar -zxvf /tmp/${HELM_FILENAME} -C /tmp; \
  mv /tmp/linux-amd64/helm /usr/local/bin/helm; \
  chmod +x /usr/local/bin/helm; \
  \
  helm plugin install https://github.com/databus23/helm-diff; \
  ) \
  || echo 'skip install helm'; \
  \
	apk del .fetch-deps; \
  rm -rf /tmp/*; \
	\
	[[ $INSTALL_DOCKER -eq 1 ]] && ( \
    dockerd -v; \
    docker -v; \
  ) || echo 'skip docker'; \
  [[ $INSTALL_GOOGLE_CLOUD_SDK -eq 1 ]] && ( \
    gcloud version; \
    kubectl version --client; \
  ) || echo 'skip gcloud'; \
  [[ $INSTALL_KUBECTL -eq 1 ]] && kubectl version --client || echo 'skip kubectl'; \
  [[ $INSTALL_HELM -eq 1 ]] && helm version --client || echo 'skip helm';

# clean up
# RUN set -ex; \
#   apk del .fetch-deps; \
#   rm -rf /tmp/*;

CMD ["sh"]
