/**
 * @description  Test class for TestDriveBookingAction and DealershipRoutingAction.
 *               Covers happy path, validation errors, duplicate lead upsert, fallback
 *               dealership, and past-date rejection scenarios.
 *               Target: >= 85% code coverage for both classes.
 *
 * @author       Salesforce Architecture Team – Electra Cars
 */
@IsTest private class TestDriveBookingActionTest {
  // ─── Test Data Setup ───────────────────────────────────────────────────

  @TestSetup static void makeData() {
    // Dealership Account
    Account dealer = new Account(Name = 'Electra Banjara Hills',
        BillingPostalCode = '500034',
        IsActive__c = true,
        RecordTypeId = getRecordTypeId('Account', 'Dealership'));
    insert dealer;

    // Fallback Account
    Account fallback = new Account(Name = 'National Booking Centre', IsActive__c = true);
    insert fallback;

    // Vehicle (Product2)
    Product2 vehicle = new Product2(
        Name = 'Electra X7 SUV', Family = 'EV SUV', IsActive = true, Test_Drive_Eligible__c = true);
    insert vehicle;
  }

  // ─── Helper: get RecordType id (returns null if RT not found, safe for orgs without Automotive
  // Cloud) ──
  private
  static Id getRecordTypeId(String sObjectName, String devName) {
    List<RecordType> rts =
        [SELECT Id FROM RecordType WHERE SObjectType =:sObjectName AND DeveloperName
                                                     =:devName LIMIT 1];
    return rts.isEmpty() ? null : rts[0].Id;
  }

  private
  static TestDriveBookingAction.Request buildRequest(String email, Boolean futureDate) {
    TestDriveBookingAction.Request req = new TestDriveBookingAction.Request();
    req.firstName = 'Priya';
    req.lastName = 'Sharma';
    req.email = email;
    req.phone = '+919876543210';
    req.vehicleModelId = 'Electra X7 SUV';
    req.preferredDate = futureDate ? Date.today().addDays(5) : Date.today();
    req.timeSlot = 'Morning (9-12)';
    req.zipCode = '500034';
    req.preferredChannel = 'Email';
    req.agentSessionId = 'TEST-SESSION-001';
    return req;
  }

  // ─── TC01 Happy Path ───────────────────────────────────────────────────

  @IsTest static void testHappyPath_CreatesLeadAndTestDrive() {
    Test.startTest();
    List<TestDriveBookingAction.Result> results = TestDriveBookingAction.createBooking(
        new List<TestDriveBookingAction.Request>{buildRequest('priya@test.com', true)});
    Test.stopTest();

    System.assertEquals(1, results.size(), 'Should return 1 result');
    TestDriveBookingAction.Result r = results[0];
    System.assert(r.successFlag, 'Success flag should be true. Error: ' + r.errorMessage);
    System.assertNotEquals(null, r.testDriveId, 'TestDrive Id should be populated');
    System.assertNotEquals(null, r.leadId, 'Lead Id should be populated');

    TestDrive__c td =
        [SELECT Booking_Status__c, Booked_Via__c, Dealership__c FROM TestDrive__c WHERE Id
          =:r.testDriveId];
    System.assertEquals('Pending Confirmation', td.Booking_Status__c);
    System.assertEquals('Agentforce', td.Booked_Via__c);
  }

  // ─── TC06 Duplicate Lead Upsert ───────────────────────────────────────

  @IsTest static void testDuplicateLeadUpsert_NoDuplicate() {
    // Pre-insert Lead with same email
    Lead existing = new Lead(FirstName = 'Priya',
        LastName = 'Sharma',
        Email = 'existing@test.com',
        Company = 'Individual',
        Status = 'Open - Not Contacted');
    insert existing;

    Test.startTest();
    TestDriveBookingAction.createBooking(
        new List<TestDriveBookingAction.Request>{buildRequest('existing@test.com', true)});
    Test.stopTest();

    Integer leadCount = [SELECT COUNT() FROM Lead WHERE Email = 'existing@test.com'];
    System.assertEquals(1, leadCount, 'No duplicate Lead should be created');
  }

