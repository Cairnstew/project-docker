FROM ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Environment
ENV USER=pzuser
ENV HOME=/home/${USER}
ENV ZOMBOIDGAMEID=108600
ENV PZSERVER_DIR=/opt/pzserver
ENV PZUSER_PASSWORD=pzpass

# Install dependencies
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y \
        lib32gcc-s1 \
        libc6-i386 \
        libstdc++6:i386 \
        libcurl4-gnutls-dev:i386 \
        libncurses5:i386 \
        libz1:i386 \
        curl \
        tar \
        sudo \
        ca-certificates \
        bash && \
    rm -rf /var/lib/apt/lists/*

# Create a user and give it sudo rights
RUN useradd -m -s /bin/bash ${USER} && \
    echo "${USER}:${PZUSER_PASSWORD}" | chpasswd && \
    usermod -aG sudo ${USER} && \
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER} && \
    chmod 0440 /etc/sudoers.d/${USER}

# Create server directory and set ownership
RUN mkdir -p ${PZSERVER_DIR} && chown ${USER}:${USER} ${PZSERVER_DIR}

# Define environment paths
ENV ZOMBOID=${HOME}/Zomboid \
    PZSERVER=${PZSERVER_DIR} \
    PZSERVERDIR=${HOME}/Zomboid/Server \
    PZSERVERDB=${HOME}/Zomboid/db/servertest.db \
    PZSERVERLOG=${HOME}/Zomboid/server-console.txt \
    PZSERVERSAVE=${HOME}/Zomboid/Saves \
    PZSERVERBACKUP=${HOME}/Zomboid/Backups \
    PZSERVERCONFIG=${HOME}/Zomboid/Server/servertest.ini \
    PZSERVERMAPDIR=${PZSERVER_DIR}/media/maps \
    PZSERVERMODDIR=${PZSERVER_DIR}/steamapps/workshop/content/${ZOMBOIDGAMEID} \
    PZSERVERSTART=${PZSERVER_DIR}/start-server.sh \
    PZSERVERSANDBOX=${HOME}/Zomboid/Server/servertest_SandboxVars.lua \
    PZSERVERSPAWNPOINTS=${HOME}/Zomboid/Server/servertest_spawnpoints.lua \
    PZSERVERSPAWNREGIONS=${HOME}/Zomboid/Server/servertest_spawnregions.lua \
    PZSERVERLOCK=/tmp/pzserver.${USER}.lock \
    STEAMCMD_UPDATE_SCRIPT=${HOME}/update_zomboid.txt

# Install SteamCMD
RUN mkdir -p ${HOME}/Steam && \
    curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | \
    tar -xz -C ${HOME}/Steam && \
    chown -R ${USER}:${USER} ${HOME}/Steam

ENV PATH="${HOME}/Steam:${PATH}"

USER ${USER}
# Generate SteamCMD update script
RUN /home/${USER}/Steam/steamcmd.sh \
    +@ShutdownOnFailedCommand 1 \
    +@NoPromptForPassword 1 \
    +force_install_dir /opt/pzserver/ \
    +login anonymous \
    +app_update 380870 validate \
    +quit

# Copy entrypoint script
COPY --chown=pzuser:pzuser entrypoint.sh ${HOME}/entrypoint.sh
RUN chmod +x ${HOME}/entrypoint.sh

# Set working directory
WORKDIR ${HOME}

# Run server with custom entrypoint
ENTRYPOINT ["bash", "/home/pzuser/entrypoint.sh"]
