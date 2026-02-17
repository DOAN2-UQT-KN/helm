#!/bin/bash
set -e

echo "🚀 Starting DA2 local deployment..."

# Start minikube
echo "📦 Starting Minikube..."
minikube start --cpus=4 --memory=8192 --driver=docker
minikube addons enable ingress

# Build images
echo "🔨 Building Docker images..."
eval $(minikube docker-env)

echo "  Building auth-service..."
cd /home/triuq/projects/DA2/be/services/auth-service
docker build -t auth-service:0.1.0 .

echo "  Building user-service..."
cd /home/triuq/projects/DA2/be/services/user-service
docker build -t user-service:0.1.0 .

# Deploy with Helm
echo "⎈ Deploying with Helm..."
cd /home/triuq/projects/DA2/helm/da2-umbrella
helm dependency update
kubectl create namespace da2-dev --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install da2 . \
  --namespace da2-dev \
  --values values-local.yaml \
  --wait \
  --timeout 10m

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📊 Check status:"
echo "   kubectl get pods -n da2-dev"
echo ""
echo "🔍 Port forward to access services:"
echo "   kubectl port-forward -n da2-dev svc/da2-umbrella-auth-service 3000:3000"
echo "   kubectl port-forward -n da2-dev svc/da2-umbrella-user-service 3001:3001"
echo ""
echo "📝 Run database migrations:"
echo "   kubectl exec -n da2-dev deployment/da2-umbrella-auth-service -- npx prisma migrate deploy"
echo "   kubectl exec -n da2-dev deployment/da2-umbrella-user-service -- npx prisma migrate deploy"
echo ""
echo "🧪 Test signup:"
echo "   curl -X POST http://localhost:3000/auth/signup -H 'Content-Type: application/json' -d '{\"email\":\"test@example.com\",\"password\":\"password123\",\"name\":\"Test User\"}'"
