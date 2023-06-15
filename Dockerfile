FROM python:3.11.4-alpine3.18 as builder
ARG KUBERNETES_VERSION=v1.25.10
ARG VERSION=master
RUN apk add --no-cache curl make && \
    curl -LO https://storage.googleapis.com/kubernetes-release/release/${KUBERNETES_VERSION}/bin/linux/amd64/kubectl && \
    chmod +x kubectl

COPY . .
RUN make dist version=${VERSION}

FROM python:3.11.4-alpine3.18

COPY --from=builder /kubectl /usr/local/bin/
COPY --from=builder /dist/*.whl /tmp

RUN apk add --no-cache bash gcc musl-dev
RUN pip3 install --no-cache-dir \
        awscli \
        /tmp/*.whl && \
        rm -rf /tmp/* && \
  AWS_DEFAULT_REGION=eu-central-1 eks_rolling_update.py -h

WORKDIR /app
ENTRYPOINT ["eks_rolling_update.py"]
