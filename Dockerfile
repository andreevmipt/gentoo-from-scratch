# syntax = docker/dockerfile:1.2
# Use the empty image with the portage tree as the first stage
FROM gentoo/portage:latest as portage

# Gentoo stage3 is the second stage, basically an unpacked Gentoo Linux
FROM gentoo/stage3:amd64-systemd as base
# FROM ksmanis/stage3:latest as base

LABEL org.opencontainers.image.authors="andreev.mipt@gmail.com"

# Copy the portage tree into the current stage
#COPY --from=portage /var/db/repos/gentoo /var/db/repos/gentoo
# We can't use any sandboxing in the container.
ENV FEATURES="-ipc-sandbox -mount-sandbox -network-sandbox -pid-sandbox -sandbox -usersandbox"
ENV LANG C.UTF-8

#RUN --mount=type=bind,target=/var/db/repos/gentoo,source=/var/db/repos/gentoo,from=portage \
#    emerge-webrsync

# disable 32-bit compat
RUN --mount=type=bind,target=/var/db/repos/gentoo,source=/var/db/repos/gentoo,from=portage \
    eselect profile set default/linux/amd64/17.1/no-multilib

# Add make.conf to override the march.
# This allows packages to be optimized specifically for the host CPU.
#COPY base/pre-build/ /

RUN echo "PYTHON_TARGETS='python3_8 python3_9'" >> /etc/portage/make.conf
RUN echo "PYTHON_SINGLE_TARGET='python3_8'" >> /etc/portage/make.conf

RUN echo "ACCEPT_KEYWORDS='~amd64'" >> /etc/portage/make.conf
RUN echo "ACCEPT_LICENSE='*'" >> /etc/portage/make.conf
RUN echo "GENTOO_MIRRORS='http://mirror.yandex.ru/gentoo-distfiles/ https://mirror.yandex.ru/gentoo-distfiles/ http://ftp.fau.de/gentoo http://gentoo-mirror.alexxy.name/'" >> /etc/portage/make.conf
ADD wgetrc /etc/

RUN --mount=type=bind,target=/var/db/repos/gentoo,source=/var/db/repos/gentoo,from=portage \
    --mount=type=cache,id=distfiles,target=/var/cache/distfiles \
    --mount=type=cache,id=base-binpkgs-amd64-nom,target=/var/cache/binpkgs \
    emerge --buildpkg \
           --usepkg \
	   --binpkg-respect-use=y \
	   --binpkg-changed-deps=y \
	   -vu sys-apps/portage

RUN --mount=type=bind,target=/var/db/repos/gentoo,source=/var/db/repos/gentoo,from=portage \
    --mount=type=cache,id=distfiles,target=/var/cache/distfiles \
    --mount=type=cache,id=base-binpkgs-amd64-nom,target=/var/cache/binpkgs \
    emerge --buildpkg \
           --usepkg \
	   --binpkg-respect-use=y \
	   --binpkg-changed-deps=y \
	   --tree \
       --with-bdeps=y \
	   sys-devel/gcc:11

RUN --mount=type=bind,target=/var/db/repos/gentoo,source=/var/db/repos/gentoo,from=portage \
    --mount=type=cache,id=distfiles,target=/var/cache/distfiles \
    --mount=type=cache,id=base-binpkgs-amd64-nom,target=/var/cache/binpkgs \
    emerge --buildpkg \
           --usepkg \
	   --binpkg-respect-use=y \
	   --binpkg-changed-deps=y \
	   --tree \
       --with-bdeps=y \
	   -C sys-devel/gcc:9.3.0 sys-devel/gcc:9.4.0 sys-devel/gcc:10; exit 0

ADD locale.gen /etc/
RUN --mount=type=bind,target=/var/db/repos/gentoo,source=/var/db/repos/gentoo,from=portage \
    --mount=type=cache,id=distfiles,target=/var/cache/distfiles \
    --mount=type=cache,id=base-binpkgs-amd64-nom,target=/var/cache/binpkgs \
    emerge --buildpkg \
	   --binpkg-respect-use=y \
	   --binpkg-changed-deps=y \
	   --tree \
       --with-bdeps=y \
	   sys-libs/glibc

#RUN gcc-config 2

RUN --mount=type=bind,target=/var/db/repos/gentoo,source=/var/db/repos/gentoo,from=portage \
    --mount=type=cache,id=distfiles,target=/var/cache/distfiles \
    --mount=type=cache,id=base-binpkgs-amd64-nom,target=/var/cache/binpkgs \
    emerge --verbose --depclean

RUN --mount=type=bind,target=/var/db/repos/gentoo,source=/var/db/repos/gentoo,from=portage \
    --mount=type=cache,id=distfiles,target=/var/cache/distfiles \
    --mount=type=cache,id=base-binpkgs-amd64-nom,target=/var/cache/binpkgs \
    perl-cleaner --reallyall

RUN --mount=type=bind,target=/var/db/repos/gentoo,source=/var/db/repos/gentoo,from=portage \
    --mount=type=cache,id=distfiles,target=/var/cache/distfiles \
    --mount=type=cache,id=base-binpkgs-amd64-nom,target=/var/cache/binpkgs \
    emerge --buildpkg \
           --usepkg \
	   --binpkg-respect-use=y \
	   --binpkg-changed-deps=y \
	   --tree --with-bdeps=y --backtrack=100 --autounmask-keep-masks=y \
	   -vjuND @world

