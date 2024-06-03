docker build -t tilex ../
docker tag tilex 191982029618.dkr.ecr.us-east-1.amazonaws.com/tilex:latest
docker push 191982029618.dkr.ecr.us-east-1.amazonaws.com/tilex:latest