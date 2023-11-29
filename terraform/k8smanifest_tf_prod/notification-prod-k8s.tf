resource "kubectl_manifest" "deployment_notification" {
  yaml_body = <<-YAML
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: emp-notification-service
      namespace: backend
    spec:
      selector:
        matchLabels:
          app.kubernetes.io/name: emp-notification-service
      replicas: 3
      template:
        metadata:
          labels:
            app.kubernetes.io/name: emp-notification-service
        spec:
          containers:
          - name: emp-notification-service
            imagePullPolicy: Always
            image: 453708032754.dkr.ecr.ap-south-1.amazonaws.com/emp-notification-service:d62575e20230601133239
            ports:
            - containerPort: 8085
            resources:
              limits:
                cpu: 750m
                memory: 750Mi
              requests:
                cpu: 500m
                memory: 500Mi
            envFrom:
            - configMapRef:
                name: emp-notification-service-cm
            - secretRef:
                name: emp-notification-service-secret
            livenessProbe:
              httpGet:
                path: /emp-notification-service/actuator/health
                port: 8085
              initialDelaySeconds: 90
              periodSeconds: 30
              timeoutSeconds: 30
  YAML
}


resource "kubectl_manifest" "service_notification" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Service
    metadata:
      name: emp-notification-service
      namespace: backend
      annotations:
        alb.ingress.kubernetes.io/healthcheck-port: '8085'
        alb.ingress.kubernetes.io/healthcheck-path: /emp-notification-service/actuator/health
    spec:
      ports:
      - port: 80
        protocol: TCP
        targetPort: 8085
      type: ClusterIP
      selector:
        app.kubernetes.io/name: emp-notification-service

  YAML
}

resource "kubectl_manifest" "config_notification" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: emp-notification-service-cm
      namespace: backend
    data:
        mj-email-service.name: mj-notification-service
        mj-email-service.send-notification-url: /notification/send
        mj-email-service.url: http://10.132.83.4:3001
        mj.notification.service.application-code: 2edsH3dn
        mj.notification.service.email-template-code: sendOtpEmail
        mj.notification.service.sms-template-code: generalSMSTest
        mj.notification.service.subapplication-code: gf3aV2sJ
        oms.domain.event.enable-dlq: "true"
        oms.domain.event.retry.initial-interval: "1000"
        oms.domain.event.retry.max-interval: "60000"
        oms.domain.event.retry.multiplier: "3"
        opentracing.jaeger.http-sender.url: http://localhost:16686/api/traces
        server.port: "8085"
        server.servlet.context-path: /emp-notification-service
        spring.application.name: emp-notification-service
        spring.datasource.driver-class-name: com.mysql.jdbc.Driver
        spring.datasource.url: jdbc:mysql://emp-prod-mysql-rds.c1ebqe1npo60.ap-south-1.rds.amazonaws.com:3306/notification?createDatabaseIfNotExist=true
        spring.datasource.username: root
        spring.jpa.generate-ddl: "false"
        
        spring.liquibase.change-log: classpath:db/changelog/db.changelog-master.xml
        kafkaconsumer.bootstrap: http://10.132.25.57:9092

  YAML
}

resource "kubectl_manifest" "secret_notification" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Secret
    metadata:
      name: emp-notification-service-secret
      namespace: backend
    data:
      spring.datasource.password: SjIzYTBrSjJsMk5a
  YAML

}

resource "kubectl_manifest" "pdb_notification" {
  yaml_body = <<-YAML
    apiVersion: policy/v1
    kind: PodDisruptionBudget
    metadata:
      name: emp-notification-service
      namespace: backend
    spec:
      maxUnavailable: 1
      selector:
        matchLabels:
          app.kubernetes.io/name: emp-notification-service
  YAML
}