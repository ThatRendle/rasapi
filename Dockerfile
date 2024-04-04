FROM --platform=arm64 python:3.10-slim AS builder

RUN apt update && \
    apt install -y --no-install-recommends \
    build-essential \
    git \
    curl \
    librdkafka-dev \
    wget

# Install Bazelisk for building tensorflow packages
WORKDIR /bazel
RUN wget https://github.com/bazelbuild/bazelisk/releases/download/v1.17.0/bazelisk-linux-arm64 && \
    chmod +x bazelisk-linux-arm64 && \
    mv bazelisk-linux-arm64 /usr/local/bin/bazel
RUN bazel --version

RUN pip install tensorflow==2.11.0

# Build tensorflow-addons to /artifacts directory
WORKDIR /tensorflow
RUN git clone https://github.com/tensorflow/addons.git
WORKDIR /tensorflow/addons
RUN git checkout r0.19
RUN python ./configure.py
RUN bazel build --enable_runfiles build_pip_pkg
RUN apt install -y rsync
RUN bazel-bin/build_pip_pkg /artifacts

# Build tensorflow-text to /artifacts directory
WORKDIR /tensorflow
RUN git clone https://github.com/tensorflow/text.git
WORKDIR /tensorflow/text
RUN git checkout 2.11
RUN /bin/bash -c "source oss_scripts/configure.sh && bazel build --enable_runfiles oss_scripts/pip_package/build_pip_package && ./bazel-bin/oss_scripts/pip_package/build_pip_package /artifacts"

# Runtime image
FROM --platform=arm64 python:3.10-slim

RUN apt update && \
    apt install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    librdkafka-dev \
    openssl \
    graphviz-dev \
    pkg-config \
    libssl-dev \
    libffi-dev \
    libpng-dev

# Get the tensorflow packages from the builder image
COPY --from=builder /artifacts/*.whl /artifacts/

RUN pip install tensorflow==2.11.0
RUN pip install /artifacts/tensorflow_addons-*.whl
RUN pip install /artifacts/tensorflow_text-*.whl
RUN pip install 'rasa==3.5.10'
RUN pip install spacy

# This is the directory you should mount onto
WORKDIR /app

# Use bash as default shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Expose rasa API port
EXPOSE 5005

# Set rasa as entrypoint and --help as default command
ENTRYPOINT [ "rasa" ]
CMD [ "--help" ]
