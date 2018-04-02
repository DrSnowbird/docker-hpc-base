#!/bin/bash -x

MY_DIR="$(dirname $(readlink -f $0))"
MY_HOME="$HOME"

## Submit the job with a specific name
#MSUB -N singularity_gamess

## Specify resources
#MSUB  -l nodes=1,walltime=1:00 -W ENVREQUESTED:TRUE 

## Combine the standard out and standard error in the same output file
#MSUB -j oe
#MSUB -o singularity_gamess.out

## Pass environment variables
#MSUB -E

## Before running, make sure you have the image downloaded in the folder 
## with custom local image name
# singularity pull --name docker-gamess.simg docker://openkbs/docker-gamess 
# 

IMAGE_PATH=docker://openkbs
## 
#IMAGE_PATH=shub://openkbs

IMAGE_TAG=docker-gamess
IMAGE_NAME=${IMAGE_TAG}.simg

if [ ! -e "${IMAGE_NAME}" ]; then
    # singularity pull --name docker-gamess.simg docker://openkbs/docker-gamess # with custom name
    singularity pull --name ${IMAGE_NAME} ${IMAGE_PATH}/${IMAGE_TAG}
else
    echo "Docker image: ${IMAGE_NAME} already existing!"
fi

## Move into user's working directory
cd $PBS_O_WORKDIR

## ref: http://singularity.lbl.gov/docs-usage
## Run Singularity Container
## /usr/local/bin/singularity run funny.simg

## INPUT_PATH=/home/rsheu/github-PUBLIC/docker-gamess
INPUT_PATH=${MY_DIR}
/usr/local/bin/singularity run ${INPUT_PATH}/${IMAGE_NAME} "${INPUT_PATH}/X-0165-thymine-X.inp" -p 8

echo "Job submitted by $PBS_O_LOGNAME ran on $HOSTNAME"


