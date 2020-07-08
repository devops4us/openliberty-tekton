kubectl apply -f https://github.com/tektoncd/dashboard/releases/download/v0.6.1.2/tekton-dashboard-release.yaml -n tekton-pipelines
kubectl apply -f https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml -n tekton-pipelines
kubectl apply -f ci-cd-pipeline/tekton-triggers/tekton-dashboard.yaml -n tekton-pipelines

kubectl apply  -f ci-cd-pipeline/tekton-triggers/webhook-service-account.yaml  -n env-ci
kubectl apply -f ci-cd-pipeline/tekton-triggers/webhook-event-listener-kubernetes.yaml -n env-ci 