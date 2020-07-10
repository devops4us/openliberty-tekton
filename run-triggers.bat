@rem kubectl delete -f https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml
@rem kubectl apply -f https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml
@rem kubectl delete -f ci-cd-pipeline/tekton-triggers/tekton-dashboard.yaml -n tekton-pipelines
@rem kubectl apply -f ci-cd-pipeline/tekton-triggers/tekton-dashboard.yaml -n tekton-pipelines

kubectl delete  -f ci-cd-pipeline/tekton-triggers/webhook-service-account.yaml  -n env-ci
kubectl create  -f ci-cd-pipeline/tekton-triggers/webhook-service-account.yaml  -n env-ci
kubectl delete -f ci-cd-pipeline/tekton-triggers/webhook-event-listener-kubernetes.yaml -n env-ci 
kubectl create -f ci-cd-pipeline/tekton-triggers/webhook-event-listener-kubernetes.yaml -n env-ci     