 sudo helm repo add mongodb https://mongodb.github.io/helm-charts
 sudo helm install enterprise-operator mongodb/enterprise-operator --namespace mongodb --create-namespace