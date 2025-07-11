## summary

In this we practice installing software on our kubernetes cluster with helm. This section will be run on a locally hosted minikube cluster.

## minikube cluster setup

Go to https://minikube.sigs.k8s.io/docs/start/, specify the parameters like OS and arch and get install command

for me it was
```powershell
New-Item -Path 'c:\' -Name 'minikube' -ItemType Directory -Force
$ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -OutFile 'c:\minikube\minikube.exe' -Uri 'https://github.com/kubernetes/minikube/releases/latest/download/minikube-windows-amd64.exe' -UseBasicParsing

$oldPath = [Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::Machine)
if ($oldPath.Split(';') -inotcontains 'C:\minikube'){
  [Environment]::SetEnvironmentVariable('Path', $('{0};C:\minikube' -f $oldPath), [EnvironmentVariableTarget]::Machine)
}
```

Start cluster (this will automatically download everything necessary and create Hyper-V vm that would host the cluster)
```powershell
minikube start
```

install helm

```powershell
winget install Helm.Helm
```

check that helm was installed succesfully

```powershell
helm version
```

ouptut should print helm verison and 

add bitnami repository and update the repo
```
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

install nginx

```powershell
helm install my-nginx bitnami/nginx --version 21.0.1
```

check that the pod exists

```powershell
kubectl get pods
```

temporary forward port from the pod to the host machine

```powershell
kubectl port-forward svc/my-nginx 8087:80
```

Open http://localhost:8087 in your browser, it should display default nginx page. This confirms our nginx app was deployed succesfully

uninstall the nginx release

```powershell
helm uninstall my-nginx
```

and check that the pod is gone

```powershell
kubectl get pods
```


## Install Jenkins

add repo

```powershell
helm repo add jenkinsci https://charts.jenkins.io
helm repo update
```

Create a Namespace for Jenkins
```
kubectl create namespace jenkins
```


```
kubectl apply -f .\jenkins\jenkins-01-volume.yaml
```

set permissions
```
minikube ssh
sudo mkdir -p /data/jenkins-volume
sudo chown -R 1000:1000 /data/jenkins-volume
```

create service role

```
kubectl apply -f .\jenkins\jenkins-02-sa.yaml
```

install jenkins using pre-defined values file

```
helm install jenkins -n jenkins -f .\jenkins\jenkins-values.yaml jenkinsci/jenkins
```

wait for pods to initialize (ready 2/2) and get admin password by running this command

```powershell
$jsonpath="{.data.jenkins-admin-password}"
$secret=$(kubectl get secret -n jenkins jenkins -o jsonpath=$jsonpath)
$bytes = [System.Convert]::FromBase64String($secret)
Write-Output ([System.Text.Encoding]::UTF8.GetString($bytes))

```

Get URL and log in with the password from previous command output

```powershell
$jsonpath="{.spec.ports[0].nodePort}"
$NODE_PORT=$(kubectl get -n jenkins -o jsonpath=$jsonpath services jenkins)
$jsonpath="{.items[0].status.addresses[0].address}"
$NODE_IP=$(kubectl get nodes -n jenkins -o jsonpath=$jsonpath)
Write-Host "http://$NODE_IP`:$NODE_PORT/login"

```

Log in and run the "HelloWorld" freestyle project, it should complete succesfully

This complete the task