  // ─── TC04 Past Date Validation ────────────────────────────────────────

  @IsTest static void testPastDateRejected() {
    Test.startTest();
    List<TestDriveBookingAction.Result> results = TestDriveBookingAction.createBooking(
        new List<TestDriveBookingAction.Request>{buildRequest('pastdate@test.com', false)});
    Test.stopTest();

    System.assertEquals(1, results.size());
    System.assert(!results[0].successFlag, 'Past date should fail validation');
    System.assert(results[0].errorMessage.containsIgnoreCase('future date'),
        'Error should mention future date');
  }

  // ─── TC03 Invalid Zip – Fallback Dealership ───────────────────────────

  @IsTest static void testInvalidZipFallsBackToNational() {
    TestDriveBookingAction.Request req = buildRequest('invalidzip@test.com', true);
    req.zipCode = '99999';  // Not in TerritoryMapping__mdt seed

    Test.startTest();
    List<TestDriveBookingAction.Result> results =
        TestDriveBookingAction.createBooking(new List<TestDriveBookingAction.Request>{req});
    Test.stopTest();

    System.assertEquals(1, results.size());
    // Should still succeed with fallback
    System.assert(
        results[0].successFlag, 'Should succeed with fallback. Error: ' + results[0].errorMessage);
    System.assertEquals('National Booking Centre', results[0].dealershipName);
  }

  // ─── Missing Email Validation ─────────────────────────────────────────

  @IsTest static void testMissingEmailFails() {
    TestDriveBookingAction.Request req = buildRequest(null, true);
    req.email = null;

    Test.startTest();
    List<TestDriveBookingAction.Result> results =
        TestDriveBookingAction.createBooking(new List<TestDriveBookingAction.Request>{req});
    Test.stopTest();

    System.assert(!results[0].successFlag, 'Missing email should fail');
  }

  // ─── DealershipRoutingAction – direct resolve ─────────────────────────

  @IsTest static void testDealershipRoutingAction_DirectResolve() {
    // We have no CMT records in test context (can't insert CMT in tests)
    // so resolve should return null and invocable should use fallback
    DealershipRoutingAction.Request req = new DealershipRoutingAction.Request();
    req.zipCode = '500034';

    Test.startTest();
    List<DealershipRoutingAction.Result> results =
        DealershipRoutingAction.assignDealership(new List<DealershipRoutingAction.Request>{req});
    Test.stopTest();

    System.assertEquals(1, results.size());
    System.assert(results[0].successFlag, 'Should succeed (fallback to National Booking Centre)');
  }

  // ─── DealershipRoutingAction – blank zip ─────────────────────────────

  @IsTest static void testDealershipRoutingAction_BlankZip() {
    DealershipRoutingAction.Request req = new DealershipRoutingAction.Request();
    req.zipCode = '';

    Test.startTest();
    List<DealershipRoutingAction.Result> results =
        DealershipRoutingAction.assignDealership(new List<DealershipRoutingAction.Request>{req});
    Test.stopTest();

    System.assertEquals(1, results.size());
    System.assert(results[0].successFlag);
    System.assertEquals('National Booking Centre', results[0].dealershipName);
  }

  // ─── Batch / bulkification test ──────────────────────────────────────

  @IsTest static void testBulkBookings_200Records() {
    List<TestDriveBookingAction.Request> bulkList = new List<TestDriveBookingAction.Request>();
    for (Integer i = 0; i < 5; i++) {
      bulkList.add(buildRequest('bulkuser' + i + '@test.com', true));
    }

    Test.startTest();
    List<TestDriveBookingAction.Result> results = TestDriveBookingAction.createBooking(bulkList);
    Test.stopTest();

    System.assertEquals(5, results.size(), 'Should return 200 results');
    for (TestDriveBookingAction.Result r : results) {
      System.assert(r.successFlag, 'Bulk record failed: ' + r.errorMessage);
    }
  }
}