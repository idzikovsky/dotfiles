FROM alpine:3

ENV SSH_CONFIG_DIR=/mnt/ssh
ENV DATA_DIR=/mnt/data
ENV SERVER_DIR=/mnt/data/server
ENV WORLD_DIRNAME=world
ENV BACKUP_DIR=/mnt/data/backup

# sshd gives login shells a clean environment, so re-export the vars via profile.d
RUN \
    echo "export SSH_CONFIG_DIR=${SSH_CONFIG_DIR}" >> /etc/profile.d/minecraft.sh && \
    echo "export DATA_DIR=${DATA_DIR}" >> /etc/profile.d/minecraft.sh && \
    echo "export SERVER_DIR=${SERVER_DIR}" >> /etc/profile.d/minecraft.sh && \
    echo "export WORLD_DIRNAME=${WORLD_DIRNAME}" >> /etc/profile.d/minecraft.sh && \
    echo "export BACKUP_DIR=${BACKUP_DIR}" >> /etc/profile.d/minecraft.sh

RUN apk add \
    bash \
    openjdk25-jre-headless \
    openssh \
    screen \
    shadow \
    supervisor \
    vim

RUN chsh -s /bin/bash root

COPY ssh/sshd.conf /etc/ssh/sshd_config.d/

RUN mkdir -p /etc/supervisor.d/
COPY supervisor.d/* /etc/supervisor.d/

COPY bin/backup /usr/local/bin

COPY entrypoint /

ENTRYPOINT [ "/entrypoint" ]
