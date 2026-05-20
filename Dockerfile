# ppmi-dbs-pain reproducibility container
# rocker/r-ver:4.5.1 base + jupyter + IRkernel + Python 3.13
FROM rocker/r-ver:4.5.1

ENV DEBIAN_FRONTEND=noninteractive

# System deps for R packages requiring system libraries
RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev libssl-dev libxml2-dev \
    libfontconfig1-dev libfreetype6-dev libharfbuzz-dev libfribidi-dev \
    libgit2-dev libpng-dev libtiff5-dev libjpeg-dev \
    libudunits2-dev libgdal-dev libgeos-dev libproj-dev \
    libcairo2-dev libxt-dev \
    python3 python3-pip python3-venv \
    pandoc curl git make \
    && rm -rf /var/lib/apt/lists/*

# Quarto (for the rendered book)
RUN curl -L -o /tmp/quarto.deb \
        "https://github.com/quarto-dev/quarto-cli/releases/download/v1.5.57/quarto-1.5.57-linux-amd64.deb" \
    && dpkg -i /tmp/quarto.deb \
    && rm /tmp/quarto.deb

WORKDIR /work
COPY renv.lock /work/renv.lock

# Install renv + restore R packages
RUN R -e 'install.packages("renv", repos="https://cloud.r-project.org")' \
    && R -e 'renv::restore(prompt = FALSE)'

# Python deps
COPY requirements.txt /work/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the project (overridden by docker run -v)
COPY . /work

CMD ["make", "all"]
