@isTest
public class GroundCalculatedInsightsTest {

    @isTest
    static void testGetInsightsSuccess() {
        // 1. Construct valid inputs to test the success path
        GroundCalculatedInsights.PromptInput inputRecord = new GroundCalculatedInsights.PromptInput();
        inputRecord.leadLastName = 'Smith';
        inputRecord.dealershipName = 'Central Dealership';
        
        List<GroundCalculatedInsights.PromptInput> inputs = new List<GroundCalculatedInsights.PromptInput>{ inputRecord };

        // 2. Execute the code
        Test.startTest();
        List<GroundCalculatedInsights.PromptOutput> outputs = GroundCalculatedInsights.getInsights(inputs);
        Test.stopTest();

        // 3. Validate outcomes
        System.assertEquals(1, outputs.size(), 'Outputs list should return exactly 1 result block.');
        System.assert(outputs[0].insightContent.contains('Lead_Booking_Count__cio'), 'Should contain Lead Insight text.');
    }

    @isTest
    static void testGetInsightsWithBlankData() {
        // 1. Construct blank inputs to test edge cases and cover the skipping logic
        GroundCalculatedInsights.PromptInput inputRecord = new GroundCalculatedInsights.PromptInput();
        inputRecord.leadLastName = '';
        inputRecord.dealershipName = '';
        
        List<GroundCalculatedInsights.PromptInput> inputs = new List<GroundCalculatedInsights.PromptInput>{ inputRecord };

        // 2. Execute the code
        Test.startTest();
        List<GroundCalculatedInsights.PromptOutput> outputs = GroundCalculatedInsights.getInsights(inputs);
        Test.stopTest();

        // 3. Validate that it runs without failure
        System.assertEquals(1, outputs.size(), 'Outputs list should return exactly 1 result block.');
    }
}