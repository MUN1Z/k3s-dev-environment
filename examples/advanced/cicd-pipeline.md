# Advanced CI/CD Pipeline Configuration

This example demonstrates how to set up a complete CI/CD pipeline that deploys to your K3s development environment.

## GitHub Actions with K3s

### Workflow Configuration

```yaml
# .github/workflows/deploy-to-k3s.yml
name: Deploy to K3s Development Environment

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
        cache: 'npm'
    
    - name: Install dependencies
      run: npm ci
    
    - name: Run tests
      run: npm test
    
    - name: Run linting
      run: npm run lint

  build:
    needs: test
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    
    steps:
    - name: Checkout repository
      uses: actions/checkout@v3

    - name: Log in to Container Registry
      uses: docker/login-action@v2
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}

    - name: Extract metadata
      id: meta
      uses: docker/metadata-action@v4
      with:
        images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
        tags: |
          type=ref,event=branch
          type=ref,event=pr
          type=sha,prefix={{branch}}-

    - name: Build and push Docker image
      uses: docker/build-push-action@v4
      with:
        context: .
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}

  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main' || github.ref == 'refs/heads/develop'
    
    steps:
    - name: Checkout repository
      uses: actions/checkout@v3

    - name: Set up kubectl
      uses: azure/setup-kubectl@v3
      with:
        version: 'v1.28.0'

    - name: Configure kubectl for K3s
      run: |
        mkdir -p ~/.kube
        echo "${{ secrets.KUBE_CONFIG }}" | base64 -d > ~/.kube/config
        chmod 600 ~/.kube/config

    - name: Deploy to development
      if: github.ref == 'refs/heads/develop'
      run: |
        envsubst < k8s/deployment-dev.yaml | kubectl apply -f -
        kubectl rollout status deployment/myapp-dev -n development

    - name: Deploy to staging
      if: github.ref == 'refs/heads/main'
      run: |
        envsubst < k8s/deployment-staging.yaml | kubectl apply -f -
        kubectl rollout status deployment/myapp-staging -n staging

    - name: Run integration tests
      run: |
        kubectl wait --for=condition=ready pod -l app=myapp -n development --timeout=300s
        npm run test:integration
```

## Kubernetes Manifests

### Development Environment

```yaml
# k8s/deployment-dev.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-dev
  namespace: development
  labels:
    app: myapp
    environment: development
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp
      environment: development
  template:
    metadata:
      labels:
        app: myapp
        environment: development
    spec:
      containers:
      - name: myapp
        image: ghcr.io/myorg/myapp:develop-${GITHUB_SHA::8}
        ports:
        - containerPort: 3000
        env:
        - name: NODE_ENV
          value: "development"
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: myapp-secrets
              key: database-url
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: myapp-dev-service
  namespace: development
spec:
  selector:
    app: myapp
    environment: development
  ports:
  - port: 80
    targetPort: 3000
---
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: myapp-dev-route
  namespace: development
spec:
  entryPoints:
    - web
  routes:
    - match: Host(`myapp-dev.k3s.local`)
      kind: Rule
      services:
        - name: myapp-dev-service
          port: 80
```

### Staging Environment

```yaml
# k8s/deployment-staging.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-staging
  namespace: staging
  labels:
    app: myapp
    environment: staging
spec:
  replicas: 2
  selector:
    matchLabels:
      app: myapp
      environment: staging
  template:
    metadata:
      labels:
        app: myapp
        environment: staging
    spec:
      containers:
      - name: myapp
        image: ghcr.io/myorg/myapp:main-${GITHUB_SHA::8}
        ports:
        - containerPort: 3000
        env:
        - name: NODE_ENV
          value: "staging"
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: myapp-secrets
              key: staging-database-url
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "400m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: myapp-staging-service
  namespace: staging
spec:
  selector:
    app: myapp
    environment: staging
  ports:
  - port: 80
    targetPort: 3000
---
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: myapp-staging-route
  namespace: staging
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`myapp-staging.k3s.local`)
      kind: Rule
      services:
        - name: myapp-staging-service
          port: 80
  tls:
    certResolver: letsencrypt
```

## GitLab CI Integration

### .gitlab-ci.yml

