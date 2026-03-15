FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    g++ \
    make \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
RUN git clone https://github.com/n-tehranchi/OpenSimRoot.git

WORKDIR /build/OpenSimRoot/OpenSimRoot/StaticBuild
RUN make clean && make -j$(nproc) release

# --- Runtime stage ---
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    libstdc++6 \
    && rm -rf /var/lib/apt/lists/*

# Copy the compiled binary
COPY --from=builder /build/OpenSimRoot/OpenSimRoot/StaticBuild/OpenSimRoot /usr/local/bin/OpenSimRoot

# Copy the bundled InputFiles (templates, environments, plant parameters)
COPY --from=builder /build/OpenSimRoot/OpenSimRoot/InputFiles /opt/opensimroot/InputFiles

# Copy entrypoint
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Allow users to mount custom input files here
VOLUME ["/sim/input", "/sim/output"]

WORKDIR /sim

ENV PHENOTYPE="" \
    LOCATION="" \
    WATER_REGIME="" \
    OUTPUT_PATH="/sim/output"

ENTRYPOINT ["entrypoint.sh"]
