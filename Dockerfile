FROM docker.io/debian:trixie-slim@sha256:cedb1ef40439206b673ee8b33a46a03a0c9fa90bf3732f54704f99cb061d2c5a AS builder

WORKDIR /usr/src/app

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y \
    python3-pip \
    cmake \
    git \
    pkg-config \
    libssl-dev \
    ninja-build \
    gcc g++ && \
    pip3 install --user --break-system-packages meson

COPY . .

RUN /root/.local/bin/meson setup \
    -Db_lto=true \
    --buildtype=release \
    --warnlevel=0 \
    -Ddefault_library=static \
    meson-build-release && \
    ninja -C meson-build-release && \
    cp /usr/src/app/meson-build-release/slipstream-client . && \
    cp /usr/src/app/meson-build-release/slipstream-server .

FROM gcr.io/distroless/cc-debian13:latest@sha256:e1cc90d06703f5dc30ae869fbfce78fce688f21a97efecd226375233a882e62f AS runtime

WORKDIR /usr/src/app

COPY ./certs/ ./certs/

ENV PATH=/usr/src/app/:$PATH

LABEL org.opencontainers.image.source=https://github.com/sredevopsorg/slipstream

FROM runtime AS client

COPY --from=builder --chmod=755 /usr/src/app/slipstream-client .

ENTRYPOINT ["/usr/src/app/slipstream-client"]

FROM runtime AS server

COPY --from=builder --chmod=755 /usr/src/app/slipstream-server .

ENTRYPOINT ["/usr/src/app/slipstream-server"]