```yaml
stages:
  - test
  - build
  - deploy
  - verify

variables:
  DOCKER_DRIVER: overlay2
  DOCKER_TLS_CERTDIR: "/certs"
  KUBECONFIG: /tmp/kube-config

test:
  stage: test
  image: node:18
  script:
    - npm ci
    - npm run test
    - npm run lint
  artifacts:
    reports:
      junit: test-results.xml
      coverage: coverage/cobertura-coverage.xml

build:
  stage: build
  image: docker:20.10.16
  services:
    - docker:20.10.16-dind
  before_script:
    - echo $CI_REGISTRY_PASSWORD | docker login -u $CI_REGISTRY_USER --password-stdin $CI_REGISTRY
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    - docker tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA $CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG

deploy_dev:
  stage: deploy
  image: bitnami/kubectl:1.28
  only:
    - develop
  script:
    - echo $KUBE_CONFIG | base64 -d > $KUBECONFIG
    - export IMAGE_TAG=$CI_COMMIT_SHA
    - envsubst < k8s/deployment-dev.yaml | kubectl apply -f -
    - kubectl rollout status deployment/myapp-dev -n development

deploy_staging:
  stage: deploy
  image: bitnami/kubectl:1.28
  only:
    - main
  script:
    - echo $KUBE_CONFIG | base64 -d > $KUBECONFIG
    - export IMAGE_TAG=$CI_COMMIT_SHA
    - envsubst < k8s/deployment-staging.yaml | kubectl apply -f -
    - kubectl rollout status deployment/myapp-staging -n staging

verify_deployment:
  stage: verify
  image: curlimages/curl:latest
  script:
    - sleep 30
    - curl -f http://myapp-dev.k3s.local/health || exit 1
  only:
    - develop
```

## Jenkins Pipeline

### Jenkinsfile

```groovy
pipeline {
    agent any
    
    environment {
        REGISTRY = 'registry.k3s.local'
        IMAGE_NAME = 'myapp'
        KUBECONFIG = credentials('k3s-kubeconfig')
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Test') {
            parallel {
                stage('Unit Tests') {
                    steps {
                        sh 'npm ci'
                        sh 'npm test'
                    }
                    post {
                        always {
                            publishTestResults testResultsPattern: 'test-results.xml'
                            publishCoverage adapters: [coberturaAdapter('coverage/cobertura-coverage.xml')]
                        }
                    }
                }
                
                stage('Lint') {
                    steps {
                        sh 'npm run lint'
                    }
                }
                
                stage('Security Scan') {
                    steps {
                        sh 'npm audit --audit-level moderate'
                    }
                }
            }
        }
        
        stage('Build') {
            steps {
                script {
                    def image = docker.build("${REGISTRY}/${IMAGE_NAME}:${env.BUILD_ID}")
                    docker.withRegistry("https://${REGISTRY}", 'registry-credentials') {
                        image.push()
                        image.push('latest')
                    }
                }
            }
        }
        
        stage('Deploy to Development') {
            when {
                branch 'develop'
            }
            steps {
                script {
                    sh """
                        export IMAGE_TAG=${env.BUILD_ID}
                        envsubst < k8s/deployment-dev.yaml | kubectl apply -f -
                        kubectl rollout status deployment/myapp-dev -n development
                    """
                }
            }
        }
        
        stage('Deploy to Staging') {
            when {
                branch 'main'
            }
            steps {
                script {
                    sh """
                        export IMAGE_TAG=${env.BUILD_ID}
                        envsubst < k8s/deployment-staging.yaml | kubectl apply -f -
                        kubectl rollout status deployment/myapp-staging -n staging
                    """
                }
            }
        }
        
        stage('Integration Tests') {
            parallel {
                stage('API Tests') {
                    steps {
                        sh 'npm run test:api'
                    }
                }
                
                stage('Load Tests') {
                    steps {
                        sh 'npm run test:load'
                    }
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        
        success {
            slackSend(
                color: 'good',
                message: "✅ Deployment successful: ${env.JOB_NAME} - ${env.BUILD_NUMBER}"
            )
        }
        
        failure {
            slackSend(
                color: 'danger',
                message: "❌ Deployment failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER}"
            )
        }
    }
}
```

## Automated Testing Setup

### Integration Test Suite

