FROM rocker/shiny:3.6.1

LABEL maintainer "Trey Saddler <saddlerto@nih.gov>"

RUN apt-get update && apt-get install -y \
    libbz2-dev \
    libx11-dev \
    libxml2-dev \
    libssl-dev \
    liblzma-dev \
    libpq-dev \
    openjdk-8-jdk \
    libglu1-mesa-dev \
    mesa-common-dev \
 && rm -rf /var/lib/apt/lists/*

# install dependencies of the euler app
RUN R -e "install.packages('packrat', repos='https://cloud.r-project.org/')"

# copy the app to the image
RUN rm -R /srv/shiny-server
RUN mkdir /srv/shiny-server
RUN mkdir /srv/shiny-server/pubchem-heatmap
RUN mkdir /srv/shiny-server/pubchem-heatmap/lib
RUN mkdir /srv/shiny-server/pubchem-heatmap/packrat

COPY server.R /srv/shiny-server/pubchem-heatmap/server.R
COPY ui.R /srv/shiny-server/pubchem-heatmap/ui.R
COPY lib /srv/shiny-heatmap/pubchem-heatmap/lib
COPY config.yml /srv/shiny-server/pubchem-heatmap/config.yml
COPY packrat/init.R /srv/shiny-server/pubchem-heatmap/packrat/init.R
COPY packrat/packrat.lock /srv/shiny-server/pubchem-heatmap/packrat/packrat.lock
COPY packrat/packrat.opts /srv/shiny-server/pubchem-heatmap/packrat/packrat.opts

COPY Rprofile.site /usr/lib/R/etc/

WORKDIR /srv/shiny-server/pubchem-heatmap

# RUN R -e "packrat::init()"
RUN R -e "packrat::restore()"

EXPOSE 3838
