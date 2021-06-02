FROM tensorflow/tensorflow:2.1.0-py3

LABEL maintainer="Minamoto Xu<migawari@google.com>"

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    net-tools \
    nano \
    nginx \
    libcurl3-dev \
    libfreetype6-dev \
    libhdf5-serial-dev \
    libpng-dev \
    libzmq3-dev \
    pkg-config \
    python3-dev \
    software-properties-common \
    unzip \
    zip \
    zlib1g-dev \
    unzip \
    cmake \
    libsm6 \
    python3-opencv \
    libdlib-dev \
    libjpeg-turbo8-dev \
    libopenblas-dev \
    && \
    apt-get clean \
    && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime ; \
    echo "Asia/Shanghai" > /etc/timezone ; \
    dpkg-reconfigure -f noninteractive tzdata ; \
    rm -rf /var/lib/apt/lists/*

RUN ln -s -f /usr/bin/python3 /usr/bin/python && \
    curl -fSskL -O https://bootstrap.pypa.io/get-pip.py && \
    python3 get-pip.py && \
    rm get-pip.py

RUN pip --no-cache-dir install -U \
    Pillow \
    h5py \
    dlib \
    ipykernel \
    jupyter \
    keras_applications \
    keras_preprocessing \
    matplotlib \
    mock \
    numpy \
    scipy \
    sklearn \
    pandas \
    opencv-python \
    imutils \
    flask \
    face_recognition \
    && \
    python3 -m ipykernel.kernelspec

COPY default /etc/nginx/sites-available/default
