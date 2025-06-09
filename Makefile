# 定义默认目标
.PHONY: all
all: build

# 从 version-manifest.json 提取所有组件的版本信息并格式化为 Docker build args
VERSION_MANIFESTS := opt/csghub/version-manifests.json
DOCKER_BUILD_ARGS := $(shell jq -r '.version_manifest.components[] | "--build-arg \(.name | ascii_upcase)_VERSION=\(.version)"' $(VERSION_MANIFESTS) | tr '\n' ' ')

# 镜像仓库配置
REGISTRY := opencsg-registry.cn-beijing.cr.aliyuncs.com/opencsg_public
IMAGE_NAME := omnibus-csghub

# 从 manifest 获取版本号，如果没有则使用默认值
IMAGE_TAG := $(shell jq -r '.version_manifest.metadata.version' $(VERSION_MANIFESTS))

# 构建平台配置
PLATFORMS := linux/arm64,linux/amd64

.PHONY: install-tools
install-tools:
	@echo "Installing required tools..."
	@if ! command -v jq >/dev/null 2>&1; then \
		echo "Installing jq..."; \
		sudo apt-get update && sudo apt-get install -y jq; \
	fi
	@if ! command -v docker-buildx >/dev/null 2>&1; then \
		echo "Setting up docker buildx..."; \
		docker buildx install; \
	fi
	@echo "All tools are ready."

# 检查必要工具是否安装m
.PHONY: check-tools
check-tools:
	@echo "Checking required tools..."
	@command -v docker >/dev/null 2>&1 || { echo >&2 "Error: docker is required but not installed."; exit 1; }
	@command -v jq >/dev/null 2>&1 || { echo >&2 "Error: jq is required but not installed."; exit 1; }
	@command -v docker-buildx >/dev/null 2>&1 || { echo >&2 "Error: docker buildx is required but not installed."; exit 1; }
	@echo "All required tools are installed."

# 检查必要文件是否存在
.PHONY: check-files
check-files:
	@echo "Checking required files..."
	@test -f "$(VERSION_MANIFESTS)" || { echo >&2 "Error: version manifest file $(VERSION_MANIFESTS) not found."; exit 1; }
	@test -f "Dockerfile" || { echo >&2 "Error: Dockerfile not found."; exit 1; }
	@echo "All required files exist."

# 工具和文件检查
.PHONY: check-deps
check-deps: check-tools check-files

# 构建 Docker 镜像
.PHONY: build
build: check-deps
	@echo "Building Docker image with the following build arguments:"
	@echo $(DOCKER_BUILD_ARGS)
	docker build $(DOCKER_BUILD_ARGS) \
		-t $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG) \
		-t $(REGISTRY)/$(IMAGE_NAME):latest \
		.

# 多平台构建并推送
.PHONY: buildx-push
buildx-push: check-deps
	@echo "Building multi-platform images with buildx and pushing to registry"
	@echo "Build arguments: $(DOCKER_BUILD_ARGS)"
	docker buildx build --provenance false \
		--platform $(PLATFORMS) \
		$(DOCKER_BUILD_ARGS) \
		-f Dockerfile \
		-t $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG) \
		-t $(REGISTRY)/$(IMAGE_NAME):latest \
		--push .

# 显示版本信息
.PHONY: versions
versions:
	@echo "Component versions:"
	@jq -r '.version_manifest.components[] | "\(.name | ascii_upcase)_VERSION=\(.version)"' $(VERSION_MANIFESTS)

# 清理构建的镜像
.PHONY: clean
clean:
	@echo "Removing local images..."
	-docker rmi $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG) 2>/dev/null || true
	-docker rmi $(REGISTRY)/$(IMAGE_NAME):latest 2>/dev/null || true