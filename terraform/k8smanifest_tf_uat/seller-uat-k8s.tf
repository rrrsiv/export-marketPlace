resource "kubectl_manifest" "deployment_seller" {
  yaml_body = <<-YAML
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: emp-seller-service
      namespace: backend
    spec:
      selector:
        matchLabels:
          app.kubernetes.io/name: emp-seller-service
      replicas: 3
      template:
        metadata:
          labels:
            app.kubernetes.io/name: emp-seller-service
        spec:
          containers:
          - name: emp-seller-service
            imagePullPolicy: Always
            image: 656600766668.dkr.ecr.ap-south-1.amazonaws.com/emp-seller-service-ecr:59acc9120230522074825
            ports:
            - containerPort: 8080
            resources:
              limits:
                cpu: 750m
                memory: 750Mi
              requests:
                cpu: 500m
                memory: 500Mi
            envFrom:
            - configMapRef:
                name: emp-seller-service-cm
            - secretRef:
                name: emp-seller-service-secret
            livenessProbe:
              httpGet:
                path: /emp-seller-service/actuator/health
                port: 8080
              initialDelaySeconds: 90
              periodSeconds: 30
              timeoutSeconds: 30
  YAML
}


resource "kubectl_manifest" "service_seller" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Service
    metadata:
      name: emp-seller-service
      namespace: backend
      annotations:
        alb.ingress.kubernetes.io/healthcheck-port: '8080'
        alb.ingress.kubernetes.io/healthcheck-path: /emp-seller-service/actuator/health
    spec:
      ports:
      - port: 80
        protocol: TCP
        targetPort: 8080
      type: ClusterIP
      selector:
        app.kubernetes.io/name: emp-seller-service

  YAML
}

resource "kubectl_manifest" "config_seller" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: emp-seller-service-cm
      namespace: backend
    data:
      server.port: "8080"

      spring.application.name: emp-seller-service
      spring.jpa.generate-ddl: "false"

      spring.datasource.url: jdbc:mysql://emp-uat-rds-mysql.chaqp2ysfjmh.ap-south-1.rds.amazonaws.com:3306/seller?createDatabaseIfNotExist=true
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


      emp.seller.temporary.cron: 0 0 6 * * ?
      emp.seller.temporary.hours: "72"

      #Default Values
      seller.search.default.page.size: "10"
  YAML
}

resource "kubectl_manifest" "secret_seller" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Secret
    metadata:
      name: emp-seller-service-secret
      namespace: backend
    data:
      spring.datasource.password: cGFzc3dvcmQjMTIzNA==
      secret_key: MmRhZTg0Zjg0NmU0ZjRiMTU4YThkMjY2ODE3MDdmNDMzODQ5NWJjN2FiNjgxNTFkN2Y3Njc5Y2M1ZTU2MjAyZGQzZGEwZDM1NmRhMDA3YTdjMjhjYjBiNzgwNDE4ZjRmMzI0Njc2OTk3MmQ2ZmVhYThmNjEwYzdkMWU3ZWNmNmE=
  YAML

}

resource "kubectl_manifest" "pdb_seller" {
  yaml_body = <<-YAML
    apiVersion: policy/v1
    kind: PodDisruptionBudget
    metadata:
      name: emp-seller-service
      namespace: backend
    spec:
      maxUnavailable: 1
      selector:
        matchLabels:
          app.kubernetes.io/name: emp-seller-service
  YAML
}