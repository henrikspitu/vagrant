This doc will explain how to test and verify CNI works in the k3s cluster

contain different yaml files for testing

1) TEST DNS Service routing


# Define variables
POD_WORKER=$(
  kubectl -n cni-test get pods -l app=netshoot \
    -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.nodeName}{"\n"}{end}' \
  | awk '$2!="kmaster"{print $1; exit}'
)
POD_WORKER_IP=$(kubectl -n cni-test get pod "$POD_WORKER" -o jsonpath='{.status.podIP}')
WORKER_NODE=$(kubectl -n cni-test get pod "$POD_WORKER" -o jsonpath='{.spec.nodeName}')
WORKER_NODE_IP=$(kubectl get node "$WORKER_NODE" -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')
POD_MASTER=$(kubectl -n cni-test get pod -l app=netshoot --field-selector spec.nodeName=kmaster -o jsonpath='{.items[0].metadata.name}')

# Tests to run
kubectl -n cni-test exec -it $POD_WORKER -- nslookup whoami.cni-test.svc.cluster.local 10.43.0.10
kubectl -n cni-test exec -it $POD_WORKER -- curl -sS http://whoami.cni-test.svc.cluster.local
kubectl -n cni-test exec -it $POD_MASTER -- nslookup whoami.cni-test.svc.cluster.local 10.43.0.10
kubectl -n cni-test exec -it $POD_MASTER -- curl -sS http://whoami.cni-test.svc.cluster.local

echo "Check Connection FROM master to Worker"
kubectl -n cni-test exec -it $POD_MASTER -- ping -c 3 $POD_WORKER_IP

echo "check ingress is working"
curl -H "Host: whoami.local" http://$WORKER_NODE_IP/