RUN --mount=type=bind,target=/var/db/repos/gentoo,source=/var/db/repos/gentoo,from=portage \
    --mount=type=cache,id=distfiles,target=/var/cache/distfiles \
    --mount=type=cache,id=base-binpkgs-amd64-nom,target=/var/cache/binpkgs \
    perl-cleaner --reallyall

RUN --mount=type=bind,target=/var/db/repos/gentoo,source=/var/db/repos/gentoo,from=portage \
    --mount=type=cache,id=distfiles,target=/var/cache/distfiles \
    --mount=type=cache,id=base-binpkgs-amd64-nom,target=/var/cache/binpkgs \
    revdep-rebuild

#RUN --mount=type=bind,target=/var/db/repos/gentoo,source=/var/db/repos/gentoo,from=portage \
#    --mount=type=cache,id=distfiles,target=/var/cache/distfiles \
#    --mount=type=cache,id=base-binpkgs-amd64-nom,target=/var/cache/binpkgs \
#    @golang-rebuild

RUN --mount=type=bind,target=/var/db/repos/gentoo,source=/var/db/repos/gentoo,from=portage \
    --mount=type=cache,id=distfiles,target=/var/cache/distfiles \
    --mount=type=cache,id=base-binpkgs-amd64-nom,target=/var/cache/binpkgs \
	emerge --depclean

FROM base as binpkgs

RUN echo "PYTHON_TARGETS='python3_8'" >> /etc/portage/make.conf
RUN echo "PYTHON_SINGLE_TARGET='python3_8'" >> /etc/portage/make.conf

RUN echo "dev-python/pip vanilla" >> /etc/portage/package.use/python.use
RUN echo "dev-util/strace aio unwind" >> /etc/portage/package.use/dev.use
RUN echo "dev-db/postgresql -server" >> /etc/portage/package.use/db.use
RUN echo "dev-db/oracle-instantclient odbc" >> /etc/portage/package.use/db.use

#	        dev-libs/nss dev-libs/nspr \
RUN --mount=type=bind,target=/var/db/repos/gentoo,source=/var/db/repos/gentoo,from=portage \
    --mount=type=cache,id=distfiles,target=/var/cache/distfiles \
    --mount=type=cache,id=base-binpkgs-amd64-nom,target=/var/cache/binpkgs \
    emerge --buildpkg \
           --usepkg \
	   --binpkg-respect-use=y \
	   --binpkg-changed-deps=y \
	   --tree \
	   -vj --backtrack=100 --autounmask-keep-masks=y \
	   -Du dev-lang/python:3.8 app-eselect/eselect-python dev-python/pip dev-python/tox app-shells/bash dev-python/wheel \
	        sys-devel/gcc sys-kernel/linux-headers sys-devel/binutils \
	        dev-db/unixODBC dev-db/psqlodbc dev-libs/librdkafka dev-db/mariadb-connector-odbc dev-db/oracle-instantclient \
            app-admin/sudo sys-apps/dbus \
	        dev-util/strace sys-process/procps sys-process/lsof sys-process/psmisc dev-util/cgdb dev-util/bcc dev-util/bpftrace\
	        net-misc/telnet-bsd net-misc/curl net-analyzer/traceroute app-shells/bash-completion net-misc/wget net-analyzer/netcat net-misc/iputils net-dns/bind-tools app-editors/nano


RUN quickpkg --include-config y "*/*"

#	        dev-libs/nss dev-libs/nspr \
ENV ROOT="/destination"
RUN --mount=type=bind,target=/var/db/repos/gentoo,source=/var/db/repos/gentoo,from=portage \
    --mount=type=cache,id=distfiles,target=/var/cache/distfiles \
    --mount=type=cache,id=base-binpkgs-amd64-nom,target=/var/cache/binpkgs \
    emerge --buildpkg \
           --usepkg \
	   --binpkg-respect-use=y \
	   --binpkg-changed-deps=y \
	   --tree \
	   -vj \
	   -Du dev-lang/python:3.8 app-eselect/eselect-python dev-python/pip dev-python/tox app-shells/bash dev-python/wheel \
	        sys-devel/gcc sys-kernel/linux-headers sys-devel/binutils \
            app-admin/sudo sys-apps/dbus \
            dev-db/unixODBC dev-db/psqlodbc dev-libs/librdkafka dev-db/mariadb-connector-odbc dev-db/oracle-instantclient \
	        dev-util/strace sys-process/procps sys-process/psmisc sys-process/lsof dev-util/cgdb dev-util/bcc dev-util/bpftrace\
	        net-misc/telnet-bsd net-misc/curl net-analyzer/traceroute app-shells/bash-completion net-misc/wget net-analyzer/netcat net-misc/iputils net-dns/bind-tools app-editors/nano

RUN rm -rf /destination/usr/share/doc /destination/var/db/pkg

# Start from an empty image
FROM scratch

# Copy the destination files from the previous stage
COPY --from=binpkgs /destination /
RUN eselect python set python3.8
ENV LANG C.UTF-8
RUN echo "root:x:0:0:root:/root:/bin/bash" >> /etc/passwd && mkdir /root

ADD odbcinst.ini /etc/unixODBC/

#ADD orca-1.3.1.AppImage /usr/bin/orca
#RUN chmod +x /usr/bin/orca

RUN mkdir ~/.pip && \
    printf "[global]\ntimeout = 1000\nindex-url = https://artifactory.host/artifactory/api/pypi/pypi-remote/simple" >> ~/.pip/pip.conf && \
    python -m pip install --trusted-host artifactory.host pip==20.3.3 && \
    python -m pip install --trusted-host artifactory.host setuptools==51.0.0 && \
    python -m pip install --trusted-host artifactory.host invoke && rm -rf /.cache



