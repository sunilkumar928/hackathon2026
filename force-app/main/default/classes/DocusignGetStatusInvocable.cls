public with sharing class DocusignGetStatusInvocable {
    @InvocableMethod(label='Docusign: Check Signing Status' description='Checks if the user has completed signing the envelope.')
    public static List<Boolean> getStatus(List<String> envelopeIds) {
        List<Boolean> results = new List<Boolean>();
        for (String envId : envelopeIds) {
            results.add(DocusignRESTAPIService.getEnvelopeSigningStatus(envId));
        }
        return results;
    }
}