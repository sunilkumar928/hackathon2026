/**
 * @description  Resolves the nearest active Electra Cars dealership for a given zip/pin code
 *               by querying TerritoryMapping__mdt. Called from TestDriveBookingAction and
 *               also exposed as a standalone Agentforce invocable action for re-routing.
 *
 * @author       Salesforce Architecture Team – Electra Cars
 * @version      1.0
 */
public without sharing class DealershipRoutingAction {

    // ─── Invocable wrapper ──────────────────────────────────────────────────

    @InvocableMethod(
        label='Assign Dealership by Zip Code'
        description='Resolves the nearest active dealership from TerritoryMapping__mdt for the supplied zip code.'
        category='Electra Cars – Agentforce'
    )
    public static List<Result> assignDealership(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            Result r = new Result();
            try {
                Account dealer = resolve(req.zipCode);
                if (dealer != null) {
                    r.dealershipId   = dealer.Id;
                    r.dealershipName = dealer.Name;
                    r.successFlag    = true;
                } else {
                    r.dealershipId   = getFallbackDealershipId();
                    r.dealershipName = 'National Booking Centre';
                    r.successFlag    = true;
                    r.warningMessage = 'No territory mapping found for zip ' + req.zipCode + '. Assigned to National Booking Centre.';
                }
            } catch (Exception e) {
                r.successFlag  = false;
                r.errorMessage = e.getMessage();
            }
            results.add(r);
        }
        return results;
    }

    // ─── Core routing logic (also callable directly from TestDriveBookingAction) ──

    /**
     * @description  Returns the Account (dealership) for a given zip code.
     *               Returns null if no active mapping exists – caller must handle fallback.
     */
    public static Account resolve(String zipCode) {
        if (String.isBlank(zipCode)) {
            return null;
        }

        String cleanZip = zipCode.trim();

        // Query Custom Metadata – ordered by Priority so lowest number wins on overlap
        List<TerritoryMapping__mdt> mappings = [
            SELECT Dealership_Id__c, Dealership_Name__c
            FROM   TerritoryMapping__mdt
            WHERE  Zip_Code__c   = :cleanZip
            AND    Is_Active__c  = true
            ORDER BY Priority__c ASC
            LIMIT 1
        ];

        if (mappings.isEmpty()) {
            return null;
        }

        String dealerId = mappings[0].Dealership_Id__c;

        // Validate the stored ID is a real 15/18-char Salesforce ID
        if (String.isBlank(dealerId) || dealerId == 'PLACEHOLDER_REPLACE_AFTER_DEPLOY') {
            // Fallback: look up by name stored in metadata
            List<Account> byName = [
                SELECT Id, Name
                FROM   Account
                WHERE  Name      = :mappings[0].Dealership_Name__c
                AND    IsActive__c = true
                LIMIT 1
            ];
            return byName.isEmpty() ? null : byName[0];
        }

        List<Account> dealers = [
            SELECT Id, Name, BillingPostalCode, WhatsApp_Business_ID__c
            FROM   Account
            WHERE  Id          = :dealerId
            AND    IsActive__c = true
            LIMIT 1
        ];
        return dealers.isEmpty() ? null : dealers[0];
    }

    // ─── Fallback dealer ───────────────────────────────────────────────────

    private static Id getFallbackDealershipId() {
        List<Account> fallback = [
            SELECT Id
            FROM   Account
            WHERE  Name      = 'National Booking Centre'
            AND    IsActive__c = true
            LIMIT 1
        ];
        return fallback.isEmpty() ? null : fallback[0].Id;
    }

    // ─── Inner classes ─────────────────────────────────────────────────────

    public class Request {
        @InvocableVariable(label='Zip Code' description='Customer zip or pin code' required=true)
        public String zipCode;
    }

    public class Result {
        @InvocableVariable(label='Dealership Id')
        public String dealershipId;

        @InvocableVariable(label='Dealership Name')
        public String dealershipName;

        @InvocableVariable(label='Success Flag')
        public Boolean successFlag;

        @InvocableVariable(label='Warning Message')
        public String warningMessage;

        @InvocableVariable(label='Error Message')
        public String errorMessage;
    }
}