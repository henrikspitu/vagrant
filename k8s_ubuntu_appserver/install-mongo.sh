 sudo helm repo add mongodb https://mongodb.github.io/helm-charts
 sudo helm install enterprise-operator mongodb/enterprise-operator --namespace mongodb --create-namespace
kubectl config set-context $(kubectl config current-context) --namespace mongodb

kubectl create secret generic opsadminuser --from-literal=Username="admin" --from-literal=Password="mongo01" --from-literal=FirstName="admin" --from-literal=LastName="admin" --namespace mongodb

#password for the Ops Manager database user
kubectl create secret generic omdbuser --from-literal=password="mongo01" --namespace mongodb




cat >>opsManager.yaml<<EOF
apiVersion: mongodb.com/v1
kind: MongoDBOpsManager
metadata:
  name: 01-mongodbopsmanager
spec:
  replicas: 1
  version: 6.0.0
  adminCredentials: opsadminuser # Should match metadata.name
                                           # in the secret
                                           # for the admin user
  externalConnectivity:
    type: LoadBalancer

  applicationDatabase:
    members: 3
    version: 5.0.14-ent
EOF


NOTE: for servers with chip set that does not support AVX the application server need to be version 


cat >>opsManager.yaml<<EOF
apiVersion: mongodb.com/v1
kind: MongoDBOpsManager
metadata:
  name: 01-mongodbopsmanager
spec:
  replicas: 1
  version: 6.0.0
  adminCredentials: opsadminuser # Should match metadata.name
                                           # in the secret
                                           # for the admin user
  externalConnectivity:
    type: LoadBalancer

  applicationDatabase:
    members: 3
    version: 4.4.0-ent
EOF

kubectl create -f  opsManager.yaml --namespace mongodb