```javascript
// tests/integration/deployment.test.js
const axios = require('axios');
const { expect } = require('chai');

describe('Deployment Integration Tests', () => {
    const baseURL = process.env.TEST_URL || 'http://myapp-dev.k3s.local';
    
    before(async () => {
        // Wait for service to be ready
        await waitForService(baseURL);
    });
    
    it('should return healthy status', async () => {
        const response = await axios.get(`${baseURL}/health`);
        expect(response.status).to.equal(200);
        expect(response.data.status).to.equal('healthy');
    });
    
    it('should serve the application', async () => {
        const response = await axios.get(baseURL);
        expect(response.status).to.equal(200);
        expect(response.data).to.include('MyApp');
    });
    
    it('should connect to database', async () => {
        const response = await axios.get(`${baseURL}/api/status`);
        expect(response.status).to.equal(200);
        expect(response.data.database).to.equal('connected');
    });
    
    async function waitForService(url, timeout = 60000) {
        const start = Date.now();
        while (Date.now() - start < timeout) {
            try {
                await axios.get(`${url}/health`);
                return;
            } catch (error) {
                await new Promise(resolve => setTimeout(resolve, 1000));
            }
        }
        throw new Error(`Service not ready after ${timeout}ms`);
    }
});
```

### Load Testing

```yaml
# k6/load-test.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
    stages: [
        { duration: '2m', target: 100 }, // Ramp up
        { duration: '5m', target: 100 }, // Stay at 100 users
        { duration: '2m', target: 200 }, // Ramp up to 200 users
        { duration: '5m', target: 200 }, // Stay at 200 users
        { duration: '2m', target: 0 },   // Ramp down
    ],
    thresholds: {
        http_req_duration: ['p(99)<1500'], // 99% of requests must complete below 1.5s
        http_req_failed: ['rate<0.1'],     // Error rate must be below 10%
    },
};

export default function () {
    const baseURL = __ENV.TEST_URL || 'http://myapp-dev.k3s.local';
    
    let response = http.get(`${baseURL}/api/users`);
    check(response, {
        'status was 200': (r) => r.status == 200,
        'response time OK': (r) => r.timings.duration < 1000,
    });
    
    sleep(1);
    
    response = http.post(`${baseURL}/api/users`, {
        name: 'Test User',
        email: 'test@example.com',
    });
    check(response, {
        'user created': (r) => r.status == 201,
    });
    
    sleep(1);
}
```

## Monitoring CI/CD Pipeline

### Prometheus Metrics for Deployments

```yaml
# monitoring/deployment-metrics.yaml
apiVersion: v1
kind: ServiceMonitor
metadata:
  name: deployment-metrics
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: myapp
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
---
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: deployment-alerts
  namespace: monitoring
spec:
  groups:
  - name: deployment.rules
    rules:
    - alert: DeploymentReplicasNotReady
      expr: kube_deployment_status_replicas_available != kube_deployment_spec_replicas
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Deployment has not enough replicas"
        description: "Deployment {{ $labels.deployment }} in namespace {{ $labels.namespace }} has {{ $value }} replicas available, expected {{ $labels.spec_replicas }}"
    
    - alert: HighPodRestartRate
      expr: rate(kube_pod_container_status_restarts_total[15m]) > 0
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "Pod is restarting frequently"
        description: "Pod {{ $labels.pod }} in namespace {{ $labels.namespace }} is restarting frequently"
```

### Grafana Dashboard for Deployments

```json
{
  "dashboard": {
    "id": null,
    "title": "CI/CD Pipeline Metrics",
    "tags": ["cicd", "deployments"],
    "panels": [
      {
        "title": "Deployment Frequency",
        "type": "stat",
        "targets": [
          {
            "expr": "increase(deployment_total[1d])",
            "legendFormat": "Deployments per day"
          }
        ]
      },
      {
        "title": "Success Rate",
        "type": "stat",
        "targets": [
          {
            "expr": "rate(deployment_success_total[1d]) / rate(deployment_total[1d]) * 100",
            "legendFormat": "Success Rate %"
          }
        ]
      },
      {
        "title": "Mean Time to Recovery",
        "type": "stat",
        "targets": [
          {
            "expr": "avg(deployment_recovery_time_seconds)",
            "legendFormat": "MTTR (seconds)"
          }
        ]
      }
    ]
  }
}
```

## Best Practices

### Security
1. **Use image scanning** in your pipelines
2. **Store secrets securely** (HashiCorp Vault, K8s secrets)
3. **Implement RBAC** for CI/CD service accounts
4. **Sign container images** for integrity

### Performance
1. **Use multi-stage builds** to reduce image size
2. **Implement caching** for dependencies
3. **Parallel pipeline stages** where possible
4. **Resource limits** for CI/CD pods

### Reliability
1. **Implement rollback strategies**
2. **Use blue-green or canary deployments**
3. **Health checks** and readiness probes
4. **Automated testing** at multiple levels

This CI/CD configuration provides a complete pipeline for deploying applications to your K3s environment with proper testing, monitoring, and rollback capabilities.
