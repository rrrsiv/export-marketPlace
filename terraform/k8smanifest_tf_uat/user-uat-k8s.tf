resource "kubectl_manifest" "deployment_user" {
  yaml_body = <<-YAML
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: emp-user-service
      namespace: backend
    spec:
      selector:
        matchLabels:
          app.kubernetes.io/name: emp-user-service
      replicas: 3
      template:
        metadata:
          labels:
            app.kubernetes.io/name: emp-user-service
        spec:
          containers:
          - name: emp-user-service
            imagePullPolicy: Always
            image: 656600766668.dkr.ecr.ap-south-1.amazonaws.com/emp-user-service-ecr:a90431e20230522085608
            ports:
            - containerPort: 8081
            resources:
              limits:
                cpu: 750m
                memory: 750Mi
              requests:
                cpu: 500m
                memory: 500Mi
            envFrom:
            - configMapRef:
                name: emp-user-service-cm
            - secretRef:
                name: emp-user-service-secret
            livenessProbe:
              httpGet:
                path: /emp-user-service/actuator
                port: 8081
              initialDelaySeconds: 90
              periodSeconds: 30
              timeoutSeconds: 30
  YAML
}


resource "kubectl_manifest" "service_user" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Service
    metadata:
      name: emp-user-service
      namespace: backend
      annotations:
        alb.ingress.kubernetes.io/healthcheck-port: '8081'
        alb.ingress.kubernetes.io/healthcheck-path: /emp-user-service/actuator
    spec:
      ports:
      - port: 80
        protocol: TCP
        targetPort: 8081
      type: ClusterIP
      selector:
        app.kubernetes.io/name: emp-user-service

  YAML
}

resource "kubectl_manifest" "config_user" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: emp-user-service-cm
      namespace: backend
    data:
        kafkaconsumer.bootstrap: http://10.132.80.37:9092
        server.port: "8081"
        server.servlet.context-path: /emp-user-service
        spring.application.name: emp-user-service
        spring.datasource.driver-class-name: com.mysql.jdbc.Driver
        spring.datasource.driver.class.name: com.mysql.jdbc.Driver
        spring.datasource.url: jdbc:mysql://emp-uat-rds-mysql.chaqp2ysfjmh.ap-south-1.rds.amazonaws.com:3306/usermanagement?createDatabaseIfNotExist=true
        spring.datasource.username: root
        spring.jpa.generate-ddl: "true"
        spring.jpa.properties.hibernate.dialect: org.hibernate.dialect.MySQL5InnoDBDialect
        spring.liquibase.change-log: classpath:db/changelog/db.changelog-master.xml

  YAML
}

resource "kubectl_manifest" "secret_user" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Secret
    metadata:
      name: emp-user-service-secret
      namespace: backend
    data:
      spring.datasource.password: cGFzc3dvcmQjMTIzNA==
  YAML

}

resource "kubectl_manifest" "pdb_user" {
  yaml_body = <<-YAML
    apiVersion: policy/v1
    kind: PodDisruptionBudget
    metadata:
      name: emp-user-service
      namespace: backend
    spec:
      maxUnavailable: 1
      selector:
        matchLabels:
          app.kubernetes.io/name: emp-user-service
  YAML
}