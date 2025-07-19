Write-Host "======> Welcome to the Jenkins Minikube install script" -BackgroundColor Black -ForegroundColor White

Write-Host "======> Adding Jenkins Helm repo"
helm repo add jenkinsci https://charts.jenkins.io
helm repo update

Write-Host "======> Creating Jenkins namespace"
kubectl create namespace jenkins

Write-Host "======> Applying Jenkins volume manifest"
kubectl apply -f .\jenkins\jenkins-01-volume.yaml

Write-Host "======> Set permissions for Jenkins volume in Minikube"
minikube ssh "sudo mkdir -p /data/jenkins-volume && sudo chown -R 1000:1000 /data/jenkins-volume"

Write-Host "======> Applying Jenkins service account manifest"
kubectl apply -f .\jenkins\jenkins-02-sa.yaml

Write-Host "======> Creating secrets for Jenkins"
kubectl create secret generic jenkins-credentials-env --from-env-file=.env -n jenkins

Write-Host "======> Installing Jenkins with custom values"
helm install jenkins -n jenkins -f .\jenkins\jenkins-values.yaml jenkinsci/jenkins

Write-Host "======> Waiting for Jenkins pod to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=jenkins-controller -n jenkins --timeout=300s

Write-Host "======> Getting Jenkins admin password"
$jsonpath="{.data.jenkins-admin-password}"
$secret=$(kubectl get secret -n jenkins jenkins -o jsonpath=$jsonpath)
$bytes = [System.Convert]::FromBase64String($secret)
$adminPassword = [System.Text.Encoding]::UTF8.GetString($bytes)
Write-Host "`nJenkins admin password:`n$adminPassword`n" -ForegroundColor Cyan -BackgroundColor Black

Write-Host "======> Getting Jenkins URL"
$jsonpath="{.spec.ports[0].nodePort}"
$NODE_PORT=$(kubectl get -n jenkins -o jsonpath=$jsonpath services jenkins)
$jsonpath="{.items[0].status.addresses[0].address}"
$NODE_IP=$(kubectl get nodes -n jenkins -o jsonpath=$jsonpath)

Write-Host "Log into Jenkins using the following URL and credentials:"
Write-Host "http://$NODE_IP`:$NODE_PORT/login" -ForegroundColor Green -BackgroundColor Black
Write-Host "username: admin"
Write-Host "password: $adminPassword"