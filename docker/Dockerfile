# Image to be used as a base, e.g. one of the official ones:
# https://github.com/docker-library/official-images/blob/master/library/debian
FROM debian:sid

# install packages
RUN apt-get update

# main packages
RUN apt-get install -y grml-debootstrap bats eatmydata

# convenient packages
RUN apt-get install -y curl less vim wget zsh

# grml config
RUN wget -O /root/.vimrc https://raw.githubusercontent.com/grml/grml-etc-core/master/etc/vim/vimrc \
    && wget -O /root/.zshrc https://raw.githubusercontent.com/grml/grml-etc-core/master/etc/zsh/zshrc

# nice defaults
ENV LANG C.UTF-8
ENV TERM xterm-256color

# be verbose about package versions
RUN echo 'APT::Get::Show-Versions "1";' > /etc/apt/apt.conf.d/verbose

# cleanup
RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/bin/zsh"]
