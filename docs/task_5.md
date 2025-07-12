## Flask app install with helm

### Requirements
- helm is installed
- minikube is up and running

### Install

Сheckout repo 

Open console and navigate to the repo folder

install helm chart

```
helm install flask-hello ./flask_app_helm --namespace flask-hello --create-namespace --values ./flask_app_helm/values.yaml
```

Wait for deployment to finish, verify that the pod is up and running with

```
kubectl get all -n flask-hello
```

Should list flask-hello pod and other resources in the namespace

Get minikube ip

```
minikube ip
```

Get service port (left value in the PORTS column )

```
kubectl get service flask-hello -n flask-hello
```

Using this information open your browser, navigate to `http://<minikube-ip>:<nodeport>` and verify that our web application is available

You should be able to see "Hello World!" text from the flask web app.

## Cleanup

uninstall helm chart

```
helm delete flask-hello --namespace flask-hello
```