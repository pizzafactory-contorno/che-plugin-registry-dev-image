#
# Copyright (c) 2018-2020 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
# Contributors:
#   Red Hat, Inc. - initial API and implementation
#

FROM docker.io/node:12.19.0-alpine3.12
RUN apk add --no-cache py3-pip jq bash git git-perl wget skopeo curl && pip3 install yq jsonschema
# Tools for publishing to surge.sh
RUN npm install --global surge && apk add --no-cache tree

USER 0
# Set permissions on /etc/passwd and /home to allow arbitrary users to write
COPY --chown=0:0 entrypoint.sh /
RUN mkdir -p /projects && \
    mkdir -p /home/user && \
    chgrp -R 0 /home && \
    chmod -R g=u /etc/passwd /etc/group /home && \
    chmod +x /entrypoint.sh
COPY bashrc /home/user/.bashrc

# Install common terminal editors in container to aid development process
COPY install-editor-tooling.sh /tmp
RUN /tmp/install-editor-tooling.sh && rm -f /tmp/install-editor-tooling.sh

RUN echo "Invalidating docker cache 2021-05-26" && \
    cd /tmp && \
    mkdir che-plugin-registry-repo && \
    cd che-plugin-registry-repo && \
    git clone https://github.com/eclipse/che-plugin-registry && \
    cd che-plugin-registry && \
    mkdir output && \
    BUILDER=docker SKIP_TEST=true SKIP_FORMAT=true SKIP_LINT=true NODE_BUILD_OPTIONS="-max-old-space-size=1024" ./build.sh --skip-oci-image && \
    chmod -R a+rw /tmp/che-plugin-registry && \
    cd && rm /tmp/che-plugin-registry-repo -rf;

USER 10001
ENV HOME=/home/user
WORKDIR /projects
ENTRYPOINT [ "/entrypoint.sh" ]
CMD ["tail", "-f", "/dev/null"]
