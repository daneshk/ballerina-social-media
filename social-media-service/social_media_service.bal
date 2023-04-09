import ballerina/http;
import ballerina/log;
import ballerina/time;
import ballerina/random;
import ballerina/persist;

final Client socialMediaDb;
function initDbClient() returns Client|error => new ();


service /social\-media on new http:Listener(9090) {

    public function init() returns error? {
        socialMediaDb = check initDbClient();
        log:printInfo("Social media service started");
    }

    # Get all the users
    #
    # + return - The list of users or error message
    resource function get users() returns User[]|error {
        stream<User, persist:Error?> userStream = socialMediaDb->/users();
        return from User user in userStream
            select user;
    }

    # Get a specific user
    #
    # + id - The user ID of the user to be retrived
    # + return - A specific user or error message
    resource function get users/[int id]() returns User|RecordNotFound|error {
        User|error result = socialMediaDb->/users/[id];
        if result is persist:InvalidKeyError {
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
        UserInsert user = {
            id: check random:createIntInRange(1, 1000000),
            birthDate: newUser.birthDate,
            name: newUser.name,
            mobileNumber: newUser.mobileNumber
        };
        int[] userInsert = check socialMediaDb->/users.post([user]);
        return {
            body: { message: string `user created: ${userInsert[0]}` }
        };
    }

    resource function post users/batch(@http:Payload NewUser[] newUsers) returns BatchCreated|error {
        UserInsert[] users = from NewUser newUser in newUsers
            select {
                id: check random:createIntInRange(1, 1000000),
                birthDate: newUser.birthDate,
                name: newUser.name,
                mobileNumber: newUser.mobileNumber
            };
        int[] userInsert = check socialMediaDb->/users.post(users);

        string[] messages = from int id in userInsert
            select string `user created: ${id}`;

        return {
            body: { messages: messages }
        };
    }

    # Delete a user
    #
    # + id - The user ID of the user to be deleted
    # + return - The success message or error message
    resource function delete users/[int id]() returns http:NoContent|RecordNotFound|error {
        _ = check socialMediaDb->/users/[id].delete();
        return http:NO_CONTENT;
    }

    # Get posts for a give user
    #
    # + id - The user ID for which posts are retrieved
    # + return - A list of posts or error message
    resource function get users/[int id]/posts() returns PostWithUser[]|RecordNotFound|error {                                                                                                                                                                                                                 
        stream<PostWithUser, persist:Error?> resultStream = socialMediaDb->/posts();

        PostWithUser[] posts = check from PostWithUser post in resultStream
            where post.user.id == id
            select post;
        
        if posts.length() == 0 {
            ErrorDetails errorDetails = buildErrorPayload(string `No posts found for userId: ${id}`, string `users/${id}/posts`);
            RecordNotFound userNotFound = {
                body: errorDetails
            };
            return userNotFound;
        }
        return posts;
    }

    # Create a post for a given user
    #
    # + id - The user ID for which the post is created
    # + return - The created message or error message
    resource function post users/[int id]/posts(@http:Payload NewPost newPost) returns http:Created|RecordNotFound|error {
        User|error user = socialMediaDb->/users/[id];
        if user is persist:InvalidKeyError {
            ErrorDetails errorDetails = buildErrorPayload(string `id: ${id}`, string `users/${id}/posts`);
            RecordNotFound userNotFound = {
                body: errorDetails
            };
            return userNotFound;
        }
        if user is error {
            return user;
        }

        PostInsert post = {
            id: check random:createIntInRange(1, 1000000),
            description: newPost.description,
            category: newPost.category,
            created_date: time:utcToCivil(time:utcNow()),
            tags: newPost.tags,
            userId: id
        };
        int[] postInsert = check socialMediaDb->/posts.post([post]);
        return {
            body: { message: string `post created: ${postInsert[0]}` }
        };
    }

    // Add new follower to a user identified by the given ID
    resource function post users/[int id]/followers(@http:Payload NewUser newFollower) returns RecordCreated|error {
        UserInsert user = {
            id: check random:createIntInRange(1, 1000000),
            birthDate: newFollower.birthDate,
            name: newFollower.name,
            mobileNumber: newFollower.mobileNumber
        };
        transaction {
            int[] userInsert = check socialMediaDb->/users.post([user]);
            
            int[] followerInsert = check socialMediaDb->/follows.post([{
                id: check random:createIntInRange(1, 1000000),
                followerId: userInsert[0],
                leaderId: id,
                created_date: time:utcToCivil(time:utcNow())
            }]); 

            check commit;
            return {
                body: { message: string `follower created: ${followerInsert[0]}` }
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
