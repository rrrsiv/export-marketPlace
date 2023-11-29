resource "kubectl_manifest" "deployment_payment" {
  yaml_body = <<-YAML
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: emp-payment-service
      namespace: backend
    spec:
      selector:
        matchLabels:
          app.kubernetes.io/name: emp-payment-service
      replicas: 1
      template:
        metadata:
          labels:
            app.kubernetes.io/name: emp-payment-service
        spec:
          containers:
          - name: emp-payment-service
            imagePullPolicy: Always
            image: 656600766668.dkr.ecr.ap-south-1.amazonaws.com/emp-payment-service:50c3e6220230914112741
            ports:
            - containerPort: 8090
            resources:
              limits:
                cpu: 750m
                memory: 750Mi
              requests:
                cpu: 500m
                memory: 500Mi
            envFrom:
            - configMapRef:
                name: emp-payment-service-cm
            - secretRef:
                name: emp-payment-service-secret
            livenessProbe:
              httpGet:
                path: /emp-payment-service/actuator/health
                port: 8090
              initialDelaySeconds: 90
              periodSeconds: 30
              timeoutSeconds: 30
  YAML
}


resource "kubectl_manifest" "service_payment" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Service
    metadata:
      name: emp-payment-service
      namespace: backend
      annotations:
        alb.ingress.kubernetes.io/healthcheck-port: '8090'
        alb.ingress.kubernetes.io/healthcheck-path: /emp-payment-service/actuator/health
    spec:
      ports:
      - port: 80
        protocol: TCP
        targetPort: 8090
      type: ClusterIP
      selector:
        app.kubernetes.io/name: emp-payment-service

  YAML
}

resource "kubectl_manifest" "config_payment" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: emp-payment-service-cm
      namespace: backend
    data:
      
      server.port: "8090"
      server.servlet.context-path: /emp-payment-service

      spring.application.name: emp-payment-service
      spring.jpa.generate-ddl: "false"

      logging.level.com.mj.marketplace.export.payment: DEBUG
      logging.level.org.apache.http: DEBUG
      logging.level.org.springframework.web.client.RestTemplate: DEBUG
      payment.payoneer.account-id: "100208910"
      payment.payoneer.url.login: https://login.sandbox.payoneer.com/api
      payment.payoneer.url.api: https://api.sandbox.payoneer.com
      payment.payoneer.url.auth-token: /v2/oauth2/token
      payment.payoneer.url.registration-link: /v4/programs/{paymentPayoneerAccountId}/payees/registration-link
      payment.payoneer.redirect-url: https://login.sandbox.payoneer.com/api/v2/oauth2/authorize?client_id=oTxFTNNC1WxeTmWv6AdKneG9Kp68bGDG&redirect_uri=https://www.example.com&scope=read%20write%20openid%20personal-details&response_type=code
      payment.payoneer.payee-status-url: https://api.sandbox.payoneer.com/v4/programs/{programId}/payees/{payeeId}/status
      payment.payoneer.optin-url: https://api.sandbox.payoneer.com/v4/accounts/{accountId}/payment_request/optin
      payment.payoneer.program-id: "100208910"
      payment.sap.static.userName: PIAPPL_EXT

      seller-service.name: emp-seller-service
      seller-service.url: http://emp-seller-service/emp-seller-service

      spring.datasource.url: jdbc:mysql://emp-qa-rds-mysql.chaqp2ysfjmh.ap-south-1.rds.amazonaws.com:3306/payment?createDatabaseIfNotExist=true
      spring.datasource.username: root

      spring.datasource.driver-class-name: com.mysql.jdbc.Driver

      opentracing.jaeger.http-sender.url: http://localhost:16686/api/traces

      spring.liquibase.change-log: classpath:db/changelog/db.changelog-master.xml

      spring.redis.host: emp-elasticcache.ypkey6.clustercfg.aps1.cache.amazonaws.com
      spring.redis.port: "6379"
      spring.cache.redis.cache-null-values: "false"
      spring.cache.redis.time-to-live: "600000"
      spring.cache.type: none
      spring.cache.redis.enable-statistics : "true"

      spring.kafka.bootstrap-servers: 10.132.80.37:9092
      emp.notification.email.topic: emp.notification.email.dev
      kafkaconsumer.bootstrap: 10.132.80.37:9092
      spring.kafka.producer.key-serializer: org.apache.kafka.common.serialization.StringSerializer
      spring.kafka.producer.value-serializer: org.springframework.kafka.support.serializer.JsonSerializer

  YAML
}

resource "kubectl_manifest" "secret_payment" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Secret
    metadata:
      name: emp-payment-service-secret
      namespace: backend
    data:
      spring.datasource.password: cGFzc3dvcmQjMTIzNA==
      payment.payoneer.client-id: b1R4RlROTkMxV3hlVG1XdjZBZEtuZUc5S3A2OGJHREc=
      payment.payoneer.secret: QlhIUWhybTdoR1kycEQyVA==
      payment.sap.static.password: TWpuQDA4MjAyMg==
  YAML

}

resource "kubectl_manifest" "pdb_payment" {
  yaml_body = <<-YAML
    apiVersion: policy/v1
    kind: PodDisruptionBudget
    metadata:
      name: emp-payment-service
      namespace: backend
    spec:
      maxUnavailable: 1
      selector:
        matchLabels:
          app.kubernetes.io/name: emp-payment-service
  YAML
}