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
SQL script: https://github.com/daneshk/ballerina-social-media/blob/db-tutorial/db-setup/init.sql
```

Next you can create the Ballerina project. You can use the below commands to create the project.

```bash
bal new social-media
```

Next is to initialize the DB Client by passing the MySQL DB configurations. First we create a configurable variable and read configurations from the Config.toml file. Those variables are passed to the mysql client init method.

```ballerina
type DataBaseConfig record {|
   string host;
   int port;
   string user;
   string password;
   string database;
|};
configurable DataBaseConfig databaseConfig = ?;

mysql:Client socialMediaDb = new (...databaseConfig);
```

We can use the initialized client rest of our application, Let’s start implementing the service resource functions for basic CRUD operations.

2. [Implementing the service resource functions](#implementing-the-service-resource-functions)

We can implement the service resource functions for basic CRUD operations. Let's start with the get method of `users` resource. We can use the below code to implement the get method of `users` resource.

```ballerina
    resource function get users() returns User[]|error {
        stream<User, sql:Error?> userStream = socialMediaDb->query(`SELECT * FROM users`);
        return from User user in userStream
            select user;
    }
```

Here we are using the `query` operation of the mysql client to execute the query and get the result as a stream. Then we are using the `from` clause to iterate the stream and get the result as an array.

If you want to get the result as a single record, you can use the `queryRow` operation of the mysql client. Let's see how to use the `queryRow` operation to implement the get method of `users/[int id]` resource.

```ballerina
    resource function get users/[int id]() returns User|RecordNotFound|error {
        User|error result = socialMediaDb->queryRow(`SELECT * FROM users WHERE ID = ${id}`);
        if result is sql:NoRowsError {
            ErrorDetails errorDetails = buildErrorPayload(string `id: ${id}`, string `users/${id}`);
            RecordNotFound userNotFound = {
                body: errorDetails
            };
            return userNotFound;
        } else {
            return result;
        }
    }
```

Here we are using the `queryRow` operation of the mysql client to execute the query and get the result as a single record. If there is no record found for the given id, we get a `sql:NoRowsError` error. We can use the `if` condition to check the error type and return a custom error payload.

Let's see how to use the `execute` operation to implement the post method of `users` resource.

```ballerina
    resource function post users(@http:Payload NewUser newUser) returns RecordCreated|error {
        sql:ExecutionResult userInsert = check socialMediaDb->execute(`
            INSERT INTO users(birth_date, name, mobile_number)
            VALUES (${newUser.birthDate}, ${newUser.name}, ${newUser.mobileNumber})`);
        return {
            body: { message: string `user created: ${userInsert.lastInsertId.toString()}` }
        };
    }
```

Here we are using the `execute` operation of the mysql client to execute the query and get the result as an `sql:ExecutionResult` record. We can use the `lastInsertId` field of the `sql:ExecutionResult` record to get the id of the newly created record. The `lastInsertId` field is onlt applicable when we are inserting a record to a table with an auto-incremented primary key. otherwise it is nil value.

Once we successfully created the user, we return HTTP 201 Created response with a custom payload. The custom payload is a record with a single field `message` of type string. We can use the `check` keyword to handle the error returned by the `execute` operation. it will return Internal Server Error response with the error details.

Let's see how to use the `execute` operation to implement the delete method of `users/[int id]` resource.

```ballerina
    resource function delete users/[int id]() returns http:NoContent|RecordNotFound|error {
        sql:ExecutionResult userDelete = check socialMediaDb->execute(`
            DELETE FROM users WHERE ID = ${id}`);
        if userDelete.affectedRowCount == 0 {
            ErrorDetails errorDetails = buildErrorPayload(string `id: ${id}`, string `users/${id}`);
            RecordNotFound userNotFound = {
                body: errorDetails
            };
            return userNotFound;
        } else {
            return http:NO_CONTENT;
        }
    }
```

Here we are using the `execute` operation of the mysql client to execute the query and get the result as an `sql:ExecutionResult` record. We can use the `affectedRowCount` field of the `sql:ExecutionResult` record to get the number of records affected by the query. If the `affectedRowCount` is 0, we can assume that there is no record found for the given id. Otherwise we return HTTP 204 No Content response.

Same like create and delete operations, we can implement the put method of `users/[int id]` resource. In this tutorial, we are not going to implement the put method of `users/[int id]` resource. You can follow the same approach as we did for the post method of `users` resource.

Next we are going to implement the batch operations. Let's see how to use the `batchExecute` operation to implement batch insert operation of users.

3. [Implementing the batch operations](#implementing-the-batch-operations)

We can implement the batch operations using the `batchExecute` operation of the mysql client. Let's see how to use the `batchExecute` operation to implement batch insert operation of users. We can use the below code to implement the post method of `users/batch` resource.

```ballerina
    resource function post users/batch(@http:Payload NewUser[] newUsers) returns BatchCreated|error {
        // Create a batch parameterized query.
        sql:ParameterizedQuery[] insertQueries = from NewUser newUser in newUsers
            select `INSERT INTO users(birth_date, name, mobile_number)
                    VALUES (${newUser.birthDate}, ${newUser.name}, ${newUser.mobileNumber})`; 
        sql:ExecutionResult[] batchResult = check socialMediaDb->batchExecute(insertQueries);

        string[] messages = from sql:ExecutionResult result in batchResult
            select string `user created: ${result.lastInsertId.toString()}`;

        return {
            body: { messages: messages }
        };
    }
