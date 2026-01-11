Install Strimzi

NOTE: --set watchAnyNamespace=true will make strimzi look for resources in any namespace

kubectl create namespace kafka
helm install strimzi-cluster-operator oci://quay.io/strimzi-helm/strimzi-kafka-operator --namespace kafka --create-namespace --set watchAnyNamespace=true --version 0.49.1


Create Kafka cluster
kubectl apply custer.yaml  -n kafka
NOTE: cluster and operator NEED to be in different namespaces

IMPORTANT: Delete PVC's if a kafka cluster is deleted. 
However Strimzi can also delete PVC's: deleteClaim: true 


Start a kafka client

kubectl -n kafka run kafka-client -it --rm --restart=Never \
  --image=quay.io/strimzi/kafka:0.49.1-kafka-4.1.1 \
  -- bash


  Create topic

  bin/kafka-topics.sh --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --create --topic test --partitions 3 --replication-factor 3


  List topics

  bin/kafka-topics.sh --bootstrap-server my-cluster-kafka-bootstrap:9092 --list



  # Configure Ingress & External Traffic for cluster

## Expose a new TCP entryPoint on Traefik (k3s way: HelmChartConfig)

file: /var/lib/rancher/k3s/server/manifests/traefik-kafka-port.yaml

```yaml

apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: traefik
  namespace: kube-system
spec:
  valuesContent: |-
    ports:
      kafka:
        port: 9094
        expose:
          default: true
        exposedPort: 9094
        protocol: TCP


 ```

NOTE: if your DNS name like broker-0.kafkaingress.sharks4it.dk and sharks4it.dk already is a domain in use. (which it is). THen the server will route traffic to this.

That is why I on master node were I test from do this:

```bash
sudo tee -a /etc/hosts >/dev/null <<'EOF'
192.168.1.150  bootstrap.kafkaingress.sharks4it.dk
192.168.1.150  broker-0.kafkaingress.sharks4it.dk
192.168.1.150  broker-1.kafkaingress.sharks4it.dk
192.168.1.150  broker-2.kafkaingress.sharks4it.dk
EOF

```

Export Cert for REAL cert test

```bash

kubectl -n kafka-cluster-ingress get secret kafka-cluster01-cluster-ca-cert -o jsonpath='{.data.ca\.crt}' | base64 -d > cluster-ca.crt

```

Install the kcat-test.yaml this will configure a test pod, that can confirm if we can list brokers and topic info

```bash

kubectl -n kafka exec -it kcat-test -- \
  kcat -b bootstrap.kafkaingress.sharks4it.dk:9094 -L \
    -X security.protocol=SSL \
    -X ssl.ca.location=/ca/ca.crt

```

If this command return broker and topic info we have verified:

DNS/SNI routing works: you connected to bootstrap.kafkaingress.sharks4it.dk:9094 and got a valid TLS connection.

Traefik TCP IngressRouteTCP is routing correctly: the bootstrap service answered and returned metadata.

Strimzi advertised listeners are correct: brokers are advertised as the external names broker-0/1/2.kafkaingress.sharks4it.dk:9094 (this is the #1 thing that usually breaks).

KRaft controller present: broker 1 is shown as (controller)

Now The test is Ready to try and produce & consume messages

I created a Topic Using Topic Manager of Strimzi. So that is also tested.

I however have some SSL errores currently. To be continued

