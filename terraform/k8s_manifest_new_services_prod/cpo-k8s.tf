resource "kubectl_manifest" "deployment_cpo" {
  yaml_body = <<-YAML
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: emp-contract-purchase-order-service
      namespace: backend
    spec:
      selector:
        matchLabels:
          app.kubernetes.io/name: emp-contract-purchase-order-service
      replicas: 4
      template:
        metadata:
          labels:
            app.kubernetes.io/name: emp-contract-purchase-order-service
        spec:
          containers:
          - name: emp-contract-purchase-order-service
            imagePullPolicy: Always
            image: 453708032754.dkr.ecr.ap-south-1.amazonaws.com/prod-emp-contract-purchase-order-service:e6c8cc720230911070022
            ports:
            - containerPort: 8089
            resources:
              limits:
                cpu: 750m
                memory: 750Mi
              requests:
                cpu: 500m
                memory: 500Mi
            envFrom:
            - configMapRef:
                name: emp-contract-purchase-order-service-cm
            - secretRef:
                name: emp-contract-purchase-order-service-secret
            livenessProbe:
              httpGet:
                path: /emp-contract-purchase-order-service/actuator
                port: 8089
              initialDelaySeconds: 90
              periodSeconds: 30
              timeoutSeconds: 30
  YAML
}


resource "kubectl_manifest" "service_cpo" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Service
    metadata:
      name: emp-contract-purchase-order-service
      namespace: backend
      annotations:
        alb.ingress.kubernetes.io/healthcheck-port: '8089'
        alb.ingress.kubernetes.io/healthcheck-path: /emp-contract-purchase-order-service/actuator
    spec:
      ports:
      - port: 80
        protocol: TCP
        targetPort: 8089
      type: ClusterIP
      selector:
        app.kubernetes.io/name: emp-contract-purchase-order-service

  YAML
}

resource "kubectl_manifest" "config_cpo" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: emp-contract-purchase-order-service-cm
      namespace: backend
    data:
      server.port: "8089"
      buyer-service.name: emp-buyer-service
      buyer-service.url: http://emp-buyer-service/buyer
      catalogue-service.name: emp-catalogue-service
      catalogue-service.url: http://emp-catalogue-service/emp-catalogue-service
      configuration-service.name: emp-configuration-service
      configuration-service.url: http://emp-configuration-service/emp-configuration-service
      contract.list.default.page.size: "6"
      emp.notification.email.topic: emp.notification.email.prod
      emp.tna.delivered.topic: emp.tna.delivered.prod
      kafkaconsumer.bootstrap: 10.132.25.57:9092
      opentracing.jaeger.http-sender.url: http://localhost:16686/api/traces
      seller-service.name: emp-seller-service
      seller-service.url: http://emp-seller-service/emp-seller-service
      server.servlet.context-path: /emp-contract-purchase-order-service
      spring.application.name: emp-contract-purchase-order-service
      spring.cache.redis.cache-null-values: "false"
      spring.cache.redis.enable-statistics: "true"
      spring.cache.redis.time-to-live: "600000"
      spring.cache.type: redis
      spring.datasource.driver-class-name: com.mysql.jdbc.Driver
      spring.datasource.url: jdbc:mysql://emp-prod-mysql-rds.c1ebqe1npo60.ap-south-1.rds.amazonaws.com:3306/contractpo?createDatabaseIfNotExist=true
      spring.datasource.username: root
      spring.jpa.generate-ddl: "false"
      spring.kafka.bootstrap-servers: 10.132.25.57:9092
      spring.kafka.producer.key-serializer: org.apache.kafka.common.serialization.StringSerializer
      spring.kafka.producer.value-serializer: org.springframework.kafka.support.serializer.JsonSerializer
      spring.liquibase.change-log: classpath:db/changelog/db.changelog-master.xml
      spring.profiles.active: production,swagger
      spring.redis.host: clustercfg.emp-redis-production.5wm9au.aps1.cache.amazonaws.com
      spring.redis.port: "6379"
      swagger.ui.enabled: "false"


  YAML
}

resource "kubectl_manifest" "secret_cpo" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Secret
    metadata:
      name: emp-contract-purchase-order-service-secret
      namespace: backend
    data:
      spring.datasource.password: SjIzYTBrSjJsMk5a
  YAML

}

resource "kubectl_manifest" "pdb_cpo" {
  yaml_body = <<-YAML
    apiVersion: policy/v1
    kind: PodDisruptionBudget
    metadata:
      name: emp-contract-purchase-order-service
      namespace: backend
    spec:
      maxUnavailable: 2
      selector:
        matchLabels:
          app.kubernetes.io/name: emp-contract-purchase-order-service
  YAML
}