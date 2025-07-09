# ==== Stage: base ====
#FROM ubuntu:24.04 AS base
#
## 非互動模式（可選，但不影響最小建構）
#ENV DEBIAN_FRONTEND=noninteractive
#
## 安裝 bash（Ubuntu 通常已內建，但保險起見加上）
#RUN apt-get update && apt-get install -y \
#    bash \
#    && rm -rf /var/lib/apt/lists/*
#
## 設定 container 預設執行 bash
#CMD ["/bin/bash"]

# ==== Stage: base ====
FROM ubuntu:24.04 AS base

# 1️⃣ 設定環境變數：非互動模式
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Taipei

# 2️⃣ 安裝基本工具 + 設定時區 + sudo
RUN apt-get update && apt-get install -y \
    tzdata \
    bash \
    sudo \
    && ln -fs /usr/share/zoneinfo/$TZ /etc/localtime \
    && dpkg-reconfigure -f noninteractive tzdata \
    && rm -rf /var/lib/apt/lists/*

# 3️⃣ 建立 non-root 使用者（固定 UID/GID）
ARG USERNAME=devuser
ARG UID=500
ARG GID=500

RUN groupadd --gid $GID $USERNAME \
    && useradd --uid $UID --gid $GID --create-home --shell /bin/bash $USERNAME \
    && usermod -aG sudo $USERNAME \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 4️⃣ 切換到 non-root 使用者
USER $USERNAME

# 5️⃣ 設定預設工作目錄與 shell
WORKDIR /home/$USERNAME
CMD ["/bin/bash"]
