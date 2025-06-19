FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Allow root user to run configure
ENV FORCE_UNSAFE_CONFIGURE=1

# Set working directory
WORKDIR /workspace

# Copy project-specific files into the container
COPY light_overlay/ ./light_overlay/
COPY create-buildroot-image.sh ./

# Install dependencies required for Buildroot builds and clone the repository
RUN apt-get update && apt-get install -y --no-install-recommends \
  build-essential \
  gcc \
  g++ \
  make \
  git \
  curl \
  wget \
  ca-certificates \
  bc \
  bison \
  flex \
  file \
  cpio \
  rsync \
  unzip \
  xz-utils \
  libncurses5-dev \
  libssl-dev \
  libelf-dev \
  liblz4-tool \
  libstdc++-11-dev \
  python3 \
  python3-pip \
  pkg-config \
  genext2fs \
  fakeroot \
  sudo \
  openssh-client \
  device-tree-compiler \
  mtools \
  dosfstools \
  udev \
  vim \
  net-tools \
  iputils-ping \
  less \
  tzdata \
  && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && git clone --branch 2025.02.1 --depth 1 https://github.com/buildroot/buildroot.git \
  && cp create-buildroot-image.sh /workspace/buildroot/ \
  && chmod +x  /workspace/buildroot/create-buildroot-image.sh


# Set final working directory
WORKDIR /workspace/buildroot

# Set the script to run by default when container starts
ENTRYPOINT ["./create-buildroot-image.sh"]
