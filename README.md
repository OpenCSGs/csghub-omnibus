# How to build DEB/RPM packages locally

## Summary

This document is only used to guide users on how to build deb/rpm packages and container images.

## Build method

### Linux

#### DEB

_Tips: There is currently no need to distinguish between Debian distributions_

```shell
git clone git@git-devops.opencsg.com:product/infra/omnibus-csghub.git
cd omnibus-csghub && rm -rf .git* .idea Dockerfile *.md *.spec
cd .. 
dpkg-deb -Z xz -b omnibus-csghub omnibus-csghub_1.6.0-ee.0_amd64.deb
```

#### RPM

##### 1. Prepare the build environment

```shell
# Install required tools
sudo yum install -y rpm-build rpmdevtools

# Set up the RPM build tree
rpmdev-setuptree
```

##### 2. Create the package structure

```shell
# clone the repository
git clone git@git-devops.opencsg.com:product/infra/omnibus-csghub.git

# Create directories
mkdir -p ~/rpmbuild/SOURCES/omnibus-csghub-1.6.0

# Copy your files to the appropriate locations
# Assuming you have your files in /path/to/your/files
cp -r omnibus-csghub/etc/csghub/* ~/rpmbuild/SOURCES/omnibus-csghub-1.6.0/etc/csghub
cp -r omnibus-csghub/opt/csghub/* ~/rpmbuild/SOURCES/omnibus-csghub-1.6.0/opt/csghub

# Copy systemd service file if you have one
cp omnibus-csghub/etc/systemd/csghub-runsvdir.service ~/rpmbuild/SOURCES/omnibus-csghub-1.6.0/

# Create tarball
cd ~/rpmbuild/SOURCES
tar -czvf omnibus-csghub-1.6.0.tar.gz omnibus-csghub-1.6.0/
```

##### 3. Copy the spec file

```shell
cp omnibus-csghub/omnibus-csghub.spec ~/rpmbuild/SPECS/omnibus-csghub.spec
```

##### 4. Build the RPM

```shell
# Build the RPM package
rpmbuild -bb ~/rpmbuild/SPECS/omnibus-csghub.spec

# The built RPM will be in:
# ~/rpmbuild/RPMS/x86_64/omnibus-csghub-1.6.0-1.el7.x86_64.rpm (or similar)
```

##### 5. Verification

```shell
# Check the package contents
rpm -qlp ~/rpmbuild/RPMS/x86_64/omnibus-csghub-*.rpm

# Check the package metadata
rpm -qip ~/rpmbuild/RPMS/x86_64/omnibus-csghub-*.rpm
```

#### Key Differences from Debian to RPM

1. **Spec File Structure**: RPM uses a single `.spec` file instead of multiple control files
2. **Script Sections**:
    - `%pre` replaces `preinst`
    - `%post` replaces `postinst`
    - `%preun` replaces `prerm`
    - `%postun` replaces `postrm`
3. **File Ownership**: RPM uses `%defattr` and `%attr` macros for file permissions
4. **Dependencies**:
    - `Requires` replaces `Depends`
    - `Obsoletes` replaces `Replaces`
5. **Version Comparison**: RPM handles version comparisons internally, no need for dpkg checks



