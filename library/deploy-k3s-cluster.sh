echo "================Download and install k3sup==================="
curl -sLS https://get.k3sup.dev | bash
sudo cp k3sup /usr/local/bin/k3sup
sudo install k3sup /usr/local/bin/k3sup

echo "================Check k3sup version=========================="
k3sup version

echo "================Local Install K3S through K3SUP==============="
k3sup install --local
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
sleep 20

echo "==================Check k3sup installation==================="
kubectl --kubeconfig kubeconfig get node -o wide

