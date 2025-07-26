# Task 7: Prometheus Deployment on K8s

In this task, we deploy a monitoring and alerting stack for our Minikube cluster via an automated Jenkins pipeline. Then, we will create alerts that would trigger email notifications.


### Requirements

- Minikube cluster with 8GB of RAM and 4 CPUs
- Jenkins deployment is up and running (see task 6)


### Reinstall Minikube Cluster

To accommodate the workloads in this task, we need to recreate the cluster with more available resources:

```
minikube stop
minikube delete
minikube config set cpus 4
minikube config set memory 8192
minikube config set disk-size 30g
minikube start
```

verify with
```
minikube config view
```

Prometheus helm charts requires additional permissions, so we would need to reinstall jenkins:

```
.\jenkins\install-jenkins.ps1
```

### Add Jenkins credentials

- Log into Jenkins
- Go to "Jenkins Dashboard" > "Manage Jenkins" > "Credentials" > "System" > "Global credentials (unrestricted)" >  "Add Credentials":

```
- Kind: Secret text
- Scope: Global
- Secret: [paste desired Grafana admin password]
- ID: grafana-admin-password
- Description: Grafana admin password
```

Click create

Repeat for smtp settings

```
- Kind: Username with password
- Scope: Global
- Username: [username, i.e. alerts@weyland-yutani.com]
- Passowrd: [password]
- ID: grafana-smtp
- Description: local smtp credentials
```

Enable option `Treat username as secret`

Click create


### Deploy monitoring stack

Monitoring stack is deployed fully from code

- Open Jenkins Dashboard > "Deploy monitoring stack" > "Build with Parameters" > Build
- When pipeline completes, run the below command to get Prometheus web console URL:
    ```
    kubectl port-forward svc/prometheus-stack-kube-prom-prometheus 9090 -n monitoring
    ```
Check prometheus web interface at http://127.0.0.1:9090/
You should be able to see Prometheus web interface

Get Grafana URL

```
minikube service grafana -n monitoring --url
```
login with username admin and password you set in jenkins credential

Open mailhog web interface to see email notifications triggered in the following steps

```
minikube service mailhog -n monitoring --url
```

Open Grafana and log in with admin and password that you configured in Jenkins credential

- Go to "Explore" and see if any metrics are available, for example `node_memory_MemAvailable_bytes:sum` 

### Configure Contact point (Manual)

Open separate console window and create a port-forwarding connection to mailhog pod

```
kubectl port-forward svc/mailhog 8025:8025 -n monitoring
```

Open http://localhost:8085 in the browser

Go to Grafana > Alerting > Contact Points > Create contact point

- Name: `DevOps contact point`
- Integration: `Email`
- Addresses: `devops@weyland-yutani.local`

Click Test > Send test notification, you should see "Test succesful" and mailhog browser notification
Click "Save contact point"

### Configure Alerts (Manual)

Go to Grafana > Dashboards > Kubernetes cluster monitoring (via Prometheus)

Create high CPU alert.
Click top right corner for "Cluster CPU usage (1m avg)" gauge > More > New alert rule

- Name: `High Cluster CPU usage (1m avg)`
- Condition" `WHEN Query A IS ABOVE 60`

- Evaluation group and interval > New evaluation group:
  - Evaluation group name: `10s eval`
  - Evaluation interval: `10s`
  - Click create
- Pending period: `10s`
- Keep firing: `10s`
- Contact point: `DevOps contact point`
- Click save

Cluster memory usage

Lack of RAM capacity on any node of the cluster

- Name: `Low available cluster memory`
- Condition" `WHEN Query A IS ABOVE 60`
- Evaluation group and interval: `10s eval`
- Pending period: `10s`
- Keep firing: `10s`
- Contact point: `DevOps contact point`
- Click save

Start temporary pod that will stress both CPU and RAM

```
kubectl run stress-ram --image=polinux/stress --rm -i --restart=Never -- stress --vm 4 --vm-bytes 1G --timeout 120s

```

Verify that alerts succesfully firing and deliver e-mails to contact point

On this, task is finished.