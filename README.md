##Errata


* src/test/java Package structure does not fit folder structure
* File `ci-ci-pipeline/tekton-triggers/webhook-event-listener-kubernetes.yaml`: Field `spec/serviceType` must be set to `NodePort`. 
* markdown link errors in README.md

## Cloud native CI/CD Pipeline on Kubernetes 1.17

The Tekton Pipelines project provides k8s-style resources for declaring CI/CD-style pipelines.

More information can be found here : https://github.com/tektoncd/pipeline 

## Prerequisites for creating the Tekton CI/CD pipeline

1. Clone git project
```
git clone https://github.com/vladsancira/openliberty-tekton.git
cd openliberty-tekton
```

2. Install Tekton pipelines in default `tekton-pipelines` namespace :

```
kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
kubectl get pods --namespace tekton-pipelines
```

3. Create new `env-stage`,`env-dev` and `env-ci` namespaces. In `env-ci` we will store the CI/CD pipeline and all pipeline resources. In `env-dev` and `env-stage` namespaces, we will deploy the application via image promotion.
```
kubectl create namespace env-stage
kubectl create namespace env-dev
kubectl create namespace env-ci
```

4. Create <API_KEY> for IBM Cloud Registry and export PullImage secret from `default` namespace. The <API_KEY> is used for pushing images into IBM Cloud Registry. When creating a K8s cluster, am IBM Cloud Registry pull secrect will be created in `default` namespace (for all regions ) that is used for pulling images from IBM Cloud Registry.

```
ibmcloud iam api-key-create MyKey -d "this is my API key" --file key_file.json
cat key_file.json | grep apikey

kubectl create secret generic ibm-cr-secret  -n env-ci --type="kubernetes.io/basic-auth" --from-literal=username=iamapikey --from-literal=password=<API_KEY>
kubectl annotate secret ibm-cr-secret  -n env-ci tekton.dev/docker-0=us.icr.io

kubectl get secret default-us-icr-io --export -o yaml > default-us-icr-io.yaml
kubectl create -f  default-us-icr-io.yaml -n env-dev
kubectl create -f  default-us-icr-io.yaml -n env-stage
```

5. Create a new ServiceAccount to allow the Pipeline to run and deploy to `env-dev` namespace. We specify this ServiceAccount in pipeline definition. Also we will bind a custom Role to this ServiceAccount that will enable it to create/delete/edit/.. resources in `env-dev` and `env-stage` namespaces.

```
kubectl apply -f ci-cd-pipeline/tekton-kubernetes/service-account.yaml         -n env-ci
kubectl apply -f ci-cd-pipeline/tekton-kubernetes/service-account-binding.yaml -n env-dev
kubectl apply -f ci-cd-pipeline/tekton-kubernetes/service-account-binding.yaml -n env-stage
```

---
### Below is an image of the Kubernetes Pipeline design.

![Pipeline Design](images/pipeline-design-tekton-simple.jpg?raw=true "Pipeline Design")

---
## Create the Tekton CI/CD pipeline


1. Create Tekton resources , taks and pipeline:

```
kubectl create -f ci-cd-pipeline/tekton-kubernetes/resources.yaml          -n env-ci
kubectl create -f ci-cd-pipeline/tekton-kubernetes/task-build.yaml         -n env-ci
kubectl create -f ci-cd-pipeline/tekton-kubernetes/task-deploy.yaml        -n env-ci
kubectl create -f ci-cd-pipeline/tekton-kubernetes/task-test.yaml          -n env-ci
kubectl create -f ci-cd-pipeline/tekton-kubernetes/task-promote.yaml       -n env-ci
kubectl create -f ci-cd-pipeline/tekton-kubernetes/pipeline.yaml           -n env-ci
```

2. Execute Pipeline via Pipeline Run and watch :

```
kubectl create -f ci-cd-pipeline/tekton-kubernetes/pipeline-run.yaml -n env-ci
kubectl get pipelinerun -n env-ci -w
```

3. Check Pods and logs :

```
kubectl get pods                             -n env-dev
kubectl logs liberty-app-76fcdc6759-pjxs7 -f -n env-dev
```
Optional : create Horizontal Pod Autoscaler :

```
kubectl autoscale deploy liberty-app  --min=1 --max=2 --cpu-percent=90 -n env-dev
kubectl autoscale deploy liberty-app  --min=1 --max=2 --cpu-percent=90 -n env-stage
```


4. View the OpenLiberty application health status:

Retrieve the Kubernetes cluster `EXTERNAL-IP` using following command:

```
kubectl get nodes -o wide
```

Then open following URL in a Browser to view the OpenLiberty application UI :
- from `DEV` environment:  `http://<EXTERNAL-IP>:32427/health`
- from `STAGE` environment:  `http://<EXTERNAL-IP>:32527/health`

---


## Create a WebHook connection from a Git repo

