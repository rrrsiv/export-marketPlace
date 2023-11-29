resource "kubectl_manifest" "deployment_rfq" {
  yaml_body = <<-YAML
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: emp-rfq-service
      namespace: backend
    spec:
      selector:
        matchLabels:
          app.kubernetes.io/name: emp-rfq-service
      replicas: 4
      template:
        metadata:
          labels:
            app.kubernetes.io/name: emp-rfq-service
        spec:
          containers:
          - name: emp-rfq-service
            imagePullPolicy: Always
            image: 453708032754.dkr.ecr.ap-south-1.amazonaws.com/emp-rfq-service:e2eb23020230911061223
            ports:
            - containerPort: 8084
            resources:
              limits:
                cpu: 750m
                memory: 750Mi
              requests:
                cpu: 500m
                memory: 500Mi
            envFrom:
            - configMapRef:
                name: emp-rfq-service-cm
            - secretRef:
                name: emp-rfq-service-secret
            livenessProbe:
              httpGet:
                path: /emp-rfq-service/actuator/health
                port: 8084
              initialDelaySeconds: 90
              periodSeconds: 30
              timeoutSeconds: 30
  YAML
}


resource "kubectl_manifest" "service_rfq" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Service
    metadata:
      name: emp-rfq-service
      namespace: backend
      annotations:
        alb.ingress.kubernetes.io/healthcheck-port: '8084'
        alb.ingress.kubernetes.io/healthcheck-path: /emp-rfq-service/actuator/health
    spec:
      ports:
      - port: 80
        protocol: TCP
        targetPort: 8084
      type: ClusterIP
      selector:
        app.kubernetes.io/name: emp-rfq-service

  YAML
}

resource "kubectl_manifest" "config_rfq" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: emp-rfq-service-cm
      namespace: backend
    data:
        server.port: "8084"
        spring.cache.redis.cache-null-values: "false"
        spring.cache.redis.enable-statistics: "true"
        spring.cache.redis.time-to-live: "600000"
        spring.cache.type: redis
        spring.datasource.driver-class-name: com.mysql.jdbc.Driver
        spring.datasource.url: jdbc:mysql://emp-prod-mysql-rds.c1ebqe1npo60.ap-south-1.rds.amazonaws.com:3306/rfq?useSSL=false&createDatabaseIfNotExist=true
        spring.datasource.username: root
        spring.jpa.generate-ddl: "false"
        spring.redis.host: clustercfg.emp-redis-production.5wm9au.aps1.cache.amazonaws.com
        spring.redis.port: "6379"

        buyer-service.name: emp-buyer-service
        buyer-service.url: http://emp-buyer-service/buyer
        buyer.bid.valid.till.days: "5"
        catalogue-service.name: emp-catalogue-service
        catalogue-service.url: http://emp-catalogue-service/emp-catalogue-service
        configuration-service.name: emp-configuration-service
        configuration-service.url: http://emp-configuration-service/emp-configuration-service
        emp.notification.email.topic: emp.notification.email.prod
        kafka.rfq-topic: rfq_create
        kafkaconsumer.bootstrap: 10.132.25.57:9092
        notify.buyer.cron: 0 59 23 * * ?
        notify.buyer.rfq.cron: 0 59 22 * * ?
        notify.seller.cron: 0 59 23 * * ?
        notify.seller.rfq.not.viewed: 0 59 20 * * ?
        opentracing.jaeger.http-sender.url: http://localhost:16686/api/traces
        quote.valid.till.offset.days: "30"
        rfq.draft.days.notify: "3"
        rfq.enable.request.response.logging: "true"
        rfq.list.days.tomark.critical: "3"
        rfq.list.default.page.size: "6"
        rfq.not.viewed.since.days: "3"

        seller-service.name: emp-seller-service
        seller-service.url: http://emp-seller-service/emp-seller-service
        seller.last.bid.date.days: "5"
       
        server.servlet.context-path: /emp-rfq-service
        spring.application.name: emp-rfq-service

    
        spring.kafka.bootstrap-servers: 10.132.25.57:9092
        spring.kafka.producer.key-serializer: org.apache.kafka.common.serialization.StringSerializer
        spring.kafka.producer.value-serializer: org.springframework.kafka.support.serializer.JsonSerializer
        spring.liquibase.change-log: classpath:db/changelog/db.changelog-master.xml
 
        swagger.ui.enabled: "false"

  YAML
}

resource "kubectl_manifest" "secret_rfq" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Secret
    metadata:
      name: emp-rfq-service-secret
      namespace: backend
    data:
      spring.datasource.password: SjIzYTBrSjJsMk5a
  YAML

}

resource "kubectl_manifest" "pdb_rfq" {
  yaml_body = <<-YAML
    apiVersion: policy/v1
    kind: PodDisruptionBudget
    metadata:
      name: emp-rfq-service
      namespace: backend
    spec:
      maxUnavailable: 2
      selector:
        matchLabels:
          app.kubernetes.io/name: emp-rfq-service
  YAML
}