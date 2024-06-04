GOOGLE_SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id GoogleKeys --region us-east-1)

kubectl create secret generic google-secrets \
    --from-literal=client-id=$(echo $GOOGLE_SECRET_JSON | jq -r '(.SecretString | fromjson).GOOGLE_CLIENT_ID') \
    --from-literal=client-secret=$(echo $GOOGLE_SECRET_JSON | jq -r '(.SecretString | fromjson).GOOGLE_CLIENT_SECRET')

DB_JSON=$(aws rds describe-db-instances --region us-east-1 --db-instance-identifier tilex-db)
DB_PASS_ARN=$(echo $DB_JSON | jq -r '.DBInstances[0].MasterUserSecret.SecretArn')
DB_PASS_JSON=$(aws secretsmanager get-secret-value --secret-id $DB_PASS_ARN --region us-east-1 )

kubectl create secret generic db-secrets \
    --from-literal=address=$(echo $DB_JSON | jq -r '.DBInstances[0].Endpoint.Address') \
    --from-literal=username=$(echo $DB_PASS_JSON | jq -r '(.SecretString | fromjson).username') \
    --from-literal=password=$(echo $DB_PASS_JSON | jq -r '(.SecretString | fromjson).password')