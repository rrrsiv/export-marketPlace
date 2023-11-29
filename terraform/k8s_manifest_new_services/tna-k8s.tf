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
      replicas: 2
      template:
        metadata:
          labels:
            app.kubernetes.io/name: emp-tna-service
        spec:
          containers:
          - name: emp-tna-service
            imagePullPolicy: Always
            image: 656600766668.dkr.ecr.ap-south-1.amazonaws.com/emp-tna-service:a2f886a20230703074231
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

      spring.datasource.url: jdbc:mysql://emp-qa-rds-mysql.chaqp2ysfjmh.ap-south-1.rds.amazonaws.com:3306/tna_dev?createDatabaseIfNotExist=true
      spring.datasource.username: root
    
      spring.datasource.driver-class-name: com.mysql.jdbc.Driver
      #spring.jpa.hibernate.ddl-auto: validate

      opentracing.jaeger.http-sender.url: http://localhost:16686/api/traces

      spring.liquibase.change-log: classpath:db/changelog/db.changelog-master.xml

      # Kafka config
      spring.kafka.bootstrap-servers: 10.132.80.37:9092

      # Kafka topic
      emp.notification.email.topic: emp.notification.email.dev

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
      spring.datasource.password: cGFzc3dvcmQjMTIzNA==
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
      maxUnavailable: 1
      selector:
        matchLabels:
          app.kubernetes.io/name: emp-tna-service
  YAML
}