```

Here we are using the `from` clause to iterate the `newUsers` array and create a batch parameterized query. Then we are using the `batchExecute` operation of the mysql client to execute the batch query and get the result as an array of `sql:ExecutionResult` records. We can use the `lastInsertId` field of the `sql:ExecutionResult` record to get the id of the newly created record. Then we are using the `from` clause to iterate the `batchResult` array and create a custom payload.

Next we are going to implement the stored procedures. Let's see how to use the `call` operation to implement the get method of `users/[int id]/posts` resource.



4. [Implementing the stored procedures](#implementing-the-stored-procedures)

We can implement the stored procedures using the `call` operation of the mysql client. Let's see how to use the `call` operation to implement the get method of `users/[int id]/posts` resource.

```ballerina
    resource function get users/[int id]/posts() returns PostWithUser[]|RecordNotFound|error {
        sql:IntegerOutParameter postsCount = new;                                                                                                                                                                                                                 
        sql:ProcedureCallResult callResults = check socialMediaDb->call(`call get_posts_for_user(${id}, ${postsCount})`, [PostWithUser]);
        if postsCount.get(int) == 0 {
            ErrorDetails errorDetails = buildErrorPayload(string `No posts found for userId: ${id}`, string `users/${id}/posts`);
            RecordNotFound userNotFound = {
                body: errorDetails
            };
            return userNotFound;
        }
        stream<PostWithUser, sql:Error?> queryResult = <stream<PostWithUser, sql:Error?>>callResults.queryResult;
        PostWithUser[] postWithUser = check from PostWithUser post in queryResult
            select post;
        check callResults.close();
        return postWithUser;
    }
```

Here we are using the `call` operation of the mysql client to execute the stored procedure and get the result as an `sql:ProcedureCallResult` record. We are passing the userId as IN parameter and the postsCount as OUT parameter. The `PostWithUser` record is to map the result of the query in the stored procedure. We can use the `get` method of the `sql:IntegerOutParameter` record to get the value of the OUT parameter. If the `postsCount` is 0, we can assume that there is no post found for the given user id. Otherwise we return the result as an array of `PostWithUser` records. We can use the `from` clause to iterate the `queryResult` stream and create an array of `PostWithUser` records. Then we should call the `close` method of the `sql:ProcedureCallResult` record to close the operation and release the connection resources to the pool.

Till now we have implemented the CRUD operations and batch operations. Next we are going to implement the transactions.

5. [Implementing the transactions](#implementing-the-transactions)

Let's see how to use the `transaction` operation to implement the post method of `users/[int id]/followers` resource.

```ballerina
    resource function post users/[int id]/followers(@http:Payload NewUser newFollower) returns RecordCreated|error {
        transaction {
            sql:ExecutionResult userInsert = check socialMediaDb->execute(`
                INSERT INTO users(birth_date, name, mobile_number)
                VALUES (${newFollower.birthDate}, ${newFollower.name}, ${newFollower.mobileNumber})`);
            
            sql:ExecutionResult followerInsert = check socialMediaDb->execute(`
                INSERT INTO followers(follower_id, leader_id)
                VALUES (${userInsert.lastInsertId}, ${id})`); 

            check commit;
            return {
                body: { message: "follower created: " + followerInsert.lastInsertId.toString() }
            };                    
        } on fail error e {
            // In case of error, the transaction block is rolled back automatically.
            return e;
        }
    }
```

Here we are using the `transaction` operation of the mysql client to execute the transaction. We can use the `commit` statement to commit the transaction. If there is an error, the transaction block is rolled back automatically. Then we can use the `on fail` clause to handle the error.

So we covered all the CRUD operations, batch operations, how to call stored procedures, and how to use transactions. Now we are going to discuss the best practices you should follow when using the mysql client to use it effectively in your application.

# Setup each environment

You can use the below docker compose commands.
1. docker compose up

# Try out
- To send request open `social-media-request.http` file using VS Code with `REST Client` extension
