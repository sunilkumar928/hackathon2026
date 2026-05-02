public class DocuSignAttachmentQueueable implements Queueable, Database.AllowsCallouts {
    private Id testDriveId;
    private String envelopeId;

    public DocuSignAttachmentQueueable(Id testDriveId, String envelopeId) {
        this.testDriveId = testDriveId;
        this.envelopeId = envelopeId;
    }

    public void execute(QueueableContext context) {
        // 1. Re-query the TestDrive record or use the provided Envelope ID
        TestDrive__c td = [SELECT Id, Envelope_Id__c FROM TestDrive__c WHERE Id = :testDriveId LIMIT 1];
        
        // 2. Perform the Callout (Safe now because this is a new transaction)
        DocusignRESTAPIService docusignService = DocusignRESTAPIService.getInstance();
        List<DocusignRESTAPIHelper.EnvelopeDocument> docs = new List<DocusignRESTAPIHelper.EnvelopeDocument>();
        
        for (DocusignRESTAPIHelper.EnvelopeDocument doc : docusignService.getDocumentsList(td.Envelope_Id__c)) {
            if (String.isNotBlank(doc.name) && doc.name != 'Summary') {
                doc.base64EncodedString = docusignService.getDocumentBody(td.Envelope_Id__c, doc.documentId);
                docs.add(doc);
            }
        }

        // 3. Perform DML to attach documents
        if (!docs.isEmpty()) {
            attachDocuments(docs, td.Id);
        }
    }

    private void attachDocuments(List<DocusignRESTAPIHelper.EnvelopeDocument> docs, Id parentId) {
        List<ContentVersion> cvList = new List<ContentVersion>();
        for (DocusignRESTAPIHelper.EnvelopeDocument d : docs) {
            cvList.add(new ContentVersion(
                Title = d.name,
                PathOnClient = d.name + '.pdf',
                VersionData = EncodingUtil.base64Decode(d.base64EncodedString)
            ));
        }
        insert cvList;

        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
        for (ContentVersion cv : [SELECT ContentDocumentId FROM ContentVersion WHERE Id IN :cvList]) {
            cdlList.add(new ContentDocumentLink(
                ContentDocumentId = cv.ContentDocumentId,
                LinkedEntityId = parentId,
                ShareType = 'V'
            ));
        }
        insert cdlList;
    }
}