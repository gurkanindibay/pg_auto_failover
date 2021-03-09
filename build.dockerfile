FROM ubuntu:20.04 as build-make
ENV PGVERSION 12
ENV TEST multi
ENV TRAVIS true
ENV PATH=$PATH:/app/pyenv/bin

WORKDIR /app
#RUN mkdir /app

# Prevent getting dialog when creating docker image
ENV TZ=Europe/Istanbul
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN echo $PATH
# Update and upgrade &&  apt-get -y upgrade
RUN  apt-get update && apt-get -y upgrade
#Install required packages for tool install
RUN apt-get -y install git sudo gnupg lsb-core make

#Install Tools
#RUN git clone -b v0.7.18 --depth 1 https://github.com/citusdata/tools.git
RUN git clone --single-branch --branch pg_auto_failover_build https://github.com/citusdata/tools.git




#Install nodejs for Azure Devops
RUN curl -fsSL https://deb.nodesource.com/setup_10.x | sudo -E bash - && sudo apt-get install -y nodejs

#Install apt-get if missing
RUN  make -C tools install
#Uninstall pg
RUN nuke_pg || true &&  apt-get --purge -y remove postgresql-* && echo 'exit 0' |  tee /etc/init.d/postgresql &&  chmod a+x /etc/init.d/postgresql
# Install Python and other dependencies
RUN  apt-get install -y software-properties-common &&  add-apt-repository ppa:deadsnakes/ppa &&  apt-get install -y  python3.6 &&  apt-get install -y  black &&  apt-get install -y  python3-pip &&  pip3 install nose virtualenv pipenv
# Install dependencies for make -j5
RUN  apt-get install -y libxml2-dev &&  apt-get install -y libxslt-dev &&  apt-get install -y libssl-dev &&  apt-get install -y libgssapi-krb5-2 &&  apt-get install -y libkrb5-dev &&  apt-get install -y libreadline-dev && apt-get install -y cmake
# Install uncrustify
RUN  apt-get install -y g++ && install_uncrustify &&  apt-get install -y cmake && apt-get install -y python-is-python3 iotop
#Install PG

RUN sudo apt -y install vim bash-completion wget && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" |sudo tee  /etc/apt/sources.list.d/pgdg.list
RUN grep ^ /etc/apt/sources.list /etc/apt/sources.list.d/* && pwd
#RUN sudo apt-get -y  install postgresql-common postgresql-contrib-13 libedit-dev libpam0g-dev libselinux1-dev postgresql-13 postgresql-server-dev-13
RUN install_pg && pg_config && PATH=`pg_config --bindir`:$PATH which pg_ctl &&  pip3 install psycopg2
RUN PYTHON_BIN_PATH="$(python3 -m site --user-base)/bin" && PATH="$PATH:$PYTHON_BIN_PATH"
#Install Pyenv
RUN  git clone https://github.com/pyenv/pyenv.git /app/pyenv

# Test PyEnv Installation
RUN pyenv install --list
RUN pyenv versions
RUN  pip3 install  pipenv
RUN apt-get install -y jq

#RUN pwd
#Clone pg_auto_failover gindibay-azure-pipelines-test
#RUN git clone --single-branch --branch gindibay-azure-pipelines-test https://github.com/gurkanindibay/pg_auto_failover.git

#WORKDIR /app/pg_auto_failover
#RUN mkdir tests && mkdir ci
#COPY tests/ ./tests/
#COPY ci/ /app/ci/

#RUN TESTS

#WORKDIR  /app/pg_auto_failover/tests
#RUN pipenv install psycopg2
#RUN pipenv install --system --deploy
#WORKDIR /app/pg_auto_failover
#RUN mkdir src
#COPY build-execute.sh /app
#COPY Makefile /app
#COPY src/ /app/src/
#RUN mkdir .git
#COPY .git/ /app/.git
#CMD ["sh","build-execute.sh"]

