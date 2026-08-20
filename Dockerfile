FROM debian:trixie-slim AS builder

RUN apt-get update && apt-get install -y \
    build-essential git cmake lua-zlib liblua5.2-dev curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

COPY patches/ /patches/
RUN git clone --recurse-submodules https://github.com/tkntrec/EDCB && \
    cd EDCB && \
    (for p in /patches/*.patch; do [ -f "$p" ] && git apply "$p" || true; done) && \
    cd Document/Unix && \
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
    tzdata lua-zlib curl liblua5.2-0 ca-certificates gosu \
    && rm -rf /var/lib/apt/lists/*

# 共有ライブラリ検索パスをビルド時に設定
RUN echo "/usr/local/lib/edcb" > /etc/ld.so.conf.d/edcb.conf && ldconfig

# デフォルトの一般ユーザーを作成
RUN groupadd -g 1000 edcb && \
    useradd -u 1000 -g edcb -m -s /bin/sh edcb

COPY --from=builder /usr/local/bin/ /usr/local/bin/
COPY --from=builder /usr/local/lib/edcb/ /usr/local/lib/edcb/
COPY --from=builder /var/local/edcb/ /var/local/edcb/
COPY --from=builder /etc/edcb/template/ /etc/edcb/template/

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["EpgTimerSrv"]
