# NOTE: UNDER CONSTRUCTION

# Portfolio Description
explanation of the architecture of my portfolio website and instructions for how to set it upp locally

## Backend Architecture
The backend is running on a k3s kubernetes cluster and uses cilium for observabillity and networking. The cluster also uses helm for managing deployments and pulls custom charts from a custom [helm chart repository](https://github.com/nelsonJanusson/portfolio_chart_repo). 
The backend uses postgress as a database and deploys/manages said database using the [CloudNativePG](https://cloudnative-pg.io/) platform.
The backend microservices are written using the springboot framework and kotlin language. The complete list of microservices are as follows:  
- [Project Service](https://github.com/nelsonJanusson/portfolio_project_service)

All the custom images required to run the application can be found at in this [dockerhub container registry](https://hub.docker.com/repository/docker/nelsonjanusson/portfolio_project/general).

## Frontend Architecture
[Frontend](https://github.com/nelsonJanusson/portfolio_frontend)

## Setup guide
Running the deploy.sh script in this repository will automatically start the application on your local system, note that the script was developed for linux and might not work for other operating systems.
To fetch and execute the script you can run the following command:
```console
curl https://raw.githubusercontent.com/nelsonJanusson/portfolio_description/refs/heads/main/deploy.sh | bash
```
