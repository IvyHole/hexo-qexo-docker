FROM python:3.11
USER root
WORKDIR /app

ARG node_version=22.4.1
ARG mysql=false

# 安装node 22.4.1
RUN curl -o node.tar.gz https://nodejs.org/dist/v$node_version/node-$node_version-linux-x64.tar.gz \
    && tar -xvf node.tar.gz -C /usr/local --strip-components=1 \
    && rm -rf node.tar.gz

ENV PATH="/usr/local/bin:${PATH}"

COPY ./requirements-mysql.txt .
COPY ./requirements.txt .

# 下载qexo
RUN git clone -b dev https://github.com/Qexo/Qexo.git ./ \
    && \cp -a -f requirements.txt requirements-mysql.txt \
    && \cp -a -f requirements_withoutmysql.txt requirements.txt

RUN sed -i "s/qexo_data.db/\/db\/qexo_data.db/g" core/settings.py && \
    mkdir /db && \
    mkdir /blog

RUN apt-get update -y && \
    apt-get install -y debian-keyring debian-archive-keyring apt-transport-https && \
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg && \
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list && \
    apt-get update -y && \
    apt-get install -y caddy dumb-init

RUN curl -Ljo pandoc.deb https://github.com/jgm/pandoc/releases/download/3.2.1/pandoc-3.2.1-1-amd64.deb \
    apt-get install -y ./pandoc.deb

# pip
RUN python -m pip install --upgrade pip
RUN if [[ $mysql == "false" ]];then \
    pip install -r requirements.txt; \
    else \
    pip install -r requirements-mysql.txt;

# npm
RUN npm install -g hexo-cli hexo-renderer-pug \
    hexo-renderer-stylus hexo-deployer-git \
    hexo-abbrlink hexo-generator-search hexo-renderer-pandoc\
    hexo-filter-mathjax

EXPOSE 3000 8000
CMD ["/usr/bin/dumb-init", "--", "bash", "/app/start.sh"]