In order to create a WebHook from Git to our Tekton Pipeline we need to install [TektonCD Triggers](https://github.com/tektoncd/triggers) in our K8s cluster. 
Triggers is a Kubernetes Custom Resource Defintion (CRD) controller that allows you to extract information from events payloads (a "trigger") to create Kubernetes resources.
More information can be found in the  [TektonCD Triggers Project](https://github.com/tektoncd/triggers). Also we can use Tekton Dashboard as a web console for viewing all Tekton Resources. 

On OpenShift 4.3 , [TektonCD Triggers](https://github.com/tektoncd/triggers) are already installed as part of the [OpenShift Pipelines Operator](https://www.openshift.com/learn/topics/pipelines),  in `openshift-pipelines` project (namespace), but Tekton Dashboard is not installed. Instead,  we can use the OpenShift Pipeline Web Console.

The mechanism for triggering builds via WebHooks is the same and involves creating an EventListener and exposing that EventListener Service to outside. The EventListener handles external events and recieves a Git payload. This payload is parsed via the TriggerBinding resource for certain information, like `gitrevision` or `gitrepositoryurl`. These variables are then sent to TriggerTemplate resource that will call the Tekton Pipeline via a PipelineRun definition (with optional arguments).

![Tekton Architecture](./images/webhook-architecture-tekton-simple.jpg?raw=true "Tekton Architecture")


### For OpenShift: 

1. Create Pipeline's trigger_template, trigger_binding & event_listener

```
oc create -f ci-cd-pipeline/tekton-triggers/webhook-event-listener-openshift.yaml -n env-ci 
```
2. Create a Route for the event_listener service
```
oc expose svc/el-liberty-pipeline-listener -n env-ci
oc get route -n env-ci
```
3.  Add this route to out Git WebHook then perfom a push.

Finally, the new `PipelineRun` will be triggered automatically and visible in the pipelines console `ci-env` project.


### For Kubernetes:

1. Install Tekton Dashboard and Tekton Triggers

```
kubectl apply -f https://github.com/tektoncd/dashboard/releases/download/v0.6.1.2/tekton-dashboard-release.yaml
kubectl apply -f https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml
kubectl apply -f ci-cd-pipeline/tekton-triggers/tekton-dashboard.yaml -n tekton-pipelines
```

2. Create a new ServiceAccount, Role and RoleBinding. In K8s this new ServiceAccount will be used for running the EventListener and starting the PipelineRun via the TriggerTemplate. The actual Pipeline will still run as the ServiceAccount defined in it.

```
kubectl apply  -f ci-cd-pipeline/tekton-triggers/webhook-service-account.yaml  -n env-ci
```

3. Create Pipeline's trigger_template, trigger_binding & event_listener<br>
( by default Event Listener service type is ClusterIP , but we set it to NodePort so it can be triggered from outside cluster )


```
kubectl apply -f ci-cd-pipeline/tekton-triggers/webhook-event-listener-kubernetes.yaml -n env-ci 
```

4. Get `el-liberty-pipeline-listener` Service  PORT and cluster `EXTERNAL-IP`

```
kubectl get svc el-liberty-pipeline-listener -n env-ci
kubectl get nodes -o wide 
```

5. Add 'http://<EXTERNAL-IP>>:<EVENT_LISTNER_PORT>' to GitHib as WebHook. Then perform a push.

![Webhook](./images/webhook-tekton.jpg?raw=true "Webhook") 


6. Open the Tekton dashboard, `http://<EXTERNAL-IP>:32428/#/pipelineruns`, to make sure your changes were successful. Your output should look like the following:

![Webhook](./images/dashboard.jpg?raw=true "Webhook") 


---
## Configure cleanup CronJob 

You can create a K8s CronJob for deleting the PipelineRun resources that meet a specific criteria:

```
kubectl config set-context --current --namespace=env-ci
kubectl apply -f ci-cd-pipeline/tekton-cleanup/pipelinerun_cleanup_cronjob.yaml
```

Now every day, the `pipelinerun-cleanup` cronjob will perform a PipelineRun cleanup. 

---
## LogDNA configuration 

From IBM Cloud - Observability - Logging you can create a LogDNA Lite instance:

![LogDNA](./images/logdna.png?raw=true "LogDNA") 

LogDNA configuration for K8s and OpenShift is very simple: from "Edit log sources" run the two kubectl commands for setting up the LogDNA Agent Key and create the LogDNA agent in your K8s/OpenShift cluster. You can create the resources in any namspace:   

```
kubectl create secret generic logdna-agent-key --from-literal=logdna-agent-key=<SECRET_KEY>
kubectl create -f https://assets.eu-gb.logging.cloud.ibm.com/clients/logdna-agent-ds.yaml
```

All K8s/OpenShift logs are then visible in LogDNA Dashboard.

---

# Summary 

In this tutorial , we created a Cloud-native CI/CD Tekton Pipeline for building and deploying an OpenLiberty application in an OpenShift 4.3 / Kubernetes 1.16+ cluster.
