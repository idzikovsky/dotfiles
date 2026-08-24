FROM rockylinux:9

RUN \
    echo "SSH_CONFIG_DIR=/mnt/ssh" >> /etc/environment && \
    echo "DATA_DIR=/mnt/data" >> /etc/environment && \
    echo "SERVER_DIR=/mnt/data/server" >> /etc/environment && \
    echo "WORLD_DIRNAME=world" >> /etc/environment && \
    echo "BACKUP_DIR=/mnt/data/backup" >> /etc/environment

RUN dnf install -y epel-release

RUN dnf install -y \
    java-25-openjdk-headless \
    openssh-server \
    screen \
    supervisor \
    wget

RUN dnf install -y \
    procps-ng \
    vim

COPY supervisor.d/* /etc/supervisord.d/

COPY ssh/sshd.conf /etc/ssh/sshd_config.d/

COPY bin/* /usr/local/bin/

COPY entrypoint /

ENTRYPOINT [ "/entrypoint" ]
