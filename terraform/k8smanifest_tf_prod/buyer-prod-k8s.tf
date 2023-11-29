resource "kubectl_manifest" "deployment_buyer" {
  yaml_body = <<-YAML
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: emp-buyer-service
      namespace: backend
    spec:
      selector:
        matchLabels:
          app.kubernetes.io/name: emp-buyer-service
      replicas: 3
      template:
        metadata:
          labels:
            app.kubernetes.io/name: emp-buyer-service
        spec:
          containers:
          - name: emp-buyer-service
            imagePullPolicy: Always
            image: 453708032754.dkr.ecr.ap-south-1.amazonaws.com/emp-buyer-service:d0bec4920230601131909
            ports:
            - containerPort: 8087
            resources:
              limits:
                cpu: 750m
                memory: 750Mi
              requests:
                cpu: 500m
                memory: 500Mi
            envFrom:
            - configMapRef:
                name: emp-buyer-service-cm
            - secretRef:
                name: emp-buyer-service-secret
            livenessProbe:
              httpGet:
                path: /buyer/actuator
                port: 8087
              initialDelaySeconds: 90
              periodSeconds: 30
              timeoutSeconds: 30
  YAML
}


resource "kubectl_manifest" "service_buyer" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Service
    metadata:
      name: emp-buyer-service
      namespace: backend
      annotations:
        alb.ingress.kubernetes.io/healthcheck-port: '8087'
        alb.ingress.kubernetes.io/healthcheck-path: /buyer/actuator
    spec:
      ports:
      - port: 80
        protocol: TCP
        targetPort: 8087
      type: ClusterIP
      selector:
        app.kubernetes.io/name: emp-buyer-service

  YAML
}

resource "kubectl_manifest" "config_buyer" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: emp-buyer-service-cm
      namespace: backend
    data:
      server.port: "8087"

      spring.application.name: emp-buyer-service
      spring.jpa.generate-ddl: "false"
      server.servlet.context-path: /buyer

      spring.datasource.url: jdbc:mysql://emp-prod-mysql-rds.c1ebqe1npo60.ap-south-1.rds.amazonaws.com:3306/buyer?createDatabaseIfNotExist=true
      spring.datasource.username: root
    
      spring.datasource.driver-class-name: com.mysql.jdbc.Driver
      #spring.jpa.hibernate.ddl-auto: validate

      opentracing.jaeger.http-sender.url: http://localhost:16686/api/traces

      spring.liquibase.change-log: classpath:db/changelog/db.changelog-master.xml

      catalogue-service.url: http://emp-catalogue-service/emp-catalogue-service
      catalogue-service.name: emp-catalogue-service

      user-service.name: emp-user-service
      user-service.url: http://emp-user-service/emp-user-service

      configuration-service.name: emp-configuration-service
      configuration-service.url: http://emp-configuration-service/emp-configuration-service

      #spring.kafka.consumer.bootstrap-servers: localhost:9092
      #spring.kafka.consumer.group-id: test-consumer-group
      #spring.kafka.consumer.auto-offset-reset: earliest
      #spring.kafka.consumer.key-deserializer: org.apache.kafka.common.serialization.StringDeserializer
      #spring.kafka.consumer.value-deserializer: org.apache.kafka.common.serialization.StringDeserializer

      kafkaconsumer.bootstrap: http://10.132.25.57:9092

  YAML
}

resource "kubectl_manifest" "secret_buyer" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Secret
    metadata:
      name: emp-buyer-service-secret
      namespace: backend
    data:
      spring.datasource.password: SjIzYTBrSjJsMk5a
  YAML

}

resource "kubectl_manifest" "pdb_buyer" {
  yaml_body = <<-YAML
    apiVersion: policy/v1
    kind: PodDisruptionBudget
    metadata:
      name: emp-buyer-service
      namespace: backend
    spec:
      maxUnavailable: 1
      selector:
        matchLabels:
          app.kubernetes.io/name: emp-buyer-service
  YAML
}