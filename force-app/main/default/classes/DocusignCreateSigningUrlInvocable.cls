public with sharing class DocusignCreateSigningUrlInvocable {
    @InvocableMethod(label='Docusign Generate Signing URL' description='Generates a signing link for an existing envelope.')
    public static List<String> createUrl(List<Request> requests) {
        List<String> results = new List<String>();
        for (Request req : requests) {
            String signingUrl = DocusignRESTAPIService.createEmbeddedSigningUrl(
                req.email, req.userName, req.envelopeId, req.returnUrl
            );
            results.add(signingUrl);
        }
        return results;
    }

    public class Request {
        @InvocableVariable(required=true) public String email;
        @InvocableVariable(required=true) public String userName;
        @InvocableVariable(required=true) public String envelopeId;
        @InvocableVariable(required=true) public String returnUrl;
    }
}