FROM buster AS base
MAINTAINER Carlos Nunez <dev@carlosnunez.me>
ENV AWS_LAMBDA_RIE_URL_ARM64=https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie-arm64
ENV AWS_LAMBDA_RIE_URL_AMD64=https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie

RUN apt -y update
RUN apt -y install zlib1g-dev liblzma-dev patch chromium chromium-driver

RUN if uname -m | grep -Eiq 'arm|aarch'; \
    then curl -Lo /usr/local/bin/aws_lambda_rie "$AWS_LAMBDA_RIE_URL_ARM64"; \
    else curl -Lo /usr/local/bin/aws_lambda_rie "$AWS_LAMBDA_RIE_URL_AMD64"; \
    fi && chmod +x /usr/local/bin/aws_lambda_rie

# Use whatever base image you want here!
FROM alpine AS app
COPY --from=base /usr/local/bin/aws_lambda_rie /usr/local/bin/aws_lambda_rie
COPY include/entrypoint.sh /entrypoint.sh

# Rest of your app goes here.

# Ensure that this is the last line of your Dockerfile!
ENTRYPOINT [ "/entrypoint.sh" ]
