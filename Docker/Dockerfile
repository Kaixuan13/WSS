# Get a base R docker image
FROM r-base:4.1.2

# Install additional R packages
RUN apt-get update -y && \
    apt-get install -y libxml2-dev \
    libssl-dev \
    libcurl4-openssl-dev
RUN install2.r --error \
    devtools \
    readr \
    dplyr \
    tidyr \
    ggplot2 \
    lubridate \
    zoo \
    RColorBrewer \
    jsonlite \
    openxlsx \
    ckanr

# Copy the code to the root directory of the image
ADD ./*.R ./*.r ./
ADD ./data /data

ARG WSS_VERSION=latest
ENV WSS_VERSION=${WSS_VERSION}

# Run the code when the docker instance is activated
CMD ["Rscript", "connector.R"]
