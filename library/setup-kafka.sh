#!/bin/bash

# Remove any existing Kafka network
docker network rm kafka-network || true

# Create a new Kafka network
docker network create kafka-network

# Start Zookeeper
# docker run -d --name zookeeper --network kafka-network -p 2181:2181 zookeeper:3.8.0
docker run -d --name zookeeper --network kafka-network -p 2181:2181 zookeeper:latest


# Start Kafka
docker run -d --name kafka --network kafka-network -p 9092:9092 \
    -e KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181 \
    -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://172.17.67.153:9092 \
    -e KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=PLAINTEXT:PLAINTEXT \
    -e KAFKA_LISTENERS=PLAINTEXT://0.0.0.0:9092 \
    -e KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1 \
    -e KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR=1 \
    -e KAFKA_TRANSACTION_STATE_LOG_MIN_ISR=1 \
    confluentinc/cp-kafka:latest

# Wait for Kafka to start
sleep 60

# Print debug logs
docker logs kafka 
docker logs zookeeper

# Check if Kafka container is running
docker ps | grep kafka || exit 1

echo "this is the IP"
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' kafka

KAFKA_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' kafka)
echo $KAFKA_IP

VALUES_YAML="helm/gl-gateway-download-manager/values.yaml"
PYTHON_SCRIPT=".github/ci-artifacts/produce_message_to_kafka_topic.py"

sed -i.bak "s|brokerURL: \"\"|brokerURL: \"${KAFKA_IP}:9092\"|" "$VALUES_YAML"

sed -i.bak "s|DOCKER_KAFKA_IP:9092|${KAFKA_IP}:9092|" "$PYTHON_SCRIPT"

echo "printing values.yaml"
cat $VALUES_YAML

echo "printing python script"
cat $PYTHON_SCRIPT


# Create Kafka inbound topic
docker exec kafka kafka-topics --create --topic pce.coreservices.dm.in --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1
docker exec kafka kafka-topics --create --topic pce.gateway.pcm --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1

# List Kafka topics
docker exec kafka kafka-topics --list --bootstrap-server localhost:9092
