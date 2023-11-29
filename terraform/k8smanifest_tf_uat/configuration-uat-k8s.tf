resource "kubectl_manifest" "deployment_configuration" {
  yaml_body = <<-YAML
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: emp-configuration-service
      namespace: backend
    spec:
      selector:
        matchLabels:
          app.kubernetes.io/name: emp-configuration-service
      replicas: 3
      template:
        metadata:
          labels:
            app.kubernetes.io/name: emp-configuration-service
        spec:
          containers:
          - name: emp-configuration-service
            imagePullPolicy: Always
            image: 656600766668.dkr.ecr.ap-south-1.amazonaws.com/emp-configuration-service:54779ff20230522085050
            ports:
            - containerPort: 8086
            resources:
              limits:
                cpu: 750m
                memory: 750Mi
              requests:
                cpu: 500m
                memory: 500Mi
            envFrom:
            - configMapRef:
                name: emp-configuration-service-cm
            - secretRef:
                name: emp-configuration-service-secret
            livenessProbe:
              httpGet:
                path: /emp-configuration-service/actuator
                port: 8086
              initialDelaySeconds: 90
              periodSeconds: 30
              timeoutSeconds: 30
  YAML
}


resource "kubectl_manifest" "service_configuration" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Service
    metadata:
      name: emp-configuration-service
      namespace: backend
      annotations:
        alb.ingress.kubernetes.io/healthcheck-port: '8086'
        alb.ingress.kubernetes.io/healthcheck-path: /emp-configuration-service/actuator
    spec:
      ports:
      - port: 80
        protocol: TCP
        targetPort: 8086
      type: ClusterIP
      selector:
        app.kubernetes.io/name: emp-configuration-service

  YAML
}

resource "kubectl_manifest" "config_configuration" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: emp-configuration-service-cm
      namespace: backend
    data:
        server.port: "8086"

        spring.application.name: emp-configuration-service
        spring.jpa.generate-ddl: "false"

        spring.datasource.url: jdbc:mysql://emp-uat-rds-mysql.chaqp2ysfjmh.ap-south-1.rds.amazonaws.com:3306/configuration?useSSL=false&createDatabaseIfNotExist=true
        spring.datasource.username: root

        spring.datasource.driver-class-name: com.mysql.jdbc.Driver
        #spring.jpa.hibernate.ddl-auto: validate

        opentracing.jaeger.http-sender.url: http://localhost:16686/api/traces

        spring.liquibase.change-log: classpath:db/changelog/db.changelog-master.xml
        kafkaconsumer.bootstrap: http://10.132.80.37:9092

  YAML
}

resource "kubectl_manifest" "secret_configuration" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Secret
    metadata:
      name: emp-configuration-service-secret
      namespace: backend
    data:
      spring.datasource.password: cGFzc3dvcmQjMTIzNA==
  YAML

}

resource "kubectl_manifest" "pdb_configuration" {
  yaml_body = <<-YAML
    apiVersion: policy/v1
    kind: PodDisruptionBudget
    metadata:
      name: emp-configuration-service
      namespace: backend
    spec:
      maxUnavailable: 1
      selector:
        matchLabels:
          app.kubernetes.io/name: emp-configuration-service
  YAML
}