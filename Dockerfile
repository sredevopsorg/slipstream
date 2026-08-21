FROM docker.io/debian:trixie-slim@sha256:26f98ccd92fd0a44d6928ce8ff8f4921b4d2f535bfa07555ee5d18f61429cf0c AS builder

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

FROM gcr.io/distroless/cc-debian13:latest@sha256:e86cf4f565c8eee2cbb2be073bb107dafb14734b53d5872da20fdf47418a02f4 AS runtime

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
