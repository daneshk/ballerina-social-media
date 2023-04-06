# [Ballerina] Social Media Service

Welcome to this introduction to Ballerina DB connectors. Ballerina has built-in connectors for a set of relational databases like MySQL, Oracle, SQL Server, and PostgreSQL. Ballerina also has jdbc client connector to connect with any relational database. In this video, we'll demonstrate how to use Ballerina to access and manipulate relational databases using the MySQL connector as an example. 

The sample is based on a simple API written for a social-media site (like twitter) which has users, associated posts and followers. The API allows users to register, post, and follow other users. The API is written using Ballerina and uses a MySQL database to store the data.

Following is the entity relationship diagram.

<img src="er.png" alt="drawing" width='700'/>

Following is the service description.

```ballerina
type SocialMedia service object {
    *http:Service;

    // users resource
    resource function get users() returns User[]|error;
    resource function get users/[int id]() returns User|UserNotFound|error;
    resource function post users(@http:Payload NewUser newUser) returns http:Created|error;
    resource function delete users/[int id]() returns http:NoContent|error;

    // posts resource
    resource function get users/[int id]/posts() returns PostMeta[]|UserNotFound|error;
    resource function post users/[int id]/posts(@http:Payload NewPost newPost) returns http:Created|UserNotFound|PostForbidden|error;

    // batch posts resource
    resource function post users/[int id]/posts(@http:Payload NewPost[] newPost) returns http:Created|UserNotFound|PostForbidden|error;

    // insert two users and add follwer resource
    

};
```

Following are the features covered by the scenario.

1. RBMS Data Access and Manipulation
2. Batch Operations and Stored Procedures
3. Transaction Handling
4. Persistence support for Ballerina data types

# Tutorial Steps

1. [Setup the environment](#setup-the-environment)

Setting up the environment for the Ballerina DB connectors, including the database and the Ballerina project. For this scenario, we will use MySQL as the database. you either can use the docker image or install the MySQL server locally.

Once you have the database up and running, you can create the database and the required tables using the SQL script below.

```sql


# Setup each environment

You can use the below docker compose commands.
1. docker compose up

# Try out
- To send request open `social-media-request.http` file using VS Code with `REST Client` extension
