resource "kubectl_manifest" "deployment_vas" {
  yaml_body = <<-YAML
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: emp-vas-service
      namespace: backend
    spec:
      selector:
        matchLabels:
          app.kubernetes.io/name: emp-vas-service
      replicas: 2
      template:
        metadata:
          labels:
            app.kubernetes.io/name: emp-vas-service
        spec:
          containers:
          - name: emp-vas-service
            imagePullPolicy: Always
            image: 656600766668.dkr.ecr.ap-south-1.amazonaws.com/emp-vas-service:b11236020230920100602
            ports:
            - containerPort: 8091
            resources:
              limits:
                cpu: 750m
                memory: 750Mi
              requests:
                cpu: 500m
                memory: 500Mi
            envFrom:
            - configMapRef:
                name: emp-vas-service-cm
            - secretRef:
                name: emp-vas-service-secret
            livenessProbe:
              httpGet:
                path: /vas/actuator
                port: 8091
              initialDelaySeconds: 90
              periodSeconds: 30
              timeoutSeconds: 30
  YAML
}


resource "kubectl_manifest" "service_vas" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Service
    metadata:
      name: emp-vas-service
      namespace: backend
      annotations:
        alb.ingress.kubernetes.io/healthcheck-port: '8091'
        alb.ingress.kubernetes.io/healthcheck-path: /vas/actuator
    spec:
      ports:
      - port: 80
        protocol: TCP
        targetPort: 8091
      type: ClusterIP
      selector:
        app.kubernetes.io/name: emp-vas-service

  YAML
}

resource "kubectl_manifest" "config_vas" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: emp-vas-service-cm
      namespace: backend
    data:
      
      server.port: "8091"
      server.servlet.context-path: /vas

      spring.application.name: emp-vas-service
      spring.jpa.generate-ddl: "false"

      seller-service.name: emp-seller-service
      seller-service.url: http://emp-seller-service/emp-seller-service

      spring.datasource.url: jdbc:mysql://emp-uat-rds-mysql.chaqp2ysfjmh.ap-south-1.rds.amazonaws.com:3306/vas?createDatabaseIfNotExist=true
      spring.datasource.username: root

      spring.datasource.driver-class-name: com.mysql.jdbc.Driver

      opentracing.jaeger.http-sender.url: http://localhost:16686/api/traces

      spring.liquibase.change-log: classpath:db/changelog/db.changelog-master.xml

      spring.redis.host: emp-elasticcache-uat.ypkey6.clustercfg.aps1.cache.amazonaws.com
      spring.redis.port: "6379"
      spring.cache.redis.cache-null-values: "false"
      spring.cache.redis.time-to-live: "600000"
      spring.cache.type: redis
      spring.datasource.hikari.maximum-pool-size: "10"
      spring.cache.redis.enable-statistics : "true"

      spring.kafka.bootstrap-servers: 10.132.80.37:9092
      emp.notification.email.topic: emp.notification.email.dev
      kafkaconsumer.bootstrap: 10.132.80.37:9092
      spring.kafka.producer.key-serializer: org.apache.kafka.common.serialization.StringSerializer
      spring.kafka.producer.value-serializer: org.springframework.kafka.support.serializer.JsonSerializer

  YAML
}

resource "kubectl_manifest" "secret_vas" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Secret
    metadata:
      name: emp-vas-service-secret
      namespace: backend
    data:
      spring.datasource.password: cGFzc3dvcmQjMTIzNA==
  YAML

}

resource "kubectl_manifest" "pdb_vas" {
  yaml_body = <<-YAML
    apiVersion: policy/v1
    kind: PodDisruptionBudget
    metadata:
      name: emp-vas-service
      namespace: backend
    spec:
      maxUnavailable: 1
      selector:
        matchLabels:
          app.kubernetes.io/name: emp-vas-service
  YAML
}