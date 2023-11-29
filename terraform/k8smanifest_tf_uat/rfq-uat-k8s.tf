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
      replicas: 3
      template:
        metadata:
          labels:
            app.kubernetes.io/name: emp-rfq-service
        spec:
          containers:
          - name: emp-rfq-service
            imagePullPolicy: Always
            image: 656600766668.dkr.ecr.ap-south-1.amazonaws.com/emp-rfq-service:ddf107420230704130211
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
        opentracing.jaeger.http-sender.url: http://localhost:16686/api/traces
        server.port: "8084"
        server.servlet.context-path: /emp-rfq-service
        spring.application.name: emp-rfq-service
        spring.cache.redis.cache-null-values: "false"
        spring.cache.redis.enable-statistics: "true"
        spring.cache.redis.time-to-live: "600000"
        spring.cache.type: none
        spring.datasource.driver-class-name: com.mysql.jdbc.Driver
        spring.datasource.url: jdbc:mysql://emp-uat-rds-mysql.chaqp2ysfjmh.ap-south-1.rds.amazonaws.com:3306/rfq?useSSL=false&createDatabaseIfNotExist=true
        spring.datasource.username: root
        spring.jpa.generate-ddl: "false"
        spring.liquibase.change-log: classpath:db/changelog/db.changelog-master.xml
        spring.redis.host: emp-elasticcache-uat.ypkey6.clustercfg.aps1.cache.amazonaws.com
        spring.redis.port: "6379"

        seller-service.name: emp-seller-service
        seller-service.url: http://emp-seller-service/emp-seller-service

        configuration-service.name: emp-configuration-service
        configuration-service.url: http://emp-configuration-service/emp-configuration-service
        buyer-service.name: emp-buyer-service
        buyer-service.url: http://emp-buyer-service/buyer
        catalogue-service.name: emp-catalogue-service
        catalogue-service.url: http://emp-catalogue-service/emp-catalogue-service

        rfq.list.days.tomark.critical: "3"
        rfq.list.default.page.size: "6"

        kafka.rfq-topic: rfq_create
        emp.notification.email.topic: emp.notification.email.dev
        kafkaconsumer.bootstrap: 10.132.80.37:9092
        spring.kafka.producer.key-serializer: org.apache.kafka.common.serialization.StringSerializer
        spring.kafka.producer.value-serializer: org.springframework.kafka.support.serializer.JsonSerializer
        spring.kafka.bootstrap-servers: 10.132.80.37:9092

        notify.seller.cron: 0 59 23 * * ?
        seller.last.bid.date.days: "5"

        notify.buyer.cron: 0 59 23 * * ?
        buyer.bid.valid.till.days: "5"

        rfq.draft.days.notify: "3"
        notify.buyer.rfq.cron: 0 59 22 * * ?

        rfq.not.viewed.since.days: "3"
        notify.seller.rfq.not.viewed: 0 59 20 * * ?

        quote.valid.till.offset.days: "30"

        rfq.enable.request.response.logging: "true"

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
      spring.datasource.password: cGFzc3dvcmQjMTIzNA==
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
      maxUnavailable: 1
      selector:
        matchLabels:
          app.kubernetes.io/name: emp-rfq-service
  YAML
}