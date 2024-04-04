# rasapi

Dockerfile for creating a Raspberry Pi-compatible image of the [Rasa](https://rasa.com) Conversational AI platform

## How to Use

This image is not intended to be used directly as it does not include any of the [spaCy](https://spacy.io/)
trained pipelines that you will probably need for your app. Instead, you should use
`markrendle/rasapi` as the base image and install the spaCy pipeline you need. For example,
to install a French pipeline:

```dockerfile
FROM markrendle/rasapi:3.5.10

RUN python -m spacy download fr_core_news_md
```

Build your own image from this file (this is quite quick and should run fine on a Pi):

```shell
docker build -t local/myrasapi .
```

You can then run Rasa in Docker, mounting your current directory with your YAML
files as a volume:

```shell
docker run -ti -v $(pwd):/app local/myrasapi train
docker run -ti -v $(pwd):/app local/myrasapi shell
```

## Overview

Rasa is an excellent platform for building generative conversation AI applications.
But it's quite a challenge to get it running on a Raspberry Pi: the public `rasa`
package on PyPI has dependencies on other packages, particularly Tensorflow ones,
which don't support ARM architectures.

We found an excellent guide on
[how to run Rasa 3.5.10 on the Raspberry Pi 4](https://forum.rasa.com/t/how-to-run-rasa-3-5-10-on-the-raspberry-pi-4/58502)
which works, but running all the steps on the Pi itself is incredibly slow. It involves downloading
and using Bazel to build a couple of Tensorflow packages from source, plus the
`pip install rasa` command runs a whole load of compiler bits, so it's not going to be super-quick, right?

We thought we might try the official [rasa/rasa](https://hub.docker.com/r/rasa/rasa) Docker image,
which is a multi-arch image that includes `linux/arm64` but it didn't actually work when we tried it
(`exec format error`).

So all this repo is, is the steps from the guide above put into a Dockerfile, which we can run
on a big beefy Windows PC using Docker Desktop and `buildx`:

```shell
docker buildx build --platform linux/arm64 -t local/rasa .
```

Then we push the image to a registry and pull it onto the Pi (hurrah for Docker's resumeable downloads).

This builds the image much faster than doing it natively on the Pi, and after a bit of
trial and error it seems to work fine on our Pi 5 8GB, so we thought we'd share it.

## Message To People In The Future

If you're looking at this repo and nothing's been updated in five years, that's because
this was a side project kind of thing and we only needed it for one thing. Feel free to fork
or just copy the Dockerfile and start your own repo. If you upgrade to a later version of
Rasa you'll probably need to change the versions of the Tensorflow packages that are built
in the image too.

## Contributors

- Willow Rendle
- Mark Rendle
- Nicholas Hacault (for the original How To post)
