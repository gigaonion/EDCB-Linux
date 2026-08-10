FROM debian:trixie-slim AS builder

RUN apt-get update && apt-get install -y \
    build-essential git cmake lua-zlib liblua5.2-dev curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

RUN git clone --recurse-submodules https://github.com/tkntrec/EDCB && \
    cd EDCB/Document/Unix && \
    make install && \
    make extra && make install_extra && \
    mkdir -p /var/local/edcb && \
    make setup_ini && \
    mkdir -p /etc/edcb/template && \
    sed -i -e 's/^ALLOW_SETTING=.*/ALLOW_SETTING=true/' \
    /var/local/edcb/HttpPublic/legacy/util.lua && \
    cp -r /var/local/edcb/* /etc/edcb/template/

RUN git clone --recurse-submodules  https://github.com/EMWUI/EDCB_Material_WebUI.git && \
    cd EDCB_Material_WebUI && \
    cp -r HttpPublic /var/local/edcb/ && \
    cp -r Setting /var/local/edcb/

RUN git clone --recurse-submodules https://github.com/matching/BonDriver_LinuxMirakc.git && \
    cd BonDriver_LinuxMirakc && \
    make && \
    mkdir -p /usr/local/lib/edcb && \
    cp BonDriver_LinuxMirakc.so /usr/local/lib/edcb/

FROM debian:trixie-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    tzdata lua-zlib curl liblua5.2-0 ffmpeg \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/bin/ /usr/local/bin/
COPY --from=builder /usr/local/lib/edcb/ /usr/local/lib/edcb/
COPY --from=builder /var/local/edcb/ /var/local/edcb/
COPY --from=builder /etc/edcb/template/ /etc/edcb/template/

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["EpgTimerSrv"]
