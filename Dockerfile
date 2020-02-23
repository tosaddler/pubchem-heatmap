FROM rocker/shiny-verse:3.6.1

LABEL maintainer "Trey Saddler <saddlerto@nih.gov>"

RUN apt-get update && apt-get install -y \
    libbz2-dev \
    liblzma-dev \
    libglu1-mesa-dev \
    libpq-dev \
    libssl-dev \
    libx11-dev \
    libxml2-dev \
    mesa-common-dev \
    openjdk-8-jdk \
 && rm -rf /var/lib/apt/lists/*

# copy the app to the image
RUN rm -R /srv/shiny-server
RUN mkdir -p /srv/shiny-server/pubchem-heatmap

WORKDIR /srv/shiny-server/pubchem-heatmap

COPY server.R server.R
COPY ui.R ui.R
COPY lib lib
COPY config.yml config.yml

COPY Rprofile.site /usr/lib/R/etc/

# Install necessary packages
RUN install2.r -d TRUE -e -s \
    clusterSim \
    config \
    data.table \
    data.tree \
    jsonlite \
    RCurl \
    RPostgres \
    shinyHeatmaply \
    stringr \
    tidyverse

EXPOSE 3838
