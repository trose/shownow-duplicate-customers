public class DuplicateMatcher {

    // Constants for scoring
    private static final Decimal EMAIL_MATCH_SCORE = 50.0;
    private static final Decimal PHONE_MATCH_SCORE = 30.0;
    private static final Decimal NAME_SIMILARITY_SCORE = 20.0;
    private static final Decimal THRESHOLD = 70.0;

    // Method to find duplicates for a list of customers
    public static void findDuplicates(List<Customer__c> newCustomers) {
        if (newCustomers == null || newCustomers.isEmpty()) return;

        Set<String> emails = new Set<String>();
        Set<String> phones = new Set<String>();
        Set<String> names = new Set<String>();

        for (Customer__c cust : newCustomers) {
            if (cust.Email__c != null) emails.add(cust.Email__c.toLowerCase());
            if (cust.Phone__c != null) phones.add(cust.Phone__c);
            if (cust.Name != null) names.add(cust.Name.toLowerCase());
        }

        // Query existing customers
        List<Customer__c> existingCustomers = [
            SELECT Id, Name, Email__c, Phone__c
            FROM Customer__c
            WHERE Email__c IN :emails OR Phone__c IN :phones OR Name IN :names
        ];

        Map<String, List<Customer__c>> emailMap = new Map<String, List<Customer__c>>();
        Map<String, List<Customer__c>> phoneMap = new Map<String, List<Customer__c>>();
        Map<String, List<Customer__c>> nameMap = new Map<String, List<Customer__c>>();

        for (Customer__c cust : existingCustomers) {
            if (cust.Email__c != null) {
                String key = cust.Email__c.toLowerCase();
                if (!emailMap.containsKey(key)) emailMap.put(key, new List<Customer__c>());
                emailMap.get(key).add(cust);
            }
            if (cust.Phone__c != null) {
                if (!phoneMap.containsKey(cust.Phone__c)) phoneMap.put(cust.Phone__c, new List<Customer__c>());
                phoneMap.get(cust.Phone__c).add(cust);
            }
            if (cust.Name != null) {
                String key = cust.Name.toLowerCase();
                if (!nameMap.containsKey(key)) nameMap.put(key, new List<Customer__c>());
                nameMap.get(key).add(cust);
            }
        }

        List<Duplicate_Match__c> matchesToInsert = new List<Duplicate_Match__c>();

        for (Customer__c newCust : newCustomers) {
            Set<Id> potentialDuplicates = new Set<Id>();

            // Find by email
            if (newCust.Email__c != null && emailMap.containsKey(newCust.Email__c.toLowerCase())) {
                for (Customer__c existing : emailMap.get(newCust.Email__c.toLowerCase())) {
                    potentialDuplicates.add(existing.Id);
                }
            }

            // Find by phone
            if (newCust.Phone__c != null && phoneMap.containsKey(newCust.Phone__c)) {
                for (Customer__c existing : phoneMap.get(newCust.Phone__c)) {
                    potentialDuplicates.add(existing.Id);
                }
            }

            // Find by name (exact for simplicity)
            if (newCust.Name != null && nameMap.containsKey(newCust.Name.toLowerCase())) {
                for (Customer__c existing : nameMap.get(newCust.Name.toLowerCase())) {
                    potentialDuplicates.add(existing.Id);
                }
            }

            for (Id dupId : potentialDuplicates) {
                if (dupId == newCust.Id) continue; // Skip self

                Decimal score = calculateScore(newCust, dupId, existingCustomers);

                if (score >= THRESHOLD) {
                    // Check if match already exists
                    if (!matchExists(newCust.Id, dupId)) {
                        Duplicate_Match__c match = new Duplicate_Match__c();
                        match.Customer1__c = newCust.Id;
                        match.Customer2__c = dupId;
                        match.Match_Score__c = score;
                        match.Status__c = 'Pending';
                        matchesToInsert.add(match);
                    }
                }
            }
        }

        if (!matchesToInsert.isEmpty()) {
            insert matchesToInsert;
        }
    }

    private static Decimal calculateScore(Customer__c newCust, Id existingId, List<Customer__c> existingList) {
        Customer__c existing = null;
        for (Customer__c c : existingList) {
            if (c.Id == existingId) {
                existing = c;
                break;
            }
        }
        if (existing == null) return 0;

        Decimal score = 0;
        if (newCust.Email__c != null && existing.Email__c != null && newCust.Email__c.toLowerCase() == existing.Email__c.toLowerCase()) {
            score += EMAIL_MATCH_SCORE;
        }
        if (newCust.Phone__c != null && existing.Phone__c != null && newCust.Phone__c == existing.Phone__c) {
            score += PHONE_MATCH_SCORE;
        }
        if (newCust.Name != null && existing.Name != null && newCust.Name.toLowerCase() == existing.Name.toLowerCase()) {
            score += NAME_SIMILARITY_SCORE;
        }
        return score;
    }

    private static Boolean matchExists(Id cust1, Id cust2) {
        List<Duplicate_Match__c> existingMatches = [
            SELECT Id
            FROM Duplicate_Match__c
            WHERE (Customer1__c = :cust1 AND Customer2__c = :cust2) OR (Customer1__c = :cust2 AND Customer2__c = :cust1)
        ];
        return !existingMatches.isEmpty();
    }

    // Method to process bulk updates or inserts
    public static void processBulk(List<Customer__c> customers) {
        // Call findDuplicates in batches if needed, but for simplicity
        findDuplicates(customers);
    }
}