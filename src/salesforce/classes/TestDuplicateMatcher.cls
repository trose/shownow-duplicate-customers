@isTest
public class TestDuplicateMatcher {

    @TestSetup
    static void makeData() {
        // Create test customers
        List<Customer__c> customers = new List<Customer__c>();
        customers.add(new Customer__c(Name='John Doe', Email__c='john@example.com', Phone__c='1234567890'));
        customers.add(new Customer__c(Name='Jane Doe', Email__c='jane@example.com', Phone__c='0987654321'));
        insert customers;
    }

    @isTest
    static void testFindDuplicates_EmailMatch() {
        // Insert new customer with same email
        Customer__c newCust = new Customer__c(Name='John Smith', Email__c='john@example.com', Phone__c='1111111111');

        Test.startTest();
        insert newCust;
        Test.stopTest();

        // Check if match is created
        List<Duplicate_Match__c> matches = [SELECT Id, Match_Score__c, Status__c FROM Duplicate_Match__c WHERE Customer1__c = :newCust.Id];
        System.assertEquals(1, matches.size());
        System.assertEquals(50.0, matches[0].Match_Score__c);
        System.assertEquals('Pending', matches[0].Status__c);
    }

    @isTest
    static void testFindDuplicates_NoMatch() {
        // Insert new customer with no matches
        Customer__c newCust = new Customer__c(Name='Bob', Email__c='bob@example.com', Phone__c='2222222222');

        Test.startTest();
        insert newCust;
        Test.stopTest();

        List<Duplicate_Match__c> matches = [SELECT Id FROM Duplicate_Match__c WHERE Customer1__c = :newCust.Id];
        System.assertEquals(0, matches.size());
    }

    @isTest
    static void testFindDuplicates_Bulk() {
        List<Customer__c> newCustomers = new List<Customer__c>();
        for (Integer i = 0; i < 200; i++) {
            newCustomers.add(new Customer__c(Name='Test' + i, Email__c='test' + i + '@example.com', Phone__c='333333333' + i));
        }

        Test.startTest();
        insert newCustomers;
        Test.stopTest();

        // Should not create matches since no duplicates
        List<Duplicate_Match__c> matches = [SELECT Id FROM Duplicate_Match__c];
        System.assertEquals(0, matches.size());
    }

    @isTest
    static void testFindDuplicates_MultipleMatches() {
        // Create another customer with same email
        Customer__c existing = [SELECT Id FROM Customer__c WHERE Email__c = 'john@example.com' LIMIT 1];
        Customer__c newCust1 = new Customer__c(Name='John Doe2', Email__c='john@example.com', Phone__c='1234567890');
        Customer__c newCust2 = new Customer__c(Name='John Doe', Email__c='john@example.com', Phone__c='9999999999');

        Test.startTest();
        insert new List<Customer__c>{newCust1, newCust2};
        Test.stopTest();

        // Check matches
        List<Duplicate_Match__c> matches = [SELECT Id FROM Duplicate_Match__c WHERE Customer1__c IN (:newCust1.Id, :newCust2.Id)];
        // Should have matches for each
        System.assert(matches.size() >= 1);
    }
}