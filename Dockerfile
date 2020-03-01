# sphinx-pdf
FROM ubuntu:18.04

LABEL maintainer="Xing Zhang <angeiv.zhang@gmail.com>"

ENV \
    BUILDER_VERSION=1.0 \
    # Path to be used in other layers to place s2i scripts into
    STI_SCRIPTS_PATH=/usr/libexec/s2i \
    APP_ROOT=/opt/app-root \
    # The $HOME is not set by default, but some applications needs this variable
    HOME=/opt/app-root/src \
    PATH=/opt/app-root/src/bin:/opt/app-root/bin:/opt/app-root/src/.local/bin:$PATH \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

LABEL io.k8s.description="Platform for building Sphinx PDF" \
      io.k8s.display-name="builder 0.1.0" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="builder,0.1.0,etc." \
      io.openshift.s2i.scripts-url="image:///usr/libexec/s2i"

# Install required packages here:
RUN apt-get update && \
    apt-get install --no-install-recommends --no-install-suggests -y \
        locales \
        locales-all \
        git \
        make \
        fontconfig \
        python3-pip \
        python3-setuptools \
        python3-wheel \
        latexmk \
        texlive-xetex \
        texlive-fonts-recommended && \
    apt-get remove --purge --auto-remove -y && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/*

# (TODO): Add font
#ADD yourfont.ttf /usr/local/share/fonts
#RUN fc-cache -f -v

# (optional): Copy the builder files into /opt/app-root
# COPY ./<builder_folder>/ /opt/app-root/

# Copy extra files to the image.
COPY ./root/ /

# Copy the S2I scripts to /usr/libexec/s2i, since openshift/base-centos7 image
# sets io.openshift.s2i.scripts-url label that way, or update that label
RUN mkdir -p /usr/libexec/s2i
COPY ./s2i/bin/ /usr/libexec/s2i

# Add default user
RUN mkdir -p ${HOME} && \
  useradd -u 1001 -r -g 0 -d ${HOME} -s /sbin/nologin \
      -c "Default Application User" default && \
  chown -R 1001:0 ${APP_ROOT}

# Drop the root user and make the content of /opt/app-root owned by user 1001
RUN chown -R 1001:1001 /opt/app-root

# This default user
USER 1001

EXPOSE 8080

WORKDIR ${HOME}

CMD ["/usr/libexec/s2i/usage"]
