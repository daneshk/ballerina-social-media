import ballerina/http;
import ballerina/time;

public type NewUser record {|
    string name;
    time:Date birthDate;
    string mobileNumber;
|};

public type NewPost record {|
    string description;
    string tags;
    string category;
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

type PostWithUser record {|
    record {|
        int id;
        string name;   
    |} user;
    string description;
    string category;
    time:Date created_date;    
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
