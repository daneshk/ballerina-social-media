import ballerina/test;
import ballerina/http;

@test:Mock {
    functionName: "initDbClient"
}
function mockInitDbClient() returns Client|error {
    return test:mock(Client);
}

@test:Config{}
public function testSentimentAnalysis() returns error? {
    User userExpected = { id: 999, name: "foo", birthDate: {year: 0, month: 0, day: 0}, mobileNumber: "1234567890"};
    test:prepare(socialMediaDb).when("queryRow").thenReturn(userExpected);

    http:Client socialMediaEndpoint = check new("localhost:9090/social-media");
    User userActual = check socialMediaEndpoint->/users/[userExpected.id.toString()];

    test:assertEquals(userActual, userExpected);
}