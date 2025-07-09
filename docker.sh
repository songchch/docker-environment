#!/bin/bash

# 預設參數
IMAGE_NAME="aoc2026-env"
CONTAINER_NAME="aoc2026-container"
USERNAME="User(default)"
HOSTNAME="aoc2026"
# MOUNTS_SRC="/c/Users/USER/OneDrive/桌面/TA_training_docker"
# MOUNTS_DST="/workspace"
MOUNTS_DST="/home/$USERNAME/workspace"

# 檢查 image 是否存在
function check_image_exists() {
    if docker image inspect "$IMAGE_NAME" > /dev/null 2>&1; then
        echo "✅ Image '$IMAGE_NAME' already exists."
        echo "🧹 若要刪除並重建，請執行: ./docker.sh rebuild"
        return 0
    else
        return 1
    fi
}

# 建立 image
function build_image() {
    if check_image_exists; then
        return
    fi

    echo "🚧 Building Docker image '$IMAGE_NAME'..."
    docker build -t "$IMAGE_NAME" .
    echo "✅ Image '$IMAGE_NAME' built successfully."
}

# 移除 container 和 image
function clean_all() {
    echo "🧹 Cleaning containers and image..."
    docker rm -f "$CONTAINER_NAME" 2>/dev/null
    docker image rm -f "$IMAGE_NAME" 2>/dev/null
    echo "✅ Cleaned."
}

# 重建 image
function rebuild() {
    clean_all
    build_image
}

# 執行 container
function run_container() {
    # 判斷 container 狀態
    CONTAINER_STATUS=$(docker ps -a --filter "name=^/${CONTAINER_NAME}$" --format "{{.Status}}")

    if [[ "$CONTAINER_STATUS" == "" ]]; then
        echo "🚀 Container not found. Creating and running new container..."
        echo "PWD: $(pwd)"
        docker run -it --name "$CONTAINER_NAME" \
            --hostname "$HOSTNAME" \
            --env USER="$USERNAME" \
            --mount type=bind,source="$(pwd)",target="$MOUNTS_DST" \
            "$IMAGE_NAME" \
            bash

    elif [[ "$CONTAINER_STATUS" == Up* ]]; then
        echo "🔄 Container is already running. Entering..."
        docker exec -it "$CONTAINER_NAME" bash

    else
        echo "⏯️ Container exists but not running. Starting and entering..."
        docker start "$CONTAINER_NAME"
        docker exec -it "$CONTAINER_NAME" bash
    fi
}

# 處理 CLI 參數
function parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            build)
                CMD="build"
                shift
                ;;
            run)
                CMD="run"
                shift
                ;;
            clean)
                CMD="clean"
                shift
                ;;
            rebuild)
                CMD="rebuild"
                shift
                ;;
            --image-name)
                IMAGE_NAME="$2"
                shift 2
                ;;
            --cont-name)
                CONTAINER_NAME="$2"
                shift 2
                ;;
            --username)
                USERNAME="$2"
                shift 2
                ;;
            --hostname)
                HOSTNAME="$2"
                shift 2
                ;;
            --mount)
                MOUNTS+=("$2")
                shift 2
                ;;
            *)
                echo "❌ Unknown argument: $1"
                exit 1
                ;;
        esac
    done
}

# 執行主流程
function main() {
    parse_args "$@"

    case $CMD in
        build)
            build_image
            ;;
        run)
            run_container
            ;;
        clean)
            clean_all
            ;;
        rebuild)
            rebuild
            ;;
        *)
            echo "用法："
            echo "  ./docker.sh build --image-name IMAGE"
            echo "  ./docker.sh run --username \$USER --mount path1 --mount path2 --image-name IMAGE --cont-name CONTAINER"
            echo "  ./docker.sh clean"
            echo "  ./docker.sh rebuild"
            ;;
    esac
}

main "$@"
