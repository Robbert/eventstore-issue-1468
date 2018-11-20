FROM mhart/alpine-node:10.9.0

# Use `--no-cache` to get a smaller image, by removing unused files afterwards.
# The packages are sorted, one per line, to have better diffs in Git.
RUN \
    apk add --no-cache \
        bash \
        curl \
        nano \
        util-linux \
    && command -v bash \
    && command -v curl \
    && command -v nano \
    && command -v uuidgen

RUN mkdir -p /app \
    && addgroup -g 1000 node \
    && adduser \
        -D \
        -G node \
        -h /app \
        -s /bin/sh \
        -u 1000 \
        node \
    && chown -R node:node /app

USER node

WORKDIR /app

ADD ./ ./

CMD ["/bin/bash", "bin/start.sh"]
