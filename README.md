## Node App
The node app is built using the Express framework. We have defined our routes in routes.js. We connect to the DB in db.js. We connect to redis in redis.js. Prometheus configs are in the prometheus/ folder

***/status***
Returns the status of the app. It does this by sending a GET request to localhost port 3000 to ensure node is responding to HTTP GET requests with a 200 status code. 

If the test passes, it reports the app status as Healthy. Otherwise health is reported as Unhealthy.

***/data*** 
The app is an e-commerce application. The POST data sent to this endpoint is a JSON containing product details eg.

    {
      "id": 1,
      "name": "Samsung TV",
      "price": 140
    }

This data is saved in the db.

***/product/:id***
This endpoint allows us to retrieve a product given its ID. /product/1 retrieves a product with an ID of 1. 

AWS Elasticache has been set up. We use the lazy loading caching strategy. We try to retrieve a product first from cache. If the product exists, we return it to the user. In case of a cache miss, we retrieve the product from the AWS RDS database and store it in cache for subsequent requests. The data is stored with a TTL of 1 hour.


## Infrastructure
The infrastructure setup includes.

 - Networking - VPC, Security groups, NAT Gateway etc
 - ECS Fargate Service
 - RDS database
 - Elasticache (Redis)
 - Cloudwatch logGroup - stores application logs
 - R53 DNS name
 - ECR repo
 
## Pipeline
We use Github Actions.

*deploy-app.yml*
It has 2 re-usable workflows.

*build-app.yml* - This builds the app image and pushes it to ECR.
*deploy-infra.yml* - Uses terraform to deploy the infrastructure.


## Prometheus
We use the **prom-client** client library for Node.js to expose the default node metrics to a prometheus server. The prometheus server will scrape the /metrics endpoint every 5s for default Node metrics e.g nodejs_external_memory_bytes

Prometheus server configs are in prometheus/prometheus.yml.
Application configs are in prometheus/prometheus.js.
The /metrics route has been configured in routes.js.

## Design Decisions

 - I used ECS rather than kubernetes because it is easier and faster to set up. ECS is well suited for simple applications. Further more I used the fargate flavour rather than EC2 because AWS takes care of the underlying instance and we dont have to spend time maintaining the underlying OS (patching, OS updates etc).
 - I used redis for caching to ensure that during periods of high load (eg when there is a Sale), users can quickly retrieve products.
 - The fargate tasks as well as the database are in public subnets rather than private subnets which are more secure. This is in order to make troubleshooting easier as private subnets would require setup of a remote access vpn which would take some time.
 - I used terraform modules for ECR, ECS, RDS, VPC and Elasticache. It is faster to set up infra using modules. It also helps standardize infra in our environment.

## Setting up and deploying the application

**Github**
 - Clone this repo and set up your own repo.

**Terraform**

 - Create a workspace in terraform cloud.
 - Create an API token in terraform cloud to be used by Github actions. Add it a repository secret in Github and name it TERRAFORM_CLOUD_TOKEN.
 - Go to the terraform/backend.tf file and update the organization name and workspace name.
 
 *Terraform variables to add (terraform/variables.tf and terraform cloud)* 
 - **AWS_ACCESS_KEY_ID** & **AWS_SECRET_ACCESS_KEY** - Set up an IAM user with admin priviledges. This user will be used by terraform to provision resources. Create 2 environment variables (not terraform variables) in the terraform cloud workspace named AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY and populate them with the IAM key and secret. Mark the variables as sensitive.
 - **certificate_arn** - Add a variable named certificate_arn in terraform cloud. This is the ACM certificate ARN that will be attached to the ALB of the prometheus ECS service as well as the ALB of the app's ECS service.
 - **sns_topic** - contains the ARN of an SNS topic to be used to send notifications from cloudwatch alarms. 
 - **region** - modify the region variable to deploy the infra to a region you want. By default it deploys to eu-west-1.
 - **prometheus_domain_name** - domain name that will be used to access prometheus.

**Pipeline** 
 - We use github actions to first build the app image and then we deploy that image using terraform together with other infra.
 - Go to .github/workflows/deploy-app.yml. Modify the branch that will trigger a deployment to your branch name. On the **build-app-image** job, set your aws region name. Also set the name of the ECR repo. This is constructed by concatenating the env variable in terraform/variables.tf, a hyphen and the service variable set in terraform/variables.tf eg if env is prod and service is node-app, ECR repo name will be prod-node-app. Set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY as repository secrets in Github. On the **deploy-infra** and **deploy-initial-infra** jobs, set terraform_workspace to your workspace name. We have the job deploy-initial-infra so that an ECR repo is created before we push an image in the next job, build-app-image.

**Prometheus** 

 - For prometheus, set your chosen domain name and port in
   prometheus/prometheus.yml under targets.

rate(process_cpu_system_seconds_total[1m])
 

Initialize env variables

    CREATE TABLE Products (
       id INT PRIMARY KEY,
       name VARCHAR(100),
       price DECIMAL(10, 2)
    );


## Testing the app
**Prometheus**
- Go to the domain name configured when setting up the prometheus ECS service eg https://prometheus.rentrahisi.co.ke


