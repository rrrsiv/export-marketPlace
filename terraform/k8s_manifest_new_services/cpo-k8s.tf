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
      replicas: 2
      template:
        metadata:
          labels:
            app.kubernetes.io/name: emp-contract-purchase-order-service
        spec:
          containers:
          - name: emp-contract-purchase-order-service
            imagePullPolicy: Always
            image: 656600766668.dkr.ecr.ap-south-1.amazonaws.com/emp-contract-purchase-order-service:6b716eb20230703075137
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

      spring.application.name: emp-contract-purchase-order-service
      spring.jpa.generate-ddl: "false"
      server.servlet.context-path: /emp-contract-purchase-order-service

      spring.datasource.url: jdbc:mysql://emp-qa-rds-mysql.chaqp2ysfjmh.ap-south-1.rds.amazonaws.com:3306/contractpo?createDatabaseIfNotExist=true
      spring.datasource.username: root
    
      spring.datasource.driver-class-name: com.mysql.jdbc.Driver
      #spring.jpa.hibernate.ddl-auto: validate

      opentracing.jaeger.http-sender.url: http://localhost:16686/api/traces

      spring.liquibase.change-log: classpath:db/changelog/db.changelog-master.xml

      # Kafka config
      spring.kafka.bootstrap-servers: 10.132.80.37:9092

      # Kafka topic
      emp.notification.email.topic: emp.notification.email.dev

      kafkaconsumer.bootstrap: 10.132.80.37:9092
      spring.kafka.producer.key-serializer: org.apache.kafka.common.serialization.StringSerializer
      spring.kafka.producer.value-serializer: org.springframework.kafka.support.serializer.JsonSerializer

     
      spring.redis.host: emp-elasticcache.ypkey6.clustercfg.aps1.cache.amazonaws.com
      spring.redis.port: "6379"
      spring.cache.redis.cache-null-values: "false"
      spring.cache.redis.time-to-live: "600000"
      spring.cache.type: none
      #spring.cache.cache-names: trest
      #spring.data.redis.repositories.enabled: "false"
      spring.cache.redis.enable-statistics: "true"


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
      spring.datasource.password: cGFzc3dvcmQjMTIzNA==
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
      maxUnavailable: 1
      selector:
        matchLabels:
          app.kubernetes.io/name: emp-contract-purchase-order-service
  YAML
}