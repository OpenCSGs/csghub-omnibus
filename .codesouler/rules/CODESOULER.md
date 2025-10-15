# CODESOULER.md

本文档为AI助手提供本代码库的工作指引。

## 项目概述
- **项目名称**: Omnibus-CSGHub
- **核心功能**: 企业级AI模型管理平台的一键式Docker部署方案
- **技术栈**: Docker Compose + 容器化微服务架构
- **关键组件**: Nginx, PostgreSQL, Redis, MinIO等
- **部署目标**: 快速搭建AI模型管理环境（开发/测试/生产）

## 关键命令
### 部署命令
```bash
# 基础功能部署（不含K8s相关功能）
docker compose -f docker-compose-simple.yml up -d

# 完整功能部署（需预先配置K8s环境）
docker compose -f docker-compose.yml up -d
```

### 服务管理
```bash
# 查看服务状态
csghub-ctl status

# 重启服务
csghub-ctl restart

# 查看实时日志
csghub-ctl tail
```

## 架构详解
### 核心架构
- **容器化微服务架构**: 各组件独立容器运行
- **配置分层管理**:
  1. 环境变量 (最高优先级)
  2. /etc/csghub/csghub.yaml
  3. 默认配置 /opt/csghub/etc/csghub/default.yaml


## 配置优先级说明
1. **环境变量** (最高优先级): `CSGHUB_OMNIBUS_CONFIG`
2. **配置文件**: `/etc/csghub/csghub.yaml`
3. **默认配置**: `/opt/csghub/etc/csghub/default.yaml`

## 典型问题排查
```bash
# 服务启动失败检查
csghub-ctl tail  [服务名]

# 数据库连接测试
csghub-psql -c "\l"
```
