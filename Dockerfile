FROM n8nio/n8n:latest

USER root
RUN apk update && \
    apk add --no-cache \
    python3 \
    py3-pip \
    ffmpeg \
    bash \
    build-base \
    jpeg-dev \
    zlib-dev && rm -rf /var/lib/apt/lists/*


COPY . .
RUN chown -R node:node /home/node
USER node