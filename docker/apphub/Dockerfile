# This file can running at actions
# MEDIA_VERSION and LIBRARY_VERSION will trigger its release
# modify time: 202409131700, you can modify here to trigger Docker Build action


FROM python:3.10-slim-bullseye
LABEL maintainer="Websoft9<help@websoft9.com>"
LABEL version="0.1.3-rc1"

WORKDIR  /websoft9

ARG MEDIA_VERSION="0.1.1"
ARG LIBRARY_VERSION="0.7.1"
ARG WEBSOFT9_REPO="https://github.com/qiaofeng1227/websoft9"
ARG WEBSOFT9_ARTIFACT="https://artifact.websoft9.com/release/websoft9"
ARG LIBRARY_REPO="https://github.com/Websoft9/docker-library"
ARG SOURCE_GITHUB_PAGES="https://websoft9.github.io/websoft9"

# If you build this image on local, need download media.zip from WEBSOFT9_ARTIFACT to docker/apphub directory like below
# RUN curl -o media.zip https://artifact.websoft9.com/release/websoft9/plugin/media/media-latest.zip
COPY media.zip /websoft9

RUN apt update && apt install -y --no-install-recommends curl git jq cron iproute2 supervisor rsync wget unzip zip && \
    # download docker-library
    git clone --depth=1 $LIBRARY_REPO && \
    mv docker-library w9library && \
    rm -rf w9library/.github && \
    ls -la && \
    unzip media.zip && rm -rf media.zip && \
    mv media* w9media && \
    git clone --depth=1 https://github.com/swagger-api/swagger-ui.git && \
    wget https://cdn.redoc.ly/redoc/latest/bundles/redoc.standalone.js && \
    cp redoc.standalone.js swagger-ui/dist && \
    git clone --depth=1 $WEBSOFT9_REPO ./w9source && \
    cp -r ./w9media ./media && \
    cp -r ./w9library ./library && \
    cp -r ./w9source/apphub ./apphub && \
    cp -r ./swagger-ui/dist ./apphub/swagger-ui && \
    cp -r ./w9source/apphub/src/config ./config && \
    cp -r ./w9source/docker/apphub/script ./script && \
    curl -o ./script/update_zip.sh $SOURCE_GITHUB_PAGES/scripts/update_zip.sh && \
    pip install --no-cache-dir --upgrade -r apphub/requirements.txt && \
    pip install -e ./apphub && \
    # Clean cache and install files
    rm -rf apphub/docs apphub/tests library.zip media.zip redoc.standalone.js swagger-ui w9library w9media w9source && \
    apt clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/man /usr/share/doc /usr/share/doc-base

# supervisor
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN chmod +r /etc/supervisor/conf.d/supervisord.conf

# cron
COPY config/cron /etc/cron.d/cron
RUN echo "" >> /etc/cron.d/cron && crontab /etc/cron.d/cron

# chmod for all .sh script
RUN find /websoft9/script -name "*.sh" -exec chmod +x {} \;

VOLUME /websoft9/apphub/logs 
VOLUME /websoft9/apphub/src/config

EXPOSE 8080
EXPOSE 8081
ENTRYPOINT ["/websoft9/script/entrypoint.sh"]
