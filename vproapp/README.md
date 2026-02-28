# vproapp

Java web application (WAR) built with Spring MVC/Security/Data JPA and deployed on Tomcat.

## Tech Stack

- Java 17
- Maven 3.9+
- Spring MVC / Spring Security / Spring Data JPA
- JSP + JSTL
- MySQL
- Memcached
- RabbitMQ
- Elasticsearch

## Project Layout

```text
vproapp/
├── src/                       # application source code
├── Dockerfile                 # multi-stage build (Maven -> Tomcat runtime)
├── docker-compose.yml         # runtime compose file used by deployment
├── cicd/buildspec.yml         # AWS CodeBuild pipeline steps
└── cicd/codedeploy/           # CodeDeploy appspec + scripts
```

## Prerequisites

- JDK 17
- Maven 3.9+
- MySQL 8

## Build

```bash
mvn clean package
```

Build output is generated under `target/` as a WAR file.

## Run With Docker

Build image:

```bash
docker build -t vprofile:local .
```

Run container:

```bash
docker run --rm -p 8080:8080 vprofile:local
```

## Database Setup

Create database:

```sql
CREATE DATABASE accounts;
```

Import seed data:

```bash
mysql -u <user> -p accounts < src/main/resources/db_backup.sql
```

## Tests

```bash
mvn test
```

## CI/CD Notes

- `cicd/buildspec.yml` builds Docker image, pushes to ECR, and creates CodeDeploy deployment artifact.
- `cicd/codedeploy/appspec.yml` defines lifecycle hooks for deployment.
- Deployment scripts are in `cicd/codedeploy/scripts/`.

