public class GroundCalculatedInsights {

    public class PromptInput {
        @InvocableVariable(label='Lead Last Name' required=false)
        public String leadLastName;
        
        @InvocableVariable(label='Dealership Name' required=false)
        public String dealershipName;
    }

    public class PromptOutput {
        @InvocableVariable(label='Insight Content')
        public String insightContent;
    }

    @InvocableMethod(label='Fetch Calculated Insights for Agent' category='Prompt Grounding')
    public static List<PromptOutput> getInsights(List<PromptInput> inputs) {
        List<PromptOutput> outputs = new List<PromptOutput>();

        for (PromptInput input : inputs) {
            PromptOutput output = new PromptOutput();
            String promptContext = 'Here are the Calculated Data Cloud insights:\n';

            // 1. QUERY INSIGHT 1: Lead Booking Count
            if (String.isNotBlank(input.leadLastName)) {
                String leadQuery = 'SELECT number_of_bookings__c FROM Lead_Booking_Count__cio WHERE lead__c = \'' + String.escapeSingleQuotes(input.leadLastName) + '\' LIMIT 1';
                promptContext += executeQuery('Lead_Booking_Count__cio', leadQuery);
            }

            // 2. QUERY INSIGHT 2: Dealership Booking Count
            if (String.isNotBlank(input.dealershipName)) {
                String dealerQuery = 'SELECT no_of_bookings__c FROM No_of_Bookings_on_Dealership__cio WHERE dealership__c = \'' + String.escapeSingleQuotes(input.dealershipName) + '\' LIMIT 1';
                promptContext += executeQuery('No_of_Bookings_on_Dealership__cio', dealerQuery);
            }
            
            // FUTURE INSIGHTS GO HERE:
            // Simply add an if statement and a custom query for your 3rd, 4th, or 5th insight.

            output.insightContent = promptContext;
            outputs.add(output);
        }
        return outputs;
    }

     // Helper method to safely query Data Cloud and format the response
    private static String executeQuery(String insightName, String sql) {
        try {
            ConnectApi.CdpQueryInput queryInput = new ConnectApi.CdpQueryInput();
            queryInput.sql = sql;
            
            ConnectApi.CdpQueryOutputV2 response;

            // FIX: Simulate Data Cloud objects during test to run the code loops
            if (Test.isRunningTest()) {
                response = new ConnectApi.CdpQueryOutputV2();
                ConnectApi.CdpQueryV2Row mockRow = new ConnectApi.CdpQueryV2Row();
                mockRow.rowData = new List<Object>{ '5' };
                response.data = new List<ConnectApi.CdpQueryV2Row>{ mockRow };
            } else {
                // Execute actual Data Cloud ANSI SQL in production
                response = ConnectApi.CdpQuery.queryAnsiSqlV2(queryInput);
            }

            if (response != null && response.data != null && !response.data.isEmpty()) {
                // Grab the first record row returned
                ConnectApi.CdpQueryV2Row firstRow = response.data.get(0);
                
                String result = '\n--- Insight: ' + insightName + ' ---\n';
                
                // CdpQueryV2Row stores fields as a List of Objects in 'rowData'
                if (firstRow.rowData != null && !firstRow.rowData.isEmpty()) {
                    for (Integer i = 0; i < firstRow.rowData.size(); i++) {
                        Object cellValue = firstRow.rowData.get(i);
                        result += 'Field ' + (i + 1) + ': ' + String.valueOf(cellValue) + '\n';
                    }
                    return result;
                }
            }
            return '\n' + insightName + ': No data found.\n';
        } catch (Exception e) {
            return '\nError querying ' + insightName + ': ' + e.getMessage() + '\n';
        }
    }

}