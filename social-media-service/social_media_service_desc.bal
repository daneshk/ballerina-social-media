import ballerina/http;
import ballerina/sql;
import ballerina/time;

// user representations
type User record {|
    int id;
    string name;
    @sql:Column {name: "birth_date"}
    time:Date birthDate;
    @sql:Column {name: "mobile_number"}
    string mobileNumber;
|};

public type NewUser record {|
    string name;
    time:Date birthDate;
    string mobileNumber;
|};

type RecordCreated record {|
    *http:Created;
    record {
        string message;
    } body;
|};

type RecordNotFound record {|
    *http:NotFound;
    ErrorDetails body;
|};

// post representations
type Post record {|
    int id;
    string description;
    string tags;
    string category;
    @sql:Column {name: "created_date"}
    time:Date created_date;
|};

type PostWithUser record {|
    string name;
    string description;
    string category;
    time:Date created_date;    
|};

public type NewPost record {|
    string description;
    string tags;
    string category;
|};

type BatchCreated record {|
    *http:Created;
    record {
        string[] messages;
    } body;
|};

type ErrorDetails record {|
    time:Utc timeStamp;
    string message;
    string details;
|};
