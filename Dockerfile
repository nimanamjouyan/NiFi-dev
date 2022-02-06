#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------

FROM openjdk:8-jdk

# This Dockerfile adds a non-root user with sudo access. Use the "remoteUser"
# property in devcontainer.json to use it. On Linux, the container user's GID/UIDs
# will be updated to match your local UID/GID (when using the dockerFile property).
# See https://aka.ms/vscode-remote/containers/non-root-user for details.
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Configure apt
RUN apt-get update \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends apt-utils dialog 2>&1 \
    #
    # Create a non-root user to use if preferred - see https://aka.ms/vscode-remote/containers/non-root-user.
    && groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    # [Optional] Add sudo support for the non-root user
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME\
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    #
    # Verify git, needed tools installed
    && apt-get -y install git openssh-client less iproute2 procps curl wget lsb-release \
    && curl -fsSL https://code-server.dev/install.sh | sh
# && code-server --extensions-dir /root/.vscode-server/extensions --install-extension vscjava.vscode-java-pack
# && code --extensions-dir /root/.vscode-server/extensions --install-extension vscjava.vscode-java-pack
# && apt purge codeserverdeps codeserverdeps




RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends tzdata curl ca-certificates fontconfig locales \
    && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_VERSION jdk-11.0.11+9

RUN set -eux; \
    ARCH="$(dpkg --print-architecture)"; \
    case "${ARCH}" in \
    aarch64|arm64) \
    ESUM='4966b0df9406b7041e14316e04c9579806832fafa02c5d3bd1842163b7f2353a'; \
    BINARY_URL='https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.11%2B9/OpenJDK11U-jdk_aarch64_linux_hotspot_11.0.11_9.tar.gz'; \
    ;; \
    armhf|armv7l) \
    ESUM='2d7aba0b9ea287145ad437d4b3035fc84f7508e78c6fec99be4ff59fe1b6fc0d'; \
    BINARY_URL='https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.11%2B9/OpenJDK11U-jdk_arm_linux_hotspot_11.0.11_9.tar.gz'; \
    ;; \
    ppc64el|ppc64le) \
    ESUM='945b114bd0a617d742653ac1ae89d35384bf89389046a44681109cf8e4f4af91'; \
    BINARY_URL='https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.11%2B9/OpenJDK11U-jdk_ppc64le_linux_hotspot_11.0.11_9.tar.gz'; \
    ;; \
    s390x) \
    ESUM='5d81979d27d9d8b3ed5bca1a91fc899cbbfb3d907f445ee7329628105e92f52c'; \
    BINARY_URL='https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.11%2B9/OpenJDK11U-jdk_s390x_linux_hotspot_11.0.11_9.tar.gz'; \
    ;; \
    amd64|x86_64) \
    ESUM='e99b98f851541202ab64401594901e583b764e368814320eba442095251e78cb'; \
    BINARY_URL='https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.11%2B9/OpenJDK11U-jdk_x64_linux_hotspot_11.0.11_9.tar.gz'; \
    ;; \
    *) \
    echo "Unsupported arch: ${ARCH}"; \
    exit 1; \
    ;; \
    esac; \
    curl -LfsSo /tmp/openjdk.tar.gz ${BINARY_URL}; \
    echo "${ESUM} */tmp/openjdk.tar.gz" | sha256sum -c -; \
    mkdir -p /opt/java/openjdk; \
    cd /opt/java/openjdk; \
    tar -xf /tmp/openjdk.tar.gz --strip-components=1; \
    rm -rf /tmp/openjdk.tar.gz;


#-------------------Uncomment the following steps to install Maven CLI Tools----------------------------------
ARG MAVEN_VERSION=3.6.3
ARG MAVEN_SHA=c35a1803a6e70a126e80b2b3ae33eed961f83ed74d18fcd16909b2d44d7dada3203f1ffe726c17ef8dcca2dcaa9fca676987befeadc9b9f759967a8cb77181c0
RUN mkdir -p /usr/share/maven /usr/share/maven/ref \
    && export DEBIAN_FRONTEND=noninteractive \
    && curl -fsSL -o /tmp/apache-maven.tar.gz https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
    && echo "${MAVEN_SHA} /tmp/apache-maven.tar.gz" | sha512sum -c - \
    && tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
    && rm -f /tmp/apache-maven.tar.gz \
    && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn
COPY /vscode_settings/maven-settings.xml /usr/share/maven/ref/
COPY /vscode_settings/settings.json /root/.vscode-server/data/Machine/  
ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG /root/.m2
#-------------------------------------------------------------------------------------------------------------

#-------------------Uncomment the following steps to install Gradle CLI Tools---------------------------------
# ENV GRADLE_HOME /opt/gradle
# ENV GRADLE_VERSION 5.4.1
# ARG GRADLE_DOWNLOAD_SHA256=7bdbad1e4f54f13c8a78abc00c26d44dd8709d4aedb704d913fb1bb78ac025dc
# RUN curl -sSL --output gradle.zip "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" \
#     && export DEBIAN_FRONTEND=noninteractive \
#     && echo "${GRADLE_DOWNLOAD_SHA256} *gradle.zip" | sha256sum --check - \
#     && unzip gradle.zip \
#     && rm gradle.zip \
#     && mv "gradle-${GRADLE_VERSION}" "${GRADLE_HOME}/" \
#     && ln -s "${GRADLE_HOME}/bin/gradle" /usr/bin/gradle
#-------------------------------------------------------------------------------------------------------------

# Clean up
RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*
