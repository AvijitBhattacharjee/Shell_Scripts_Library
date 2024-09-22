import sys
import json
from kafka import KafkaProducer
import os

KAFKA_BROKER = os.getenv("KAFKA_BROKER", "DOCKER_KAFKA_IP:9092")
KAFKA_TOPIC_INBOUND = os.getenv("KAFKA_TOPIC_INBOUND", "pce.coreservices.dm.in")

# Message content
message = {
    "minio_bucket": "pce-core-services",
    "minio_base_path": "0.0.1",
    "update": "true",
    "charts": None,
    "nfs_folder": "CMVMaaS"
}

def send_message(topic, broker, message):
    # Create a Kafka producer
    producer = KafkaProducer(
        bootstrap_servers=[broker],
        value_serializer=lambda v: json.dumps(v).encode('utf-8')
    )
    
    # Send the message
    producer.send(topic, value=message)
    producer.flush()  # Ensure all messages are sent
    producer.close()  # Close the producer
    
    print(f"Message sent to topic {topic}: {message}")

if __name__ == "__main__":
    send_message(KAFKA_TOPIC_INBOUND, KAFKA_BROKER, message)
