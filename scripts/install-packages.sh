#!/bin/bash
# Install OS-level runtime dependencies for csghub-omnibus.
# Usage: install-packages.sh <ce|ee>
# Called from Dockerfile / ee.Dockerfile to keep package lists DRY.

set -euo pipefail

EDITION="${1:-}"
if [[ "$EDITION" != "ce" && "$EDITION" != "ee" ]]; then
    echo "Usage: $0 <ce|ee>" >&2
    exit 1
fi

# Packages that change name across Ubuntu versions.
# - libicu / libxml2: SONAME bumps (26.04 → libicu78 / libxml2-16)
# - *t64 suffix: 24.04+ time_t transition (readline, aprutil, geoip, curl)
ubuntu_version_specific() {
    local ver="$1"
    if dpkg --compare-versions "$ver" ge "26.04"; then
        echo "libicu78 libxml2-16 libreadline8t64 libaprutil1t64 libgeoip1t64 libcurl4t64"
    elif dpkg --compare-versions "$ver" ge "24.04"; then
        echo "libicu74 libxml2 libreadline8t64 libaprutil1t64 libgeoip1t64 libcurl4t64"
    else
        echo "libicu70 libxml2 libreadline8 libaprutil1 libgeoip1 libcurl3-gnutls"
    fi
}

# geoip lib differs across CentOS versions: 9+ uses libmaxminddb, 8 uses GeoIP.
centos_geoip_lib() {
    local major="$1"
    if [[ "$major" -ge 9 ]]; then
        echo "libmaxminddb"
    else
        echo "GeoIP"
    fi
}

# cap package — ce only, ee does not ship it.
if [[ "$EDITION" == "ce" ]]; then
    UBUNTU_CAP="libcap2-bin"
    CENTOS_CAP="libcap"
else
    UBUNTU_CAP=""
    CENTOS_CAP=""
fi

if grep -q -i -E 'ubuntu|debian' /etc/os-release; then
    # Aliyun mirror for faster apt downloads in CN CI.
    if [[ -f /etc/apt/sources.list ]]; then
        sed -i \
            -e 's|http://archive.ubuntu.com/ubuntu/|http://mirrors.aliyun.com/ubuntu/|g' \
            -e 's|http://security.ubuntu.com/ubuntu/|http://mirrors.aliyun.com/ubuntu/|g' \
            -e 's|http://ports.ubuntu.com/ubuntu-ports|http://mirrors.aliyun.com/ubuntu-ports|g' \
            /etc/apt/sources.list
    fi
    apt update

    UBUNTU_VERSION=$(grep -oP 'VERSION_ID="\K[\d.]+' /etc/os-release)
    SPECIFIC=$(ubuntu_version_specific "$UBUNTU_VERSION")

    DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
        ca-certificates \
        $SPECIFIC \
        libstdc++6 \
        netcat-openbsd \
        libgd3 \
        libxslt1.1 \
        libpq-dev \
        $UBUNTU_CAP \
        vim lsof jq curl \
        tzdata

    apt clean
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/log/*
else
    # CentOS/RHEL family.
    CENTOS_VERSION=$(grep -oP 'VERSION_ID="\K[\d.]+' /etc/os-release)
    CENTOS_MAJOR="${CENTOS_VERSION%%.*}"
    GEOIP=$(centos_geoip_lib "$CENTOS_MAJOR")

    COMMON_PKGS=(
        ca-certificates
        icu
        readline
        nmap-ncat
        apr-util
        $GEOIP
        gd
        libxml2
        libxslt
        libcurl
        postgresql-devel
        vim lsof jq curl
        tzdata
    )

    if command -v dnf >/dev/null; then
        dnf install -y "${COMMON_PKGS[@]}" $CENTOS_CAP
        dnf clean all
    else
        yum install -y "${COMMON_PKGS[@]}" $CENTOS_CAP
        yum clean all
    fi

    ln -s /usr/lib64/libcurl.so.4 /usr/lib64/libcurl-gnutls.so.4 || true
    rm -rf /var/cache/yum /tmp/* /var/tmp/* /var/log/*
fi
