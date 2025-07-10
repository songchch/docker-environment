#  ==== Stage: base ====
# FROM ubuntu:24.04 AS base
# 
# # 1️⃣ 設定環境變數：非互動模式
# ENV DEBIAN_FRONTEND=noninteractive
# ENV TZ=Asia/Taipei
# 
# # 2️⃣ 安裝基本工具 + 設定時區 + sudo
# RUN apt-get update && apt-get install -y \
#     tzdata \
#     bash \
#     sudo \
#     && ln -fs /usr/share/zoneinfo/$TZ /etc/localtime \
#     && dpkg-reconfigure -f noninteractive tzdata \
#     && rm -rf /var/lib/apt/lists/*
# 
# # 3️⃣ 建立 non-root 使用者（固定 UID/GID）
# ARG USERNAME=devuser
# ARG UID=500
# ARG GID=500
# 
# RUN groupadd --gid $GID $USERNAME \
#     && useradd --uid $UID --gid $GID --create-home --shell /bin/bash $USERNAME \
#     && usermod -aG sudo $USERNAME \
#     && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
# 
# # 4️⃣ 切換到 non-root 使用者
# USER $USERNAME
# 
# # 5️⃣ 設定預設工作目錄與 shell
# WORKDIR /home/$USERNAME
# CMD ["/bin/bash"]

# ==== Stage: base ====
FROM ubuntu:24.04 AS base

# 1️⃣ 環境與時區
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Taipei

# 2️⃣ 安裝基本工具
RUN apt-get update && apt-get install -y \
    tzdata \
    bash \
    sudo \
    && ln -fs /usr/share/zoneinfo/$TZ /etc/localtime \
    && dpkg-reconfigure -f noninteractive tzdata \
    && rm -rf /var/lib/apt/lists/*

# 3️⃣ 建立 non-root 使用者
ARG USERNAME=devuser
ARG UID=500
ARG GID=500
RUN groupadd --gid $GID $USERNAME \
    && useradd --uid $UID --gid $GID --create-home --shell /bin/bash $USERNAME \
    && usermod -aG sudo $USERNAME \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 4️⃣ 切換使用者與工作目錄
USER $USERNAME

# 5️⃣ 設定預設工作目錄與 shell
WORKDIR /home/$USERNAME
CMD ["/bin/bash"]"
# -------------------------------------------------------
# ==== Stage: common_pkg_provider ====
FROM base AS common_pkg_provider
USER root

# 安裝 CLI、網路、編譯工具
RUN apt-get update && apt-get install -y \
    vim git curl wget ca-certificates build-essential \
    python3 python3-pip bzip2 \
    && ln -s /usr/bin/python3 /usr/bin/python \
    && rm -rf /var/lib/apt/lists/*

# 安裝 Miniconda (根據架構自動下載)
ARG CONDA_DIR=/opt/conda
ENV PATH=$CONDA_DIR/bin:$PATH
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh; \
        echo "Found architecture: $ARCH"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh -O miniconda.sh; \
        echo "Found architecture: $ARCH"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    bash miniconda.sh -b -p $CONDA_DIR && \
    rm miniconda.sh && \
    ln -s $CONDA_DIR/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". $CONDA_DIR/etc/profile.d/conda.sh" >> /etc/bash.bashrc && \
    conda init bash

# -------------------------------------------------------

# ==== Stage: verilator_provider ====
FROM common_pkg_provider AS verilator_provider
USER root

RUN apt-get update && apt-get install -y \
    git make autoconf g++ flex bison help2man \
    && git clone https://github.com/verilator/verilator.git /tmp/verilator \
    && cd /tmp/verilator && git checkout v5.024 \
    && autoconf && ./configure && make -j$(nproc) && make install \
    && rm -rf /tmp/verilator

# -------------------------------------------------------

# ==== Stage: systemc_provider ====
FROM common_pkg_provider AS systemc_provider
USER root

WORKDIR /tmp
RUN wget https://www.accellera.org/images/downloads/standards/systemc/systemc-2.3.4.tar.gz && \
    tar -xzf systemc-2.3.4.tar.gz && \
    cd systemc-2.3.4 && \
    mkdir build && cd build && \
    ../configure --prefix=/opt/systemc && \
    make -j$(nproc) && make install && \
    ln -s /opt/systemc/bin/systemc-config /usr/local/bin/systemc-config && \
    rm -rf /tmp/systemc-2.3.4*

# -------------------------------------------------------

# ==== Final Stage: base + all packages ====
FROM base AS final
USER root

# 複製已安裝內容
COPY --from=common_pkg_provider /opt/conda /opt/conda
COPY --from=common_pkg_provider /etc/profile.d/conda.sh /etc/profile.d/conda.sh
COPY --from=common_pkg_provider /usr/bin/python3 /usr/bin/python3
COPY --from=common_pkg_provider /usr/bin/pip3 /usr/bin/pip3
COPY --from=common_pkg_provider /usr/bin/vim /usr/bin/vim
COPY --from=common_pkg_provider /usr/bin/git /usr/bin/git
COPY --from=common_pkg_provider /usr/bin/curl /usr/bin/curl
COPY --from=common_pkg_provider /usr/bin/wget /usr/bin/wget
COPY --from=common_pkg_provider /usr/bin/make /usr/bin/make
COPY --from=common_pkg_provider /usr/bin/gcc /usr/bin/gcc
COPY --from=common_pkg_provider /usr/bin/g++ /usr/bin/g++
COPY --from=verilator_provider /usr/local/bin/verilator /usr/local/bin/verilator
COPY --from=systemc_provider /opt/systemc /opt/systemc
COPY --from=systemc_provider /usr/local/bin/systemc-config /usr/local/bin/systemc-config

# 設定 Conda 路徑
ENV PATH=/opt/conda/bin:$PATH

# 切回 devuser
USER devuser
WORKDIR /home/devuser
CMD ["/bin/bash"]
