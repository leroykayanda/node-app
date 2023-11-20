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

 - Networking - VPC, Security groups, Internet Gateway etc
 - ECS Fargate Service
 - RDS database
 - Elasticache (Redis)
 - Cloudwatch logGroup - stores application logs i.e whatever is sent to STDOUT using console.log
 - R53 DNS name
 - ECR repo
 
## Pipeline
We use Github Actions.

*deploy-app.yml*
It has 3 re-usable workflows.

*deploy-initial-infra* - This sets up ECR repos for the application and prometheus images
*build-app.yml* - This builds the app and prometheus images and pushes them to ECR.
*deploy-infra.yml* - Uses terraform to deploy the infrastructure.


## Prometheus
We use the **prom-client** client library for Node.js to expose the default node metrics to a prometheus server. The prometheus server will scrape the /metrics endpoint every 5s for default Node metrics e.g nodejs_external_memory_bytes

Prometheus server configs are in prometheus/prometheus.yml.
Application configs are in prometheus/prometheus.js.
The /metrics route has been configured in routes.js.

## Design Decisions

 - I used ECS rather than kubernetes because it is easier and faster to set up. ECS is well suited for simple applications. Further more I used the fargate flavour rather than EC2 because AWS takes care of the underlying instance and we dont have to spend time maintaining the underlying OS (patching, OS updates etc).
 - I used redis for caching to ensure that during periods of high load (eg when there is a Sale), users can quickly retrieve products.
 - The database is in a public subnet rather than a private one which is more secure. This is in order to make troubleshooting easier as private subnets would require setup of a remote access vpn which would take some time.
 - I used terraform modules for ECR, ECS, RDS, VPC and Elasticache. It is faster to set up infra using modules. It also helps standardize infra in our environment. The modules are stored in the modules/ folder.

## Setting up and deploying the application

**Github**
 - Clone this repo and set up your own repo.

**Terraform**

 - Create a workspace in terraform cloud.
 - Create an API token in terraform cloud to be used by Github actions. Add it a repository secret in Github and name it TERRAFORM_CLOUD_TOKEN.
 - Go to the terraform/backend.tf file and update the organization name and workspace name.
 
 *Terraform variables to add/modify (terraform/variables.tf or terraform cloud for sensitive variables)* 
 - **AWS_ACCESS_KEY_ID** & **AWS_SECRET_ACCESS_KEY** *(terraform cloud)* - Set up an IAM user with admin priviledges. This user will be used by terraform to provision resources. Create 2 environment variables (not terraform variables) in the terraform cloud workspace named AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY and populate them with the IAM key and secret. Mark the variables as sensitive.
 - **certificate_arn** *(terraform cloud)* - Add a variable named certificate_arn in terraform cloud. This is the ACM certificate ARN that will be attached to the ALB of the prometheus ECS service as well as the ALB of the app's ECS service.
 - **sns_topic** *(terraform cloud)* - contains the ARN of an SNS topic to be used to send notifications from cloudwatch alarms. 
 - **region** *(terraform/variables.tf)* - modify the region variable to deploy the infra to a region you want. By default it deploys to eu-west-1.
 - **prometheus_domain_name** *(terraform/variables.tf)* - domain name that will be used to access prometheus.
 - **db_username** *(terraform cloud)*
 - **db_password** *(terraform cloud)*
 - **domain_name** *(terraform/variables.tf)* - domain name that will be used to access the application.

**Pipeline** 
 - We use github actions to first build the app image and then we deploy that image using terraform together with other infra.
 - Go to .github/workflows/deploy-app.yml. Modify the branch that will trigger a deployment to your branch name. On the **build-app-image** job, set your aws region name. Also set the name of the ECR repo. This is constructed by concatenating the env variable in terraform/variables.tf, a hyphen and the service variable set in terraform/variables.tf eg if env is prod and service is node-app, ECR repo name will be prod-node-app. Set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY as repository secrets in Github. On the **deploy-infra** and **deploy-initial-infra** jobs, set terraform_workspace to your workspace name. We have the job deploy-initial-infra so that an ECR repo is created first before we push an image in the next job, build-app-image.

**Prometheus** 

 - For prometheus, set your chosen domain name and port in
   prometheus/prometheus.yml under targets.

**RDS**
Once the database has been created, log in and create the table below.

    CREATE TABLE Products (
       id INT PRIMARY KEY,
       name VARCHAR(100),
       price DECIMAL(10, 2)
    );


## Testing the app
**Go to */status***
You should see: App Status: HEALTHY

**Senda JSON payload to */data***
Send the payload below to the chosen domain name via curl or postman

    {
      "id": 1,
      "name": "Samsung TV",
      "price": 140
    }

curl -X POST -H "Content-Type: application/json" -d '{"id": 1, "name": "Samsung TV", "price": 140}' https://shop.rentrahisi.co.ke/data

Log in to the db and verify the data is there

    SELECT * FROM abc.Products;

***Send a GET request to /product/1***
You should get the data below

    curl https://shop.rentrahisi.co.ke/product/1
    {"id":1,"name":"Samsung TV","price":140}

Verify the data has been added to Redis by logging into redis-cli and executing the cmd below

    get 1
    "{\"id\":1,\"name\":\"Samsung TV\",\"price\":140}"

Verify TTL was set 

    ttl 1
    (integer) 3499

If you run the GET request again, cloudwatch logs should show that the product was retrieved from redis.

    Product with ID 1 has been stored in Redis
    Product with ID 1 has been retrieved from the DB
    Product with ID 1 found in Redis

**Prometheus**
- Go to the domain name configured when setting up the prometheus ECS service eg https://prometheus.rentrahisi.co.ke
- Run this PromQL query **rate(process_cpu_system_seconds_total[1m])**
- You should see a line graph with some data.