@RestResource(urlMapping='/duplicate/*')
global class DuplicateRestService {

    @HttpGet
    global static List<DuplicateMatchResponse> getDuplicates() {
        List<Duplicate_Match__c> matches = [
            SELECT Id, Customer1__c, Customer1__r.Name, Customer2__c, Customer2__r.Name, Match_Score__c, Status__c
            FROM Duplicate_Match__c
            WHERE Status__c = 'Pending'
            LIMIT 100
        ];

        List<DuplicateMatchResponse> responses = new List<DuplicateMatchResponse>();
        for (Duplicate_Match__c match : matches) {
            responses.add(new DuplicateMatchResponse(match));
        }
        return responses;
    }

    @HttpPost
    global static String processDuplicate() {
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();
        Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(requestBody);

        Id matchId = (Id) params.get('matchId');
        String action = (String) params.get('action'); // 'confirm' or 'reject'

        if (matchId == null || action == null) {
            return 'Invalid parameters';
        }

        List<Duplicate_Match__c> matches = [SELECT Id, Status__c FROM Duplicate_Match__c WHERE Id = :matchId LIMIT 1];
        if (matches.isEmpty()) {
            return 'Match not found';
        }
        Duplicate_Match__c match = matches[0];

        if (action == 'confirm') {
            match.Status__c = 'Confirmed';
        } else if (action == 'reject') {
            match.Status__c = 'Rejected';
        } else {
            return 'Invalid action';
        }

        update match;

        // Log audit
        Duplicate_Audit__c audit = new Duplicate_Audit__c();
        audit.Action__c = action;
        audit.Timestamp__c = DateTime.now();
        audit.User__c = UserInfo.getUserId();
        audit.Details__c = 'Processed duplicate match ' + matchId + ' with action ' + action;
        insert audit;

        return 'Success';
    }

    @HttpPut
    global static String triggerMatching() {
        // Trigger matching for all customers
        List<Customer__c> allCustomers = [SELECT Id, Name, Email__c, Phone__c FROM Customer__c LIMIT 50000];
        DuplicateMatcher.findDuplicates(allCustomers);
        return 'Matching triggered for ' + allCustomers.size() + ' customers';
    }

    // Inner class for response
    global class DuplicateMatchResponse {
        public Id matchId;
        public Id customer1Id;
        public String customer1Name;
        public Id customer2Id;
        public String customer2Name;
        public Decimal matchScore;
        public String status;

        public DuplicateMatchResponse(Duplicate_Match__c match) {
            this.matchId = match.Id;
            this.customer1Id = match.Customer1__c;
            this.customer1Name = match.Customer1__r.Name;
            this.customer2Id = match.Customer2__c;
            this.customer2Name = match.Customer2__r.Name;
            this.matchScore = match.Match_Score__c;
            this.status = match.Status__c;
        }
    }
}