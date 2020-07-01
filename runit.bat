kubectl delete namespace env-ci
kubectl create namespace env-ci
kubectl delete namespace env-dev
kubectl create namespace env-dev

kubectl create secret generic ibm-cr-secret --type="kubernetes.io/basic-auth" --from-literal=username=iamapikey --from-literal=password=7i47fQSxtbnng0_PijpwcFIXT4rDhPTDWQ_AKHer8OYp  -n env-ci
kubectl annotate secret ibm-cr-secret   tekton.dev/docker-0=us.icr.io -n env-ci
kubectl get secret default-us-icr-io --export -o yaml > default-us-icr-io.yaml
kubectl create -f  default-us-icr-io.yaml -n env-dev
kubectl apply -f ci-cd-pipeline/tekton-kubernetes/service-account.yaml         -n env-ci
kubectl apply -f ci-cd-pipeline/tekton-kubernetes/service-account-binding.yaml -n env-dev

