public with sharing class CompositeGraphWrapper{
	public cls_graph[] graphs;
    public static Integer graphCounter=0;

    public CompositeGraphWrapper(){
        this.graphs = new List<cls_graph>();
    }

	public class cls_graph {
		public String graphId;	//1
		public cls_compositeRequest[] compositeRequest;
        public cls_graph(){
            this.graphId = graphCounter+'';
            graphCounter += 1;
            this.compositeRequest = new List<cls_compositeRequest>();
        }
	}
	public class cls_compositeRequest {
		public String url;	///services/data/v50.0/sobjects/Account/
		public Map<String,Object> body;
		public String method;	//POST
		public String referenceId;	//reference_id_account_1
        public cls_compositeRequest(String url,Map<String,Object> body,String method,String referenceId){
            this.url = url;
            this.body = body;
            this.method = method;
            this.referenceId = referenceId;

        }
	}
	
	public static CompositeGraphWrapper parse(String json){
		return (CompositeGraphWrapper) System.JSON.deserialize(json, CompositeGraphWrapper.class);
	}

    /*

	static testMethod void testParse() {
		String json=		'{'+
		'   "graphs" : ['+
		'      {'+
		'        "graphId" : "1",'+
		'        "compositeRequest" : ['+
		'            {'+
		'              "url" : "/services/data/v50.0/sobjects/Account/",'+
		'              "body" : {'+
		'                "name" : "Cloudy Consulting",'+
		'                "description" : "Parent account"'+
		'              },'+
		'              "method" : "POST",'+
		'              "referenceId" : "reference_id_account_1"'+
		'            },'+
		'            {'+
		'              "url" : "/services/data/v50.0/sobjects/Account/",'+
		'              "body" : {'+
		'                "name" : "Easy Spaces",'+
		'                "description" : "Child account",'+
		'                "ParentId" : "@{reference_id_account_1.id}"'+
		'              },'+
		'              "method" : "POST",'+
		'              "referenceId" : "reference_id_account_2"'+
		'            },'+
		'            {'+
		'              "url" : "/services/data/v50.0/sobjects/Contact/",'+
		'              "body" : {'+
		'                "FirstName" : "Sam",'+
		'                "LastName" : "Steele",'+
		'                "AccountId" : "@{reference_id_account_2.id}"'+
		'              },'+
		'              "method" : "POST",'+
		'              "referenceId" : "reference_id_contact_1"'+
		'            },'+
		'            {'+
		'              "url" : "/services/data/v50.0/sobjects/Contact/",'+
		'              "body" : {'+
		'                "FirstName" : "Charlie",'+
		'                "LastName" : "Dawson",'+
		'                "AccountId" : "@{reference_id_account_2.id}",'+
		'                "ReportsToId" : "@{reference_id_contact_1.id}"'+
		'              },'+
		'              "method" : "POST",'+
		'              "referenceId" : "reference_id_contact_2"'+
		'            },'+
		'            {'+
		'              "url" : "/services/data/v50.0/sobjects/Contact/",'+
		'              "body" : {'+
		'                "FirstName" : "Nellie",'+
		'                "LastName" : "Cashman",'+
		'                "AccountId" : "@{reference_id_account_2.id}",'+
		'                "ReportsToId" : "@{reference_id_contact_2.id}"'+
		'              },'+
		'              "method" : "POST",'+
		'              "referenceId" : "reference_id_contact_3"'+
		'            },'+
		'            {'+
		'              "url" : "/services/data/v50.0/sobjects/Campaign/",'+
		'              "body" : {'+
		'                "name" : "Spring Campaign"'+
		'              },'+
		'              "method" : "POST",'+
		'              "referenceId" : "reference_id_campaign"'+
		'            },'+
		'            {'+
		'              "url" : "/services/data/v50.0/sobjects/Opportunity/",'+
		'              "body" : {'+
		'                "name" : "Opportunity",'+
		'                "stageName" : "Value Proposition",'+
		'                "closeDate" : "2025-12-31",'+
		'                "CampaignId" : "@{reference_id_campaign.id}",'+
		'                "AccountId" : "@{reference_id_account_2.id}"'+
		'              },'+
		'              "method" : "POST",'+
		'              "referenceId" : "reference_id_opportunity"'+
		'            },'+
		'            {'+
		'              "url" : "/services/data/v50.0/sobjects/Lead/",'+
		'              "body" : {'+
		'                "FirstName" : "Belinda",'+
		'                "LastName" : "Mulroney",'+
		'                "Company" : "Klondike Quarry",'+
		'                "Email" : "bmulroney@example.com"'+
		'              },'+
		'              "method" : "POST",'+
		'              "referenceId" : "reference_id_lead"'+
		'            },'+
		'            {'+
		'              "url" : "/services/data/v50.0/sobjects/CampaignMember/",'+
		'              "body" : {'+
		'                "CampaignId" : "@{reference_id_campaign.id}",'+
		'                "LeadId" : "@{reference_id_lead.id}"'+
		'              },'+
		'              "method" : "POST",'+
		'              "referenceId" : "reference_id_campaignmember"'+
		'            }'+
		'          ]'+
		'      }'+
		'   ]'+
		'}';
		CompositeGraphWrapper obj = parse(json);
		System.assert(obj != null);
	}
    */
}