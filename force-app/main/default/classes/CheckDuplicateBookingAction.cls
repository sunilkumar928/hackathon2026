/**
 * @description Agentforce action to check if a customer already has an active test drive booking.
 * @author      Electra Cars
 */
public without sharing class CheckDuplicateBookingAction {

    @InvocableMethod(
        label='Check Duplicate Test Drive'
        description='Checks if there are existing active test drive bookings for a given email or phone.'
        category='Electra Cars – Agentforce'
    )
    public static List<Result> checkDuplicate(List<Request> requests) {
        List<Result> results = new List<Result>();

        for (Request req : requests) {
            Result res = new Result();
            
            // Query for active bookings tied to a Lead with matching Email or Phone
            List<TestDrive__c> duplicates = [
                SELECT Id, Name, Preferred_Date__c, Preferred_Time_Slot__c, 
                       Booking_Status__c, Vehicle__r.Name, Dealership__r.Name
                FROM TestDrive__c
                WHERE (Lead__r.Email = :req.email AND Lead__r.Phone = :req.phone)
                AND Booking_Status__c NOT IN ('Completed', 'Cancelled')
                ORDER BY Preferred_Date__c DESC
            ];

            if (!duplicates.isEmpty()) {
                res.hasDuplicate = true;
                res.duplicateRecords = duplicates;
                res.count = duplicates.size();
            } else {
                res.hasDuplicate = false;
                res.count = 0;
            }
            results.add(res);
        }
        return results;
    }

    public class Request {
        @InvocableVariable(label='Email' required=true) 
        public String email;
        
        @InvocableVariable(label='Phone' required=false) 
        public String phone;
    }

    public class Result {
        @InvocableVariable(label='Has Duplicate') 
        public Boolean hasDuplicate;
        
        @InvocableVariable(label='Duplicate Records') 
        public List<SObject> duplicateRecords;
        
        @InvocableVariable(label='Duplicate Count') 
        public Integer count;
    }
}