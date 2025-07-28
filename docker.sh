#!/bin/bash

# 預設參數
IMAGE_NAME="aoc2026-env"
CONTAINER_NAME="aoc2026-container"
USERNAME="User(default)"
HOSTNAME="aoc2026"
STAGE_NAME="final"
# MOUNTS_SRC="/c/Users/USER/OneDrive/桌面/TA_training_docker"
# MOUNTS_DST="/workspace"

# 檢查 image 是否存在
function check_image_exists() {
    CONTAINER_IMAGE=$(docker inspect --format '{{.Config.Image}}' "$CONTAINER_NAME" 2>/dev/null)

    # echo "Checking if image '$IMAGE_NAME' or '$CONTAINER_IMAGE' exists..."

    if docker image inspect "$IMAGE_NAME" > /dev/null 2>&1; then
        echo "Image '$IMAGE_NAME' already exists."
        return 0
    else
        if docker image inspect "$CONTAINER_IMAGE" > /dev/null 2>&1; then
            echo "Image '$CONTAINER_IMAGE' already exists."
            return 0
        else
            echo "Image does not exist, please run: ./docker.sh build"
            return 1
        fi
    fi
}

# 建立 image
function build_image() {
    if check_image_exists; then
        return
    fi

    echo "🚧 Building Docker image '$IMAGE_NAME'..."
    docker build --target "$STAGE_NAME" --build-arg USERNAME="$USERNAME" -t "$IMAGE_NAME" .
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
    # 判斷 image 是否存在
    if ! check_image_exists; then
        return
    fi

    # 判斷 container 狀態
    CONTAINER_STATUS=$(docker ps -a --filter "name=${CONTAINER_NAME}$" --format "{{.Status}}")
    
    echo "CONTAINER_STATUS is = $CONTAINER_STATUS"
    
    if [[ "$CONTAINER_STATUS" == "" ]]; then
        echo "🚀 Container not found. Creating and running new container..."
        echo "PWD: $(pwd)"
        docker run -it --name "$CONTAINER_NAME" \
            --hostname "$HOSTNAME" \
            --user "$USERNAME" \
            --mount type=bind,source="$(pwd)/workspace",target="/home/$USERNAME/workspace" \
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

function stop_container() {
    # 判斷 image 是否存在
    if ! check_image_exists; then
        return
    fi

    CONTAINER_STATUS=$(docker ps -a --filter "name=${CONTAINER_NAME}$" --format "{{.Status}}")
    
    if [[ "$CONTAINER_STATUS" == "" ]]; then
        echo "❌ Container '$CONTAINER_NAME' does not exist."
    elif [[ "$CONTAINER_STATUS" == Up* ]]; then
        echo "⏹️ Stopping container '$CONTAINER_NAME'..."
        docker stop "$CONTAINER_NAME"
        echo "✅ Container '$CONTAINER_NAME' stopped."
    else
        echo "ℹ️ Container '$CONTAINER_NAME' is not running."
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
            stop)
                CMD="stop"
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
            --stage-name)
                STAGE_NAME="$2"
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
        stop)
            stop_container
            ;;
        clean)
            clean_all
            ;;
        rebuild)
            rebuild
            ;;
        *)
            echo "Usage: "
            echo "  ./docker.sh build --stage-name STAGE --username USER --image-name IMAGE"
            echo "  ./docker.sh run --username USER --image-name IMAGE --cont-name CONTAINER"
            echo "  ./docker.sh stop --cont-name CONTAINER"
            echo "  ./docker.sh clean"
            echo "  ./docker.sh rebuild"
            ;;
    esac
}

main "$@"
