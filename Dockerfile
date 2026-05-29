FROM python:3.12-slim

LABEL maintainer="nesquena"
LABEL description="Hermes Web UI — browser interface for Hermes Agent"

# Install system packages
ENV DEBIAN_FRONTEND=noninteractive

# Make use of apt-cacher-ng if available
RUN if [ "A${BUILD_APT_PROXY:-}" != "A" ]; then \
        echo "Using APT proxy: ${BUILD_APT_PROXY}"; \
        printf 'Acquire::http::Proxy "%s";\n' "$BUILD_APT_PROXY" > /etc/apt/apt.conf.d/01proxy; \
    fi \
    && apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates wget gnupg \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

RUN apt-get update -y --fix-missing --no-install-recommends \
    && apt-get install -y --no-install-recommends \
       apt-utils \
       locales \
       ca-certificates \
       curl \
       rsync \
       openssh-client \
       git \
       xz-utils \
    && apt-get upgrade -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# UTF-8
RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG=en_US.utf8
ENV LC_ALL=C

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONIOENCODING=utf-8

WORKDIR /apptoo

# Create the unprivileged runtime user and dirs
RUN groupadd -g 1024 hermeswebui \
    && useradd -u 1024 -d /home/hermeswebui -g hermeswebui -G users -s /bin/bash -m hermeswebui \
    && mkdir -p /app /uv_cache /workspace \
    && chown -R hermeswebui:hermeswebui /home/hermeswebui /app /uv_cache /workspace \
    && chmod 0755 /home/hermeswebui \
    && chmod 1777 /app /uv_cache /workspace

# We no longer use docker_init.bash as entrypoint, but keep it for reference if needed
COPY --chmod=555 docker_init.bash /hermeswebui_init.bash

RUN touch /.within_container

# Remove APT proxy configuration and clean up APT downloaded files
RUN rm -rf /var/lib/apt/lists/* /etc/apt/apt.conf.d/01proxy \
    && apt-get clean

# Pre-install uv system-wide so the container doesn't need internet access at runtime.
# Installing as root places uv in /usr/local/bin, available to all users.
USER root
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh

# Copy app source
COPY --chown=root:root . /apptoo

# Bake the git version tag into the image
ARG HERMES_VERSION=unknown
RUN echo "__version__ = '${HERMES_VERSION}'" > /apptoo/api/_version.py

# Switch to hermeswebui user for runtime
USER hermeswebui

# Runtime defaults; can be overridden by env
ENV HERMES_WEBUI_HOST=0.0.0.0
ENV HERMES_WEBUI_PORT=8787
ENV HERMES_WEBUI_STATE_DIR=/home/hermeswebui/.hermes/webui
ENV HERMES_WEBUI_DEFAULT_WORKSPACE=/workspace

# Runtime launcher script
COPY --chown=hermeswebui:hermeswebui run-webui.sh /run-webui.sh
RUN chmod +x /run-webui.sh

EXPOSE 8787

CMD ["/run-webui.sh"]
