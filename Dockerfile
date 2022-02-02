FROM ubuntu:20.04

ARG version
ARG arch
# Install dumb-init and ca-certificates. The dumb-init package is to ensure
# signals and orphaned processes are are handled correctly. The ca-certificate
# package is installed because the base Ubuntu image does not come with any
# certificate authorities. libelf1 is a dependency introduced by Teleport 7.0.
#
# Note that /var/lib/apt/lists/* is cleaned up in the same RUN command as
# "apt-get update" to reduce the size of the image.
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y curl ca-certificates dumb-init libelf1 && \
    update-ca-certificates && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/*

RUN TELEPORT_VERSION=${version} \
    TEMP_DIR=$(mktemp -d) && cd $TEMP_DIR \
    && curl -o teleport.tar.gz -fsSL https://get.gravitational.com/teleport-v${TELEPORT_VERSION}-linux-${arch}-bin.tar.gz \
    && tar xvf teleport.tar.gz --strip=1 teleport/teleport teleport/tctl teleport/tsh \
    && mv teleport tctl tsh /usr/local/bin \
    && rm -rf $TEMP_DIR

# By setting this entry point, we expose make target as command.
ENTRYPOINT ["/usr/bin/dumb-init", "teleport", "start", "-c", "/etc/teleport/teleport.yaml"]
