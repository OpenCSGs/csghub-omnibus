# Omnibus-CSGHub - Docker Compose Deployment Solution

Omnibus-CSGHub 是 OpenCSG CSGHub 的一键式 Docker Compose 部署方案，让您能够快速搭建企业级 AI 模型管理平台。  
*Omnibus-CSGHub is a one-click Docker Compose deployment solution for OpenCSG CSGHub, enabling rapid setup of enterprise-grade AI model management platforms.*

这个解决方案通过容器化技术简化了 CSGHub 的安装和配置过程，特别适合快速部署和开发测试环境使用。  
*This solution simplifies CSGHub installation and configuration through containerization, making it ideal for quick deployment and development/testing environments.*

## 主要特性 | Key Features

- **快速部署**：只需一条命令即可启动完整的 CSGHub 服务栈  

    ***Quick Deployment**: Launch the complete CSGHub service stack with a single command*  

- **全容器化**：所有组件（Web 前端、后端服务、数据库等）均以服务形式运行在容器内部  

    ***Fully Containerized**: All components (web frontend, backend services, DB, etc.) run as containerized services*  

- **环境隔离**：各服务独立运行，避免环境冲突  

    ***Environment Isolation**: Independent services prevent environment conflicts*  

- **易于维护**：通过 Compose 文件统一管理服务配置  

    ***Easy Maintenance**: Unified service configuration via Compose files*  

- **灵活扩展**：支持根据需求调整资源配置和服务规模  

    ***Flexible Scaling**: Adjust resources and scale services as needed*  

## 适用场景 | Use Cases

- 快速搭建 CSGHub 演示环境  

    *Quickly set up CSGHub demo environments*  

- 开发测试环境部署  

    *Development and testing environment deployments*  

- 中小规模生产环境部署  

    *Small-to-medium production environment deployments*  

- 需要快速验证 CSGHub 功能的场景  

    *Scenarios requiring quick validation of CSGHub functionality*  

使用 Omnibus-CSGHub，您可以在几分钟内完成 CSGHub 的部署，立即开始管理您的 AI 模型和数据资产。  
*With Omnibus-CSGHub, deploy CSGHub in minutes and start managing your AI models and data assets immediately.*

## 运行服务 | Running the Service

### 功能说明 Feature Description

因 CSGHub 配置的复杂性，启动 CSGhub 分为以下两种方式：  
*Due to the complexity of CSGHub configuration, starting CSGHub is divided into two modes:*

- **基本功能：** 不启动包含模型评测，模型推理，模型微调，Space 等在内的依托于 Kubernetes 的相关功能。  

    ***Basic Features:** Does not include Kubernetes-dependent functionalities such as model evaluation, inference, fine-tuning, and Spaces.*

- **完整功能：** 包含 ce/ee 的完整功能。  

    ***Full Features:** Includes all functionalities of both ce/ee editions.*

*特别说明：如果使用 IP 地址配置访问，MCP 功能使用受限（此功能依赖域名）。*  
*Special Note: MCP functionality will be limited when using IP address configuration (this feature requires domain name).*

### 其他前置条件 Additional Prerequisites

- Docker Compose Plugin 1.12.0+  
- Kubernetes 1.28+ (Required for full-featured installation only)

### 运行 Run CSGHub

- 基本功能 Basic Features

    ```shell
    docker compose -f docker-compose-simple.yml up -d 
    ```

- 完整功能 Full Features

    ```shell
    docker compose -f docker-compose.yml up -d 
    ```

    完整功能需要修改如下参数：  
    *For full features, modify these parameters:*

    - `environment.CSGHUB_OMNIBUS_CONFIG.runner.deploy.knative.services[0].host` 修改为访问 Kubernetes API Server的 IP 地址。  
      *Update to the IP address for accessing Kubernetes API Server.*
    
    - `volumes[3]`映射`.kube`目录到CSGHub。  
      *Map the `.kube` directory to CSGHub.*

- 停止服务执行相同操作（将up替换为down）：  
    *To stop the service, execute the same command replacing 'up' with 'down':*

    ```shell
    docker compose -f [compose-file] down
    ```

### 管理 Manage CSGHub

#### 配置管理 Manage Configuration

- 配置变量 `CSGHUB_OMNIBUS_CONFIG`

    配置变量具有最高优先级，不会被任何其他配置覆盖，主要用于 Docker Compose 启动时自定义变量的传入。

    *This configuration variable has the highest priority and won't be overridden by any other configurations. It's primarily used for passing custom variables during Docker Compose startup.*

- 可配置参数文件 `/etc/csghub/csghub.yaml`

    定义了所有可配置修改参数，默认情况下极少参数需要做修改。

    *Contains all configurable parameters, with minimal modifications typically required under default settings.*

- 默认参数文件 `/opt/csghub/etc/csghub/default.yaml`

    定义了所有参数的默认值。

    *Defines the default values for all parameters. default configuration (lowest priority).*

#### 服务管理 Manage Service

- `csghub-ctl`

    | 选项 OPTIONS | 用途 Usage                                        | 备注 Remark |
    | ------------ | ------------------------------------------------- | ----------- |
    | --help       | 获取命令帮助 *Get command help*                   |             |
    | start        | 启动服务 *Start the service*                      |             |
    | restart      | 重启服务 *Restart the service*                    |             |
    | stop         | 停止服务 *Stop the service*                       |             |
    | reload       | 重载服务 *Reload the service*                     |             |
    | tail         | 实时查看服务日志 *View service logs in real time* |             |
    | status       | 查看服务状态 *View service status*                |             |
    | other        | 见 `--help`                                       |             |

- `csghub-psql`

    用于快速登录数据库。

    *Used to quickly login to the database.*



