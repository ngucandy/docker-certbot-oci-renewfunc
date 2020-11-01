FROM python:3.8-slim

LABEL maintainer="andy.nguyen@oracle.com"

RUN apt-get update \
 && apt-get -y upgrade \
 && apt-get -y install --no-install-recommends \
      wget \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

ARG CERTBOT_VERSION
ENV CERTBOT_VERSION=${CERTBOT_VERSION:-1.9.0}

# OCI CLI
RUN pip install --no-cache-dir oci-cli

# Certbot -- based on https://hub.docker.com/r/certbot/certbot/dockerfile
WORKDIR /opt/certbot

# Retrieve certbot code
RUN mkdir -p src \
 && wget -nv -O certbot-${CERTBOT_VERSION}.tar.gz https://github.com/certbot/certbot/archive/v${CERTBOT_VERSION}.tar.gz \
 && tar xzf certbot-${CERTBOT_VERSION}.tar.gz \
 && cp certbot-${CERTBOT_VERSION}/CHANGELOG.md certbot-${CERTBOT_VERSION}/README.rst src/ \
 && cp certbot-${CERTBOT_VERSION}/letsencrypt-auto-source/pieces/dependency-requirements.txt . \
 && cp certbot-${CERTBOT_VERSION}/letsencrypt-auto-source/pieces/pipstrap.py . \
 && cp -r certbot-${CERTBOT_VERSION}/tools tools \
 && cp -r certbot-${CERTBOT_VERSION}/acme src/acme \
 && cp -r certbot-${CERTBOT_VERSION}/certbot src/certbot \
 && rm -rf certbot-${CERTBOT_VERSION}.tar.gz certbot-${CERTBOT_VERSION}

# Generate constraints file to pin dependency versions
RUN cat dependency-requirements.txt | tools/strip_hashes.py > unhashed_requirements.txt \
 && cat tools/dev_constraints.txt unhashed_requirements.txt | tools/merge_requirements.py > docker_constraints.txt

# Install certbot from sources
RUN python pipstrap.py \
 && pip install -r dependency-requirements.txt \
 && pip install --no-cache-dir --no-deps \
      --editable src/acme \
      --editable src/certbot

# Fn hotwrap binary
COPY --from=fnproject/hotwrap:latest /hotwrap /hotwrap

COPY certbot.sh /certbot.sh
COPY auth.sh /auth.sh
COPY cleanup.sh /cleanup.sh

RUN chmod +x /certbot.sh /auth.sh /cleanup.sh

CMD ["/certbot.sh"]

ENTRYPOINT ["/hotwrap"]
