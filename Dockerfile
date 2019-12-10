FROM ubuntu:latest

LABEL maintainer="Minamoto Xu<migawari@google.com>"
ENV DEBIAN_FRONTEND=noninteractive
RUN sudo add-apt-repository -y ppa:kagamih/dlib && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    libdlib-dev \
    libjpeg-turbo8-dev \
    libopenblas-dev \
    curl \
    git \
    net-tools \
    nano \
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
    && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime ; \
	echo "Asia/Shanghai" > /etc/timezone ; \
	dpkg-reconfigure -f noninteractive tzdata ; \
    apt-get clean && \
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
    && \
    python3 -m ipykernel.kernelspec

# Set up our notebook config.
# COPY jupyter_notebook_config.py /root/.jupyter/

# Jupyter has issues with being run directly:
#   https://github.com/ipython/ipython/issues/7062
# We just add a little wrapper script.
# COPY run_jupyter.sh /

# Set up Bazel.

# Running bazel inside a `docker build` command causes trouble, cf:
#   https://github.com/bazelbuild/bazel/issues/134
# The easiest solution is to set up a bazelrc file forcing --batch.
# RUN echo "startup --batch" >>/etc/bazel.bazelrc
# Similarly, we need to workaround sandboxing issues:
#   https://github.com/bazelbuild/bazel/issues/418
RUN echo "startup --batch" >>/etc/bazel.bazelrc && \
    echo "build --spawn_strategy=standalone --genrule_strategy=standalone" \
    >>/etc/bazel.bazelrc
# Install the most recent bazel release.
COPY bazel-0.26.0-installer-linux-x86_64.sh /tmp
RUN cd /tmp && \
    ./bazel-0.26.0-installer-linux-x86_64.sh && \
    rm -f /tmp/bazel-0.26.0-installer-linux-x86_64.sh

# ENV BAZEL_VERSION 0.26.0
# RUN mkdir /bazel && \
#     cd /bazel && \
#     curl -k -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.133 Safari/537.36" -fSsL -O https://github.com/bazelbuild/bazel/releases/download/$BAZEL_VERSION/bazel-$BAZEL_VERSION-installer-linux-x86_64.sh && \
#     curl -k -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.133 Safari/537.36" -fSsL -o /bazel/LICENSE.txt https://raw.githubusercontent.com/bazelbuild/bazel/master/LICENSE && \
#     chmod +x bazel-*.sh && \
#     ./bazel-$BAZEL_VERSION-installer-linux-x86_64.sh && \
#     cd / && \
#     rm -f /bazel/bazel-$BAZEL_VERSION-installer-linux-x86_64.sh

# Download and build TensorFlow.
# COPY tensorflow /tmp/
# WORKDIR /tmp

# # RUN git clone --branch=r2.0 --depth=1 https://github.com/tensorflow/tensorflow.git .

# # TODO(craigcitro): Don't install the pip package, since it makes it
# # more difficult to experiment with local changes. Instead, just add
# # the built directory to the path.

COPY go /usr/local/go
RUN echo "export PATH=$PATH:$HOME/go/bin:/usr/local/go/bin" >> /root/.bashrc && \
    go get -u github.com/Kagami/go-face
    go get -u github.com/xyzj/gopsu
    go get -u github.com/xyzj/gopsu/gin-middleware
    go get -u github.com/xyzj/gopsu/db
    go get -u github.com/tidwall/gjson
    go get -u github.com/tidwall/sjson
    go get -u github.com/go-redis/redis
    go get -u github.com/go-sql-driver/mysql
    go get -u github.com/denisenkom/go-mssqldb
    go get -u github.com/streadway/amqp
    go get -u github.com/gogo/protobuf/proto
    go get -u github.com/json-iterator/go
    go get -u github.com/gin-gonic/gin
    go get -u github.com/gin-gonic/gin/render
    go get -u github.com/gin-contrib/gzip
    go get -u github.com/gin-contrib/pprof
    go get -u github.com/gin-contrib/multitemplate
    go get -u github.com/gin-contrib/cors
    go get -u github.com/tealeg/xlsx
    go get -u github.com/google/uuid
    go get -u github.com/golang/snappy
    go get -u github.com/pkg/errors

ENV CI_BUILD_PYTHON python3

RUN git clone --branch=r2.0 --depth=1 https://github.com/tensorflow/tensorflow.git && \
    cd tensorflow && \
    tensorflow/tools/ci_build/builds/configured CPU \
    bazel build -c opt --copt=-march=native --cxxopt="-D_GLIBCXX_USE_CXX11_ABI=0" \
        #  --copt=-mavx --copt=-mavx2 --copt=-mfma --copt=-msse4.2 --copt=-avx --copt=-avx2
        # For optimized builds appropriate for the hardware platform of your choosing, uncomment below...
        # For ivy-bridge or sandy-bridge
        # --copt=-march="ivybridge" \
        # for haswell, broadwell, or skylake
        # --copt=-march="haswell" \
        tensorflow/tools/pip_package:build_pip_package && \
    bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/pip && \
    pip --no-cache-dir install --upgrade /tmp/pip/tensorflow-*.whl && \
    rm -rf /root/.cache && \
    rm -rf /tmp/pip && \
    rm -rf /tmp/tensorflow && \
    rm -rf /tmp/*
# Clean up pip wheel and Bazel cache when done.

# TensorBoard IPython
EXPOSE 6006 8888

WORKDIR /root
