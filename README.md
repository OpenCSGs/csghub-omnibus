# Omnibus-CSGHub - Docker Compose Deployment Solution

Omnibus-CSGHub is a one-click Docker Compose deployment solution for OpenCSG CSGHub, enabling rapid setup of enterprise-grade AI model management platforms.

This solution simplifies CSGHub installation and configuration through containerization, making it ideal for quick deployment and development/testing environments.

For full installation guides, see the [Quick Start](https://opencsg.com/docs/csghub/101/install/quick-start/overview) and [Kubernetes deployment](https://opencsg.com/docs/csghub/101/install/kubernetes/overview) docs.

## Key Features

- **Quick Deployment**: Launch the complete CSGHub service stack with a single command.
- **Fully Containerized**: All components (web frontend, backend services, DB, etc.) run as containerized services.
- **Environment Isolation**: Independent services prevent environment conflicts.
- **Easy Maintenance**: Unified service configuration via Compose files.
- **Flexible Scaling**: Adjust resources and scale services as needed.

## Use Cases

- Quickly set up CSGHub demo environments.
- Development and testing environment deployments.
- Small-to-medium production environment deployments.
- Scenarios requiring quick validation of CSGHub functionality.

With Omnibus-CSGHub, deploy CSGHub in minutes and start managing your AI models and data assets immediately.

## Running the Service

### Feature Description

Due to the complexity of CSGHub configuration, starting CSGHub is divided into two modes:

- **Basic Features**: Does not include Kubernetes-dependent functionalities such as model evaluation, inference, fine-tuning, and Spaces.
- **Full Features**: Includes all functionalities of both ce/ee editions.

*Special Note: MCP functionality will be limited when using IP address configuration (this feature requires a domain name).*

### Additional Prerequisites

- Docker Compose Plugin 1.12.0+
- Kubernetes 1.28+ (Required for full-featured installation only)

### Run CSGHub

- Basic Features

    ```shell
    docker compose -f example/ce/docker-compose.yml up -d
    ```

- Full Features

    ```shell
    docker compose -f example/ee/docker-compose.ee.yml up -d
    ```

    For full features, modify these parameters:

    - `environment.CSGHUB_OMNIBUS_CONFIG.runner.deploy.knative.services[0].host` — set to the IP address for accessing the Kubernetes API Server.
    - `volumes` — map the `.kube` directory to CSGHub.

- To stop the service, run the same command replacing `up` with `down`:

    ```shell
    docker compose -f [compose-file] down
    ```

## Manage CSGHub

### Configuration

- `CSGHUB_OMNIBUS_CONFIG`

    This configuration variable has the highest priority and won't be overridden by any other configurations. It's primarily used for passing custom variables during Docker Compose startup.

- `/etc/csghub/csghub.yaml`

    Contains all configurable parameters, with minimal modifications typically required under default settings.

- `/opt/csghub/embedded/etc/csghub/default.yaml`

    Defines the default values for all parameters (lowest priority).

### Service Management

- `csghub-ctl`

    | Options     | Usage                              |
    | ----------- | ---------------------------------- |
    | --help      | Get command help                   |
    | start       | Start the service                  |
    | restart     | Restart the service                |
    | stop        | Stop the service                   |
    | reload      | Reload the service                 |
    | tail        | View service logs in real time     |
    | status      | View service status                |
    | other       | See `--help`                       |

- `csghub-psql`

    Used to quickly log in to the database.