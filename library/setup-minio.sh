# Install MinIO client
wget --no-check-certificate https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x mc
sudo mv mc /usr/local/bin/mc

# Start MinIO server in Docker
# docker run -d -p 9000:9000 --name minio \
#     -e "MINIO_ACCESS_KEY=admin" \
#     -e "MINIO_SECRET_KEY=minio1234" \
#     -v /tmp/minio/data:/data \
#     minio/minio server /data

# Start MinIO server in Docker with https
# docker run -d -p 443:443 --name minio \
#     -e "MINIO_ROOT_USER=admin" \
#     -e "MINIO_ROOT_PASSWORD=minio1234" \
#     -e "MINIO_CERT_FILE=/home/avijit/actions-runner/cert.pem" \
#     -e "MINIO_KEY_FILE=/home/avijit/actions-runner/key.pem" \
#     -v /path/to/data:/data \
#     minio/minio server /data --console-address ":443"


# docker run -d -p 9000:9000 -p 9001:9001 --name minio \
#     -e "MINIO_ROOT_USER=admin" \
#     -e "MINIO_ROOT_PASSWORD=minio1234" \
#     -e "MINIO_CERT_FILE=/home/avijit/actions-runner/cert.pem" \
#     -e "MINIO_KEY_FILE=/home/avijit/actions-runner/key.pem" \
#     -v /path/to/data:/data \
#     -v /home/avijit/actions-runner/cert.pem:/root/.minio/certs/public.crt:ro \
#     -v /home/avijit/actions-runner/key.pem:/root/.minio/certs/private.key:ro \
#     minio/minio server /data --console-address ":9001"


docker run -d -p 9000:9000 -p 9001:9001 --name minio \
    -e "MINIO_ROOT_USER=admin" \
    -e "MINIO_ROOT_PASSWORD=minio1234" \
    -e "MINIO_CERT_FILE=/home/gladmin/actions-runner/cert.pem" \
    -e "MINIO_KEY_FILE=/home/gladmin/actions-runner/key.pem" \
    -v /path/to/data:/data \
    -v /home/gladmin/actions-runner/cert.pem:/root/.minio/certs/public.crt:ro \
    -v /home/gladmin/actions-runner/key.pem:/root/.minio/certs/private.key:ro \
    minio/minio server /data --console-address ":9001"    

sleep 20

# Fetch MinIO container's IP address
MINIO_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' minio)
echo $MINIO_IP
# Set up MinIO alias with dynamic IP
# mc alias set myminio http://$MINIO_IP:9000 admin minio1234 
mc alias set myminio https://$MINIO_IP:9000 admin minio1234 --insecure
# mc alias set myminio http://$MINIO_IP:443 admin minio1234

# Create bucket and subdirectories
mc mb -p myminio/pce-core-services/0.0.1/artifacts/charts --insecure
mc mb -p myminio/pce-core-services/0.0.1/artifacts/misc --insecure
mc mb -p myminio/pce-core-services/0.0.1/images --insecure

# Navigate to artifact directory
cd .github/ci-artifacts/

# helm charts artifacts
wget --no-check-certificate https://charts.bitnami.com/bitnami/nginx-13.1.2.tgz -O nginx-13.1.2.tgz
wget --no-check-certificate https://charts.bitnami.com/bitnami/postgresql-10.3.15.tgz -O postgresql-10.3.15.tgz
wget --no-check-certificate https://charts.bitnami.com/bitnami/apache-8.5.0.tgz -O apache-8.5.0.tgz

# docker images artifacts
wget --no-check-certificate https://docker.io/library/nginx:latest -O nginx-latest.tar
sleep 50
wget --no-check-certificate https://docker.io/library/mysql:latest -O mysql-latest.tar
sleep 50
wget --no-check-certificate https://docker.io/library/redis:latest -O redis-latest.tar
sleep 50

# misc binary artifacts
wget --no-check-certificate  https://jsonplaceholder.typicode.com/posts/1 -O sample.json
wget --no-check-certificate  https://people.sc.fsu.edu/~jburkardt/data/csv/addresses.csv -O addresses.csv

# Compress misc files
tar -czvf misc1.tar.gz sample.json
tar -czvf misc2.tar.gz addresses.csv

# Check if the artifact exists and upload to MinIO
for file in *.tar *.tar.gz *.tgz; do
    if [ ! -f "$file" ]; then
        echo "ERROR: $file does not exist."
        exit 1
    fi

    echo "Uploading $file to MinIO..."
    if [[ "$file" == *.tgz ]]; then
        mc cp  --insecure "$file" myminio/pce-core-services/0.0.1/artifacts/charts/ || exit 1
    elif [[ "$file" == *.tar ]]; then
        mc cp --insecure "$file" myminio/pce-core-services/0.0.1/images/ || exit 1
    elif [[ "$file" == *.tar.gz ]]; then
        mc cp --insecure "$file" myminio/pce-core-services/0.0.1/artifacts/misc/ || exit 1
    fi
done

# Verify uploaded artifacts
echo "Verification will start..."
expected_charts="nginx-13.1.2.tgz postgresql-10.3.15.tgz apache-8.5.0.tgz"
expected_misc="misc1.tgz misc2.tgz"
expected_images="nginx-latest.tar mysql-latest.tar redis-latest.tar"

# Verify charts
for chart in $expected_charts; do
    if ! mc ls --insecure myminio/pce-core-services/0.0.1/artifacts/charts/$chart; then
        echo "ERROR: $chart is missing from MinIO charts folder"
        exit 1
    fi
done

# Verify misc
for misc in $expected_misc; do
    if ! mc ls --insecure myminio/pce-core-services/0.0.1/artifacts/misc/$misc; then
        echo "ERROR: $misc is missing from MinIO misc folder"
        exit 1
    fi
done

# Verify images
for image in $expected_images; do
    if ! mc ls --insecure myminio/pce-core-services/0.0.1/images/$image; then
        echo "ERROR: $image is missing from MinIO images folder"
        exit 1
    fi
done

echo "All artifacts uploaded to MinIO and verified successfully."

mc alias set myminio http://localhost:9000 admin minio1234 --insecure
echo "These are for the charts"
mc ls --insecure myminio/pce-core-services/0.0.1/artifacts/charts
echo "These are for the misc"
mc ls --insecure myminio/pce-core-services/0.0.1/artifacts/misc
echo "These are for the images"
mc ls --insecure myminio/pce-core-services/0.0.1/images

# Clean up
# mc alias remove myminio
# docker stop minio
# docker rm minio
