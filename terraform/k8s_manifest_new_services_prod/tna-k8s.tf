resource "kubectl_manifest" "deployment_tna" {
  yaml_body = <<-YAML
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: emp-tna-service
      namespace: backend
    spec:
      selector:
        matchLabels:
          app.kubernetes.io/name: emp-tna-service
      replicas: 4
      template:
        metadata:
          labels:
            app.kubernetes.io/name: emp-tna-service
        spec:
          containers:
          - name: emp-tna-service
            imagePullPolicy: Always
            image: 453708032754.dkr.ecr.ap-south-1.amazonaws.com/prod-emp-tna-service:29c29e420230911060946
            ports:
            - containerPort: 8088
            resources:
              limits:
                cpu: 750m
                memory: 750Mi
              requests:
                cpu: 500m
                memory: 500Mi
            envFrom:
            - configMapRef:
                name: emp-tna-service-cm
            - secretRef:
                name: emp-tna-service-secret
            livenessProbe:
              httpGet:
                path: /tna/actuator
                port: 8088
              initialDelaySeconds: 90
              periodSeconds: 30
              timeoutSeconds: 30
  YAML
}


resource "kubectl_manifest" "service_tna" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Service
    metadata:
      name: emp-tna-service
      namespace: backend
      annotations:
        alb.ingress.kubernetes.io/healthcheck-port: '8088'
        alb.ingress.kubernetes.io/healthcheck-path: /tna/actuator
    spec:
      ports:
      - port: 80
        protocol: TCP
        targetPort: 8088
      type: ClusterIP
      selector:
        app.kubernetes.io/name: emp-tna-service

  YAML
}

resource "kubectl_manifest" "config_tna" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: emp-tna-service-cm
      namespace: backend
    data:
      server.port: "8088"

      spring.application.name: emp-tna-service
      spring.jpa.generate-ddl: "false"
      server.servlet.context-path: /tna

      spring.datasource.url: jdbc:mysql://emp-prod-mysql-rds.c1ebqe1npo60.ap-south-1.rds.amazonaws.com:3306/tna?createDatabaseIfNotExist=true
      spring.datasource.username: root
    
      spring.datasource.driver-class-name: com.mysql.jdbc.Driver
      #spring.jpa.hibernate.ddl-auto: validate
      opentracing.jaeger.http-sender.url: http://localhost:16686/api/traces
      spring.liquibase.change-log: classpath:db/changelog/db.changelog-master.xml

      #Redis
      spring.redis.host: clustercfg.emp-redis-production.5wm9au.aps1.cache.amazonaws.com
      spring.redis.port: "6379"
      spring.cache.redis.cache-null-values: "false"
      spring.cache.redis.time-to-live: "600000"
      spring.cache.type: redis
      #spring.cache.cache-names: trest
      #spring.data.redis.repositories.enabled: "false"
      spring.cache.redis.enable-statistics: "true"

      # Kafka config
      spring.kafka.bootstrap-servers: 10.132.25.57:9092

      # Kafka topic
      emp.notification.email.topic: emp.notification.email.prod
      emp.tna.delivered.dev.topic: emp.tna.delivered.prod
      seller-service.name: emp-seller-service
      seller-service.url: http://emp-seller-service/emp-seller-service
      catalogue-service.url: http://emp-catalogue-service/emp-catalogue-service
      catalogue-service.name: emp-catalogue-service

      configuration-service.name: emp-configuration-service
      configuration-service.url: http://emp-configuration-service/emp-configuration-service
      buyer-service.name: emp-buyer-service
      buyer-service.url: http://emp-buyer-service/buyer
      contract-purchase-order.name: emp-contract-purchase-order-service
      contract-purchase-order.url: http://emp-contract-purchase-order-service/emp-contract-purchase-order-service
      tna.list.default.page.size: "5"
      mj.tna.list.default.page.size: "10"
      mjadmin.email.address: exmenquiry@mjunction.in

  YAML
}

resource "kubectl_manifest" "secret_tna" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Secret
    metadata:
      name: emp-tna-service-secret
      namespace: backend
    data:
      spring.datasource.password: SjIzYTBrSjJsMk5a
  YAML

}

resource "kubectl_manifest" "pdb_tna" {
  yaml_body = <<-YAML
    apiVersion: policy/v1
    kind: PodDisruptionBudget
    metadata:
      name: emp-tna-service
      namespace: backend
    spec:
      maxUnavailable: 2
      selector:
        matchLabels:
          app.kubernetes.io/name: emp-tna-service
  YAML
}