/**
 * @description  Agentforce invocable action that atomically:
 *               1. Upserts a Lead (by Email)
 *               2. Resolves the nearest dealership via DealershipRoutingAction
 *               3. Creates a TestDrive__c record
 *               4. Creates an AgentConversation__c audit record
 *
 *               Called from an Autolaunched Flow triggered by Agentforce after
 *               Collect_Booking_Details action completes slot-filling.
 *
 * @author       Salesforce Architecture Team – Electra Cars
 * @version      1.0
 */
public without sharing class TestDriveBookingAction {
    private static final String SUMMARY = 'Summary';
    private static final String DOT_PDF = '.pdf';

    // ─── Invocable entry point ─────────────────────────────────────────────

    @InvocableMethod(
        label='Create Test Drive Booking'
        description='Creates Lead and TestDrive__c from Agentforce conversation data. Returns booking confirmation details.'
        category='Electra Cars – Agentforce'
    )
    public static List<Result> createBooking(List<Request> requests) {
        List<Result> results = new List<Result>();

        for (Request req : requests) {
            Savepoint sp = Database.setSavepoint();
            try {
                // 1. Validate input
                validateRequest(req);

                // 2. Upsert Lead
                Lead lead = upsertLead(req);

                // 3. Resolve dealership
                Account dealer = DealershipRoutingAction.resolve(req.zipCode);
                if (dealer == null) {
                    // Fallback to National Booking Centre
                    dealer = getFallbackAccount();
                }

                // 4. Resolve vehicle
             //   Product2 vehicle = resolveVehicle(req.vehicleModelId);

                // 5. Create TestDrive__c
                Booking_Slot__c slot = createBookingSlot(req, dealer);
                TestDrive__c td = createTestDrive(req, lead, dealer, slot.Id);
                // This tracks the specific appointment time at the dealership
               

                // 6. Update Lead with dealership assignment
                lead.Assigned_Dealership__c = dealer.Id;
                update lead;

                // 7. Create audit record
                createAuditRecord(req, lead.Id, td.Id, 'Booked');
                
                // 8. Fire and forget the DocuSign retrieval
                if (String.isNotBlank(td.Envelope_Id__c)) {
                 System.enqueueJob(new DocuSignAttachmentQueueable(td.Id, td.Envelope_Id__c));
                } 

                // 8. Build success result
                Result r = new Result();
                r.testDriveId       = td.Id;
                r.testDriveName     = td.Name;
                r.dealershipId      = dealer.Id;
                r.dealershipName    = dealer.Name;
                r.leadId            = lead.Id;
                r.successFlag       = true;
                r.confirmationMsg   = buildConfirmationMessage(req, td, dealer);
                results.add(r);
        
            } catch (TestDriveValidationException ve) {
                Database.rollback(sp);
                Result r = new Result();
                r.successFlag  = false;
                r.errorMessage = ve.getMessage();
                results.add(r);

            } catch (Exception e) {
                Database.rollback(sp);
                // Best-effort: log the error in audit object without DML on main objects
                try {
                    createErrorAuditRecord(req, e.getMessage());
                } catch (Exception ignored) {}

                Result r = new Result();
                r.successFlag  = false;
                r.errorMessage = 'Sorry, I couldn\'t complete your booking right now. Please try again or speak to our team. (Ref: ' + e.getMessage().abbreviate(80) + ')';
                results.add(r);
            }
        }
        return results;
    }

    // ─── NEW: Booking Slot Creation ────────────────────────────────────────

    /**
     * @description Creates the Booking_Slot__c record linked to the dealership and test drive.
     */
    private static Booking_Slot__c createBookingSlot(Request req, Account dealer) {
        Booking_Slot__c slot = new Booking_Slot__c(
            Preferred_Date__c      = req.preferredDate,
            Preferred_Time_Slot__c = req.timeSlot,
            Dealership__c          = dealer.Id
            // Assuming a lookup field exists to link back to the Test Drive
            // If the field name differs (e.g., Test_Drive__c), update below:
         //   Test_Drive__c          = td.Id 
        );
        insert slot;
        return slot;
    }

    // ─── Lead upsert ──────────────────────────────────────────────────────

    private static Lead upsertLead(Request req) {
        // Check for existing lead by email
        List<Lead> existing = [
            SELECT Id, FirstName, LastName, Email, MobilePhone,
                   Vehicle_Interest__c, Preferred_Channel__c, PostalCode,
                   Assigned_Dealership__c, AgentConversation_ID__c
            FROM   Lead
            WHERE  Email = :req.email
            AND    IsConverted = false
            LIMIT 1
        ];

        Lead lead;
        if (!existing.isEmpty()) {
            lead = existing[0];
            // Update mutable fields from latest conversation
            lead.Phone             = String.isNotBlank(req.phone)            ? req.phone            : lead.MobilePhone;
          //  lead.Vehicle_Interest__c     = String.isNotBlank(req.showroomVehicleId) ? req.showroomVehicleId   : lead.Vehicle_Interest__c;
            lead.Preferred_Channel__c    = String.isNotBlank(req.preferredChannel) ? req.preferredChannel : lead.Preferred_Channel__c;
            lead.Postal_Code__c              = String.isNotBlank(req.zipCode)           ? req.zipCode          : lead.PostalCode;
            lead.AgentConversation_ID__c = req.agentSessionId;
            update lead;
        } else {
            lead = new Lead(
                FirstName                = req.firstName,
                LastName                 = String.isNotBlank(req.lastName) ? req.lastName : 'Unknown',
                Email                    = req.email,
                Phone              = req.phone,
               // Vehicle_Interest__c      = req.showroomVehicleId,
                Preferred_Channel__c     = req.preferredChannel,
                Postal_Code__c               = req.zipCode,
                LeadSource               = 'Agentforce Web Agent',
                Company                  = 'Individual',
                AgentConversation_ID__c  = req.agentSessionId,
                Status                   = 'Open - Not Contacted'
            );
            insert lead;
        }
        return lead;
    }

    // ─── Vehicle resolution ────────────────────────────────────────────────

    private static Product2 resolveVehicle(String vehicleModelId) {
        if (String.isBlank(vehicleModelId)) return null;

        // Try direct ID lookup first
        if (vehicleModelId.length() == 15 || vehicleModelId.length() == 18) {
            List<Product2> byId = [
                SELECT Id, Name, Family
                FROM   Product2
                WHERE  Id = :vehicleModelId
                AND    Test_Drive_Eligible__c = true
                AND    IsActive = true
                LIMIT 1
            ];
            if (!byId.isEmpty()) return byId[0];
        }

        // Fuzzy name match
        String likePattern = '%' + vehicleModelId + '%';
        List<Product2> byName = [
            SELECT Id, Name, Family
            FROM   Product2
            WHERE  Name LIKE :likePattern
            AND    Test_Drive_Eligible__c = true
            AND    IsActive = true
            ORDER BY Name ASC
            LIMIT 1
        ];
        return byName.isEmpty() ? null : byName[0];
    }

    // ─── TestDrive__c creation ─────────────────────────────────────────────

    private static TestDrive__c createTestDrive(Request req, Lead lead, Account dealer, Id slotId) {
        TestDrive__c td = new TestDrive__c(
            Lead__c                 = lead.Id,
        //    Showroom_Vehicle__c     = req.showroomVehicleId != null ? req.showroomVehicleId : null,
            Dealership__c           = dealer.Id,
            Preferred_Date__c       = req.preferredDate,
            Preferred_Time_Slot__c  = req.timeSlot,
            Booking_Status__c       = 'Pending Confirmation',
            Booked_Via__c           = 'Agentforce',
            Agent_Session_ID__c     = req.agentSessionId,
            Confirmation_Channel__c = req.preferredChannel,
            Notes__c                = req.notes,
            Booking_Slot__c         = slotId,
            Envelope_Id__c          = req.envelopeId
        );
        insert td;
        TestDrive__c testDriveRecord = [SELECT Id,Name,Lead__c,Vehicle__c,Dealership__c,Preferred_Date__c,Booking_Status__c
                                        ,Booked_Via__c,Agent_Session_ID__c,Confirmation_Channel__c,Notes__c,Booking_Slot__c,
                                        Envelope_Id__c
                                        FROM TestDrive__c WHERE Id=:td.Id LIMIT 1];
        return testDriveRecord;
    }

    // ─── Audit record creation ─────────────────────────────────────────────

    private static void createAuditRecord(Request req, Id leadId, Id testDriveId, String outcome) {
        AgentConversation__c audit = new AgentConversation__c(
            Session_ID__c  = String.isNotBlank(req.agentSessionId) ? req.agentSessionId : 'UNKNOWN',
            Lead__c        = leadId,
            TestDrive__c   = testDriveId,
            Start_Time__c  = Datetime.now(),
            Outcome__c     = outcome,
            Channel__c     = 'Web Widget'
        );
        insert audit;
    }

    private static void createErrorAuditRecord(Request req, String errorMsg) {
        AgentConversation__c audit = new AgentConversation__c(
            Session_ID__c  = String.isNotBlank(req.agentSessionId) ? req.agentSessionId : 'ERROR',
            Start_Time__c  = Datetime.now(),
            Outcome__c     = 'Error',
            Channel__c     = 'Web Widget',
            Transcript__c  = errorMsg
        );
        insert audit;
    }

    // ─── Fallback account ──────────────────────────────────────────────────

    private static Account getFallbackAccount() {
        List<Account> fallback = [
            SELECT Id, Name
            FROM   Account
            WHERE  Name = 'National Booking Centre'
            AND    IsActive__c = true
            LIMIT 1
        ];
        if (!fallback.isEmpty()) return fallback[0];

        // Last resort: return a dummy account stub (will still show name in confirmation)
        Account dummy = new Account(Name = 'National Booking Centre');
        return dummy;
    }

    // ─── Confirmation message builder ──────────────────────────────────────

    private static String buildConfirmationMessage(Request req, TestDrive__c td, Account dealer) {
        String dateStr = req.preferredDate != null ? req.preferredDate.format() : 'TBC';
        return 'Your test drive is booked! '
            + 'Booking reference: ' + td.Name + '. '
            + 'Dealership: ' + dealer.Name + '. '
            + 'Date: ' + dateStr + ', ' + req.timeSlot + '. '
            + 'A confirmation will be sent to ' + req.email + '.';
    }

    // ─── Validation ────────────────────────────────────────────────────────

    private static void validateRequest(Request req) {
        List<String> errors = new List<String>();

        if (String.isBlank(req.email))         errors.add('Email is required.');
        if (String.isBlank(req.firstName))      errors.add('First name is required.');
        if (req.preferredDate == null)          errors.add('Preferred date is required.');
        if (String.isBlank(req.timeSlot))       errors.add('Time slot is required.');
        if (String.isBlank(req.zipCode))        errors.add('Zip code is required.');

        // Date must be in the future
        if (req.preferredDate != null && req.preferredDate <= Date.today()) {
            errors.add('Preferred date must be at least tomorrow. Please choose a future date.');
        }

        if (!errors.isEmpty()) {
            throw new TestDriveValidationException(String.join(errors, ' '));
        }
    }

    // ─── Custom exception ──────────────────────────────────────────────────

    public class TestDriveValidationException extends Exception {}

    // ─── Inner Request / Result ────────────────────────────────────────────

    public class Request {
        @InvocableVariable(label='First Name'           required=true)  public String  firstName;
        @InvocableVariable(label='Last Name'            required=false) public String  lastName;
        @InvocableVariable(label='Email'                required=true)  public String  email;
        @InvocableVariable(label='Phone'                required=false) public String  phone;
        @InvocableVariable(label='Showroom Vehicle Id'  required=false) public String  showroomVehicleId;
        @InvocableVariable(label='Preferred Date'       required=true)  public Date    preferredDate;
        @InvocableVariable(label='Time Slot'            required=true)  public String  timeSlot;
        @InvocableVariable(label='Zip Code'             required=true)  public String  zipCode;
        @InvocableVariable(label='Preferred Channel'    required=false) public String  preferredChannel;
        @InvocableVariable(label='Agent Session Id'     required=false) public String  agentSessionId;
        @InvocableVariable(label='Notes'                required=false) public String  notes;
        @InvocableVariable(label='Envelope Id'          required=false) public String  envelopeId;

    }

    public class Result {
        @InvocableVariable(label='Test Drive Id')       public String  testDriveId;
        @InvocableVariable(label='Test Drive Name')     public String  testDriveName;
        @InvocableVariable(label='Lead Id')             public String  leadId;
        @InvocableVariable(label='Dealership Id')       public String  dealershipId;
        @InvocableVariable(label='Dealership Name')     public String  dealershipName;
        @InvocableVariable(label='Success Flag')        public Boolean successFlag;
        @InvocableVariable(label='Confirmation Message') public String confirmationMsg;
        @InvocableVariable(label='Error Message')       public String  errorMessage;
    }
}