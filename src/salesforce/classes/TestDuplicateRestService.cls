@isTest
public class TestDuplicateRestService {

    @TestSetup
    static void makeData() {
        List<Customer__c> customers = new List<Customer__c>();
        customers.add(new Customer__c(Name='John Doe', Email__c='john@example.com'));
        customers.add(new Customer__c(Name='Jane Doe', Email__c='jane@example.com'));
        insert customers;

        // Create a match
        Duplicate_Match__c match = new Duplicate_Match__c(Customer1__c=customers[0].Id, Customer2__c=customers[1].Id, Match_Score__c=80.0, Status__c='Pending');
        insert match;
    }

    @isTest
    static void testGetDuplicates() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/duplicate/';
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        List<DuplicateRestService.DuplicateMatchResponse> responses = DuplicateRestService.getDuplicates();
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals('Pending', responses[0].status);
    }

    @isTest
    static void testProcessDuplicate_Confirm() {
        Duplicate_Match__c match = [SELECT Id FROM Duplicate_Match__c LIMIT 1];

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/duplicate/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"matchId":"' + match.Id + '","action":"confirm"}');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        String result = DuplicateRestService.processDuplicate();
        Test.stopTest();

        System.assertEquals('Success', result);
        match = [SELECT Status__c FROM Duplicate_Match__c WHERE Id = :match.Id];
        System.assertEquals('Confirmed', match.Status__c);

        List<Duplicate_Audit__c> audits = [SELECT Id FROM Duplicate_Audit__c];
        System.assertEquals(1, audits.size());
    }

    @isTest
    static void testProcessDuplicate_Reject() {
        Duplicate_Match__c match = [SELECT Id FROM Duplicate_Match__c LIMIT 1];

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/duplicate/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"matchId":"' + match.Id + '","action":"reject"}');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        String result = DuplicateRestService.processDuplicate();
        Test.stopTest();

        System.assertEquals('Success', result);
        match = [SELECT Status__c FROM Duplicate_Match__c WHERE Id = :match.Id];
        System.assertEquals('Rejected', match.Status__c);
    }

    @isTest
    static void testTriggerMatching() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/duplicate/';
        req.httpMethod = 'PUT';
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        String result = DuplicateRestService.triggerMatching();
        Test.stopTest();

        System.assert(result.contains('Matching triggered'));
    }

    @isTest
    static void testProcessDuplicate_InvalidAction() {
        Duplicate_Match__c match = [SELECT Id FROM Duplicate_Match__c LIMIT 1];

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/duplicate/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"matchId":"' + match.Id + '","action":"invalid"}');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        String result = DuplicateRestService.processDuplicate();
        Test.stopTest();

        System.assertEquals('Invalid action', result);
    }
}