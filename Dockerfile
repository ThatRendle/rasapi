FROM python:3.10-slim

RUN apt update && \
    apt install -y build-essential git curl librdkafka-dev wget

WORKDIR /bazel
RUN wget https://github.com/bazelbuild/bazelisk/releases/download/v1.17.0/bazelisk-linux-arm64 && \
    chmod +x bazelisk-linux-arm64 && \
    mv bazelisk-linux-arm64 /usr/local/bin/bazel
RUN bazel --version

RUN pip install tensorflow==2.11.0

WORKDIR /tensorflow
RUN git clone https://github.com/tensorflow/addons.git
WORKDIR /tensorflow/addons
RUN git checkout r0.19
RUN python ./configure.py
RUN bazel build --enable_runfiles build_pip_pkg
RUN apt install -y rsync
RUN bazel-bin/build_pip_pkg /artifacts

WORKDIR /tensorflow
RUN git clone https://github.com/tensorflow/text.git
WORKDIR /tensorflow/text
RUN git checkout 2.11
COPY mtr.sh .
RUN chmod +x mtr.sh
RUN ./mtr.sh

FROM python:3.10-slim

COPY --from=0 /artifacts/*.whl /artifacts/

RUN pip install tensorflow==2.11.0
RUN pip install /artifacts/tensorflow_addons-*.whl
RUN pip install /artifacts/tensorflow_text-*.whl

RUN apt update && \
    apt install -y --no-install-recommends build-essential \
    libpq-dev librdkafka-dev openssl graphviz-dev \
    pkg-config libssl-dev libffi-dev libpng-dev

RUN pip install 'rasa==3.5.10'
RUN pip install spacy

WORKDIR /app

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

EXPOSE 5005
ENTRYPOINT [ "rasa" ]
CMD [ "--help" ]

# RUN python -m spacy download fr_core_news_md
