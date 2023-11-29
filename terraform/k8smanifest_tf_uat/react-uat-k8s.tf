resource "kubectl_manifest" "deployment_react" {
  yaml_body = <<-YAML
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: emp-react
      namespace: frontend
    spec:
      selector:
        matchLabels:
          app.kubernetes.io/name: emp-react
      replicas: 3
      template:
        metadata:
          labels:
            app.kubernetes.io/name: emp-react
        spec:
          containers:
          - name: emp-react
            imagePullPolicy: Always
            image: 656600766668.dkr.ecr.ap-south-1.amazonaws.com/emp-react-ecr:d15ae5320230522093212
            ports:
            - containerPort: 88
            resources:
              limits:
                cpu: 750m
                memory: 750Mi
              requests:
                cpu: 500m
                memory: 500Mi


  YAML
}


resource "kubectl_manifest" "service_react" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Service
    metadata:
      name: emp-react
      namespace: frontend
    spec:
      ports:
      - port: 80
        protocol: TCP
        targetPort: 88
      type: ClusterIP
      selector:
        app.kubernetes.io/name: emp-react

  YAML


}

resource "kubectl_manifest" "pdb_react" {
  yaml_body = <<-YAML
    apiVersion: policy/v1
    kind: PodDisruptionBudget
    metadata:
      name: emp-react
      namespace: frontend
    spec:
      maxUnavailable: 1
      selector:
        matchLabels:
          app.kubernetes.io/name: emp-react
  YAML

}