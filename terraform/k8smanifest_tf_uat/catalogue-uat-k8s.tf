resource "kubectl_manifest" "deployment_catalogue" {
  yaml_body = <<-YAML
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: emp-catalogue-service
      namespace: backend
    spec:
      selector:
        matchLabels:
          app.kubernetes.io/name: emp-catalogue-service
      replicas: 3
      template:
        metadata:
          labels:
            app.kubernetes.io/name: emp-catalogue-service
        spec:
          containers:
          - name: emp-catalogue-service
            imagePullPolicy: Always
            image: 656600766668.dkr.ecr.ap-south-1.amazonaws.com/emp-catalogue-service:cb64a0c20230522090016
            ports:
            - containerPort: 8082
            resources:
              limits:
                cpu: 750m
                memory: 750Mi
              requests:
                cpu: 500m
                memory: 500Mi
            envFrom:
            - configMapRef:
                name: emp-catalogue-service-cm
            - secretRef:
                name: emp-catalogue-service-secret
            livenessProbe:
              httpGet:
                path: /emp-catalogue-service/actuator
                port: 8082
              initialDelaySeconds: 90
              periodSeconds: 30
              timeoutSeconds: 30
  YAML
}


resource "kubectl_manifest" "service_catalogue" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Service
    metadata:
      name: emp-catalogue-service
      namespace: backend
      annotations:
        alb.ingress.kubernetes.io/healthcheck-port: '8082'
        alb.ingress.kubernetes.io/healthcheck-path: /emp-catalogue-service/actuator
    spec:
      ports:
      - port: 80
        protocol: TCP
        targetPort: 8082
      type: ClusterIP
      selector:
        app.kubernetes.io/name: emp-catalogue-service

  YAML
}

resource "kubectl_manifest" "config_catalogue" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: emp-catalogue-service-cm
      namespace: backend
    data:
      server.port: "8082"

      spring.application.name: emp-catalogue-service
      spring.jpa.generate-ddl: "false"

      spring.datasource.url: jdbc:mysql://emp-uat-rds-mysql.chaqp2ysfjmh.ap-south-1.rds.amazonaws.com:3306/catalogue?createDatabaseIfNotExist=true
      spring.datasource.username: root

      spring.datasource.driver-class-name: com.mysql.jdbc.Driver
      #spring.jpa.hibernate.ddl-auto=validate

      opentracing.jaeger.http-sender.url: http://localhost:16686/api/traces

      spring.liquibase.change-log: classpath:db/changelog/db.changelog-master.xml
      spring.data.mongodb.uri: mongodb://empdoc:Indianteam1983@docdb-2023-04-18-05-48-15.chaqp2ysfjmh.ap-south-1.docdb.amazonaws.com:27017/?ssl=true&ssl_ca_certs=rds-combined-ca-bundle.pem&retryWrites=false
      spring.data.mongodb.database: catalogue_uat
      spring.data.mongodb.username: empdoc

      spring.data.mongodb.authentication-database: admin
      logging.level.org.springframework.data.mongodb.core.MongoTemplate: DEBUG
      kafkaconsumer.bootstrap: http://10.132.80.37:9092


  YAML
}

resource "kubectl_manifest" "secret_catalogue" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Secret
    metadata:
      name: emp-catalogue-service-secret
      namespace: backend
    data:
      spring.datasource.password: cGFzc3dvcmQjMTIzNA==
      spring.data.mongodb.password: SW5kaWFudGVhbTE5ODM=
  YAML

}

resource "kubectl_manifest" "pdb_catalogue" {
  yaml_body = <<-YAML
    apiVersion: policy/v1
    kind: PodDisruptionBudget
    metadata:
      name: emp-catalogue-service
      namespace: backend
    spec:
      maxUnavailable: 1
      selector:
        matchLabels:
          app.kubernetes.io/name: emp-catalogue-service
  YAML
}