REPOSITORY_NAME="monitoring/newrelic/redshift"
AWS_PROFILE=$1

ACCOUNT_ID=`aws sts get-caller-identity --output text --query 'Account' --profile $AWS_PROFILE `


bash -c "`aws ecr get-login --no-include-email --region us-east-1 --profile $AWS_PROFILE `"
docker build -t newrelic_redshift_plugin .
docker tag newrelic_redshift_plugin:latest ${ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/$REPOSITORY_NAME:latest
aws ecr describe-repositories --repository-names $REPOSITORY_NAME --region us-east-1  --profile $AWS_PROFILE 
if [[ ! $? == 0 ]]; then
  aws ecr create-repository --repository-name $REPOSITORY_NAME --region us-east-1 --profile $AWS_PROFILE 
fi
docker push ${ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/$REPOSITORY_NAME:latest
