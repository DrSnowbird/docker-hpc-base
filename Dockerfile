ARG IMAGE_VERSION=${IMAGE_VERSION:-16.04}
FROM ubuntu:$IMAGE_VERSION

MAINTAINER DrSnowbird "drsnowbird@openkbs.org"

### ---- Thanks the Contributions from:  Ryan Olson <rolson@nvidia.com>

ENV DEBIAN_FRONTEND noninteractive

#### Build argument ####
# Modify by adding the following argument during docker build:
#
#   --build-arg BLAS=[none|atlas]
#
ARG BLAS=${BLAS:-atlas}
ARG BLAS_DIR=${BLAS_DIR:-/usr/lib/atlas-base}

ARG MPI=${MPI:-openmpi}
ARG MPI_DIR=${MPI_DIR:-/usr/lib/openmpi}

#############################################################
#### ---- Setup basic & dependent libraries ----
#############################################################
#
# ref: http://lsi.ugr.es/jmantas/pdp/ayuda/datos/instalaciones/Install_OpenMPI_en.pdf
## E: Unable to locate package libopenmpi-dbg

RUN apt-get update \
    && apt-get install -y bzip2 wget make gcc gfortran csh vim \
    && apt-get install -y openssh-client openssh-server \
    && apt-get install -y openmpi-bin openmpi-common libopenmpi-dev \
    && apt-get install -y libblas-dev liblapack-dev \
    && apt-get install -y libatlas-dev libatlas-base-dev libatlas3-base \
    && apt-get clean autoclean \
    && apt-get autoremove -y
    
ENV LD_LIBRARY_PATH=${BLAS_DIR}:$LD_LIBRARY_PATH
ENV LD_LIBRARY_PATH=${MPI_DIR}:$LD_LIBRARY_PATH

#### ---- fix openmpi's include folder is located at different location
RUN mkdir -p /usr/lib64 && \
    ln -s ${BLAS_DIR} /usr/lib64/atlas && \
    ln -s ${MPI_DIR} /usr/lib64/openmpi && \
    ln -s ${MPI_DIR} /opt/openmpi

#############################################################
#### ---- Setup InifinBand & OpenMPI inside Docker ----
#############################################################
#
# Thanks the Contributions from:  Ryan Olson <rolson@nvidia.com>
#
#Regarding ports from Docker to Singularity - are you having problem with Singularity’s built-in converter?  We’ve had a lot of success using Docker images as our source of truth, then using Singularity to convert those images for runtime on HPC clusters.  Regarding OpenMPI - we’ve had some success in installing the mellanox components inside the container, building openmpi using those.  By default, openmpi will check for the presence of IB and fall back to TCP.
#Here’s the dockerfile recipe I used for OpenMPI.  This gets full IB perf via Docker and Singularity (using the built-in converter):

RUN apt-get update && apt-get install -y --no-install-recommends \
    file \
    flex \
    g++ \
    gcc \
    gfortran \
    less \
    libdb5.3-dev \
    make \
    wget
 
RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-utils \
    ifenslave \
    dapl2-utils \
    ibutils \
    ibverbs-utils \
    infiniband-diags \
    libdapl-dev \
    libibcm-dev \
    libibverbs1-dbg \
    libmlx4-1-dbg \
    libmlx4-dev \
    libmlx5-1-dbg \
    libmlx5-dev \
    librdmacm-dev \
    mstflint \
    opensm \
    perftest \
    srptools  && \
    rm -rf /var/lib/apt/lists/*

#############################################################
#### ---- Setup OpenMPI ----
#############################################################

#ADD openmpi-3.0.0.tar.bz2 /source
ARG OPENMPI_VERSION=${OPENMPI_VERSION:-3.0.0}
RUN wget --no-check-certificate https://www.open-mpi.org/software/ompi/v3.0/downloads/openmpi-${OPENMPI_VERSION}.tar.gz && \
    tar xvzf openmpi-${OPENMPI_VERSION}.tar.gz && \
    cd openmpi-${OPENMPI_VERSION} && \
    CFLAGS=-O3 CXXFLAGS=-O3 ./configure --prefix=/usr --sysconfdir=/mnt/0 --disable-pyt-support && \
    make -j8 install

##WORKDIR /source

## Somehow OSU_VERSION:-5.4.1 build has some missing files. back to 5.3.2
#ARG OSU_VERSION=${OSU_VERSION:-5.4.1}
##RUN export OSU_VERSION=5.3.2 && \
#RUN \
#   wget --no-check-certificate http://mvapich.cse.ohio-state.edu/download/mvapich/osu-micro-benchmarks-${OSU_VERSION}.tar.gz && \
#   tar xvzf osu-micro-benchmarks-${OSU_VERSION}.tar.gz 
#   rm -rf osu-micro-benchmarks-${OSU_VERSION}.tar.gz && \
#   cd osu-micro-benchmarks-${OSU_VERSION} && \
#   mkdir build.openmpi && \
#   cd build.openmpi && \
#   ../configure CC=mpicc --prefix=$(pwd) && \
#   make && make install
   
## (other reference for the above build flags): 
##    https://ulhpc-tutorials.readthedocs.io/en/latest/advanced/OSU_MicroBenchmarks/
##
## ../src/osu-micro-benchmarks-5.4/configure CC=mpiicc CXX=mpiicpc CFLAGS=-I$(pwd)/../src/osu-micro-benchmarks-5.4/util --prefix=$(pwd)

#### ----------------------------
#### ----- Application Entry ----
#### ----------------------------
# dummy entrypoint.sh file is used below
# 
COPY entrypoint.sh /entrypoint.sh
#ENTRYPOINT ["/entrypoint.sh"]

#### ---- When ready, uncomment this line below ----
#CMD "${GAMESS_RUN_DIR}/gamess_dft-grad-b_1024.bat" "672" "28"
CMD ["/bin/bash"]
