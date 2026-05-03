public with sharing class DocusignCreateEnvelopeInvocable {
    @InvocableMethod(label='Docusign Create Envelope' description='Creates a Docusign envelope for the NDA process.')
    public static List<String> createEnvelope(List<Request> requests) {
        List<String> results = new List<String>();
        for (Request req : requests) {
            String envelopeId = DocusignRESTAPIService.createEnvelope(req.email, req.userName);
            results.add(envelopeId);
        }
        return results;
    }

    public class Request {
        @InvocableVariable(required=true) public String email;
        @InvocableVariable(required=true) public String userName;
    }
}