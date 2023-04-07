import ballerina/http;
import ballerina/log;
import ballerina/sql;
import ballerina/time;
import ballerinax/mysql.driver as _;
import ballerinax/mysql;

type DataBaseConfig record {|
    string host;
    int port;
    string user;
    string password;
    string database;
|};
configurable DataBaseConfig databaseConfig = ?;
final mysql:Client socialMediaDb;
function initDbClient() returns mysql:Client|error => new (...databaseConfig);


service /social\-media on new http:Listener(9090) {

    public function init() returns error? {
        socialMediaDb = check initDbClient();
        log:printInfo("Social media service started");
    }

    # Get all the users
    #
    # + return - The list of users or error message
    resource function get users() returns User[]|error {
        stream<User, sql:Error?> userStream = socialMediaDb->query(`SELECT * FROM users`);
        return from User user in userStream
            select user;
    }

    # Get a specific user
    #
    # + id - The user ID of the user to be retrived
    # + return - A specific user or error message
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

    # Create a new user
    #
    # + newUser - The user details of the new user
    # + return - The created message or error message
    resource function post users(@http:Payload NewUser newUser) returns RecordCreated|error {
        sql:ExecutionResult userInsert = check socialMediaDb->execute(`
            INSERT INTO users(birth_date, name, mobile_number)
            VALUES (${newUser.birthDate}, ${newUser.name}, ${newUser.mobileNumber})`);
        return {
            body: { message: string `user created: ${userInsert.lastInsertId.toString()}` }
        };
    }

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

    # Delete a user
    #
    # + id - The user ID of the user to be deleted
    # + return - The success message or error message
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

    # Get posts for a give user
    #
    # + id - The user ID for which posts are retrieved
    # + return - A list of posts or error message
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

    # Create a post for a given user
    #
    # + id - The user ID for which the post is created
    # + return - The created message or error message
    resource function post users/[int id]/posts(@http:Payload NewPost newPost) returns http:Created|RecordNotFound|error {
        User|error user = socialMediaDb->queryRow(`SELECT * FROM users WHERE id = ${id}`);
        if user is sql:NoRowsError {
            ErrorDetails errorDetails = buildErrorPayload(string `id: ${id}`, string `users/${id}/posts`);
            RecordNotFound userNotFound = {
                body: errorDetails
            };
            return userNotFound;
        }
        if user is error {
            return user;
        }

        sql:ExecutionResult postInsert = check socialMediaDb->execute(`
            INSERT INTO posts(description, category, created_date, tags, user_id)
            VALUES (${newPost.description}, ${newPost.category}, CURDATE(), ${newPost.tags}, ${id});`);
        return {
            body: { message: "post created: " + postInsert.lastInsertId.toString() }
        };
    }

    // Add new follower to a user identified by the given ID
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
}

function buildErrorPayload(string msg, string path) returns ErrorDetails => {
    message: msg,
    timeStamp: time:utcNow(),
    details: string `uri=${path}`
};
