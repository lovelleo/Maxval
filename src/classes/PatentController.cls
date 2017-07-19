public class PatentController {
   /* @AuraEnabled
    public static List<Patent__c> SavePatent(Patent__c Patent) {
        system.debug('Patent : '+Patent);
        if(Patent != null && PatentFLS()){ 
            try{  
                system.debug('In Upsert');
                upsert(Patent);
                return GetPatent('','','','','','');
            }
            catch (exception e){
                system.debug('In SavePatent Exception :' + e.getMessage());
                return null;        
            }          
        }
        return null;
    }
    @AuraEnabled
    public static List<Patent__c> GetPatent(string condition, string fields, string sortby, string dir, string offset, string pagesize){
        if(PatentFLS()){
            if(fields ==''){
                fields = 'Application_Number__c, Patent_Number__c, Country__c, Filing_Date__c, Issue_Date__c, Abstract__c, Name, Id'; 
            }
            if(pagesize == null || pagesize == ''){
                pagesize = '5';
            }
            system.debug('condition :'+condition + '| field :' +fields +'| pagesize :'+pagesize + '| offset :' + offset );
            system.debug('Sortby : ' + sortby);
            if(sortby == null ||sortby == ''){
                sortby = ' ID ';
            }
            if(dir == '' || dir ==null){
                sortby += ' DESC '; 
            }
            else{
                sortby += ' '+ dir +' ';
            }
            condition += ' ORDER BY '+ sortby + ' LIMIT ' + String.valueOf(pagesize);//+sortby;
            system.debug('condition : '+ condition); 
            if(offset != null && offset != ''){
                condition += ' OFFSET '+String.valueOf(offset);
            }
            system.debug('SELECT ' + fields +' FROM Patent__c '+condition);
            system.debug('Data: '+Database.query('SELECT ' + fields +' FROM Patent__c '+condition));
            return Database.query('SELECT ' + fields +' FROM Patent__c '+condition); 
        }
        return null;
    }
    @AuraEnabled
    public static List<Patent__c> DeletePatent(string patentid){
        try{
            system.debug('ID to delete :'+'\''+ patentid +'\'' );
            if(patentid !=null) {
                if(PatentFLS()){           
                    string condition = 'where Id = '+'\''+ patentid +'\'';
                    system.debug('d-condtion :'+condition);
                    List<Patent__c> Patent = GetPatent(condition,'','','','','');
                    system.debug('Patent :'+Patent);
                    if(Patent != null){
                        Delete Patent;
                    }
                    return GetPatent('','','','','','');
                }
                
            }
            return GetPatent('','','','','','');
        }
        catch(exception e){return GetPatent('','','','','','');}
        
        
    }
    public static Boolean PatentFLS(){
        String [] PatentAccessFields = new String [] {'Application_Number__c',
            'Patent_Number__c',
            'Country__c',
            'Filing_Date__c',
            'Issue_Date__c',
            'Abstract__c',
            'Name'};
                // Obtain the field name/token map for the Expense object
                Map<String,Schema.SObjectField> m = Schema.SObjectType.Patent__c.fields.getMap();    
        for (String fieldToCheck : PatentAccessFields) {
            // Check if the user has access to view field
            if (!m.get(fieldToCheck).getDescribe().isAccessible()) {
                // Pass error to client
                throw new System.NoAccessException();
                // Suppress editor logs
                return false;
            }
        } 
        return true;
    }
    @AuraEnabled
    public static Patent__c FetchPatent(string Patentid){
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        String xmlEPO = 'http://ops.epo.org/3.1/rest-services/published-data/publication/epodoc/'+Patentid+'/biblio';
        req.setEndpoint(xmlEPO);
        req.setMethod('GET');
        HttpResponse res = http.send(req);
        // Log the XML content
        String xmlContent=res.getBody();
        //System.debug(xmlContent);
        Dom.Document docx = new Dom.Document();
        docx.load(xmlContent);   
        //system.debug('docx :: '+docx);
        dom.XmlNode xroot = docx.getrootelement() ;
        //system.debug('xroot :: '+xroot.getName());        
        //system.debug('root>child'+xroot.getChildElements());
        for (Dom.XmlNode node : docx.getRootElement().getChildElements()) {
            String childnode = node.getName();
            //system.debug('childnode '+childnode);
            if(childnode == 'exchange-documents'){
                for(Dom.XmlNode epodocument: node.getChildElements())
                {
                    system.debug('exdocs '+epodocument.getName());
                    if(epodocument.getName() == 'exchange-document'){                        
                        //for(Dom.XmlNode epodocument: exdocs.getChildElements()){
                        // if(epodocument.getName() == 'exchange-document'){
                        system.debug('epepodocument :: '+epodocument.getName());      
                        if(epodocument.getAttributeValue('status', null) != null && epodocument.getAttributeValue('status', null)=='not found'){
                            return(null);
                        }
                        else{
                            Patent__c pat =  new Patent__c();
                            pat.Patent_Number__c = Patentid;
                            pat.Country__c = epodocument.getAttributeValue('country',null);
                            for(Dom.XMLNode epchild : epodocument.getChildElements()) {
                                if(epchild.getName() =='bibliographic-data') {
                                    for(Dom.XMLNode bdchild : epchild.getChildElements()) {
                                        system.debug('bdchild:'+bdchild.getName());
                                        if(bdchild.getName()=='application-reference')    {
                                            for(Dom.XMLNode child : bdchild.getChildElements()) {       
                                                System.debug('document-id'+child.getName());
                                                if(child.getAttributeValue('document-id-type', null) == 'epodoc'){
                                                    system.debug('inside epdoc');
                                                    for(Dom.XMLNode epo : child.getChildElements()){
                                                        if(epo.getName()=='doc-number'){
                                                            pat.Application_Number__c = epo.gettext();
                                                        }
                                                        if(epo.getName()=='date'){
                                                            pat.Filing_Date__c = formatdate(epo.gettext());
                                                        }
                                                    }
                                                    
                                                }
                                            }
                                        }
                                        if(bdchild.getName()=='publication-reference') {
                                            for(Dom.XMLNode child : bdchild.getChildElements()){       
                                                System.debug('document-id'+child.getName());                                                
                                                if(child.getAttributeValue('document-id-type', null) == 'epodoc'){
                                                    system.debug('inside epdoc');
                                                    for(Dom.XMLNode epo : child.getChildElements()){
                                                        if(epo.getName()=='date'){
                                                            pat.Issue_Date__c =  formatdate(epo.gettext());
                                                        }
                                                    }
                                                    
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            for(Dom.XMLNode abs :epodocument.getChildElements()) {
                                if(abs.getName()=='abstract'){
                                    for(Dom.XMLNode abstext :abs.getChildElements()) {
                                        system.debug('Abstract :'+ abstext.gettext());
                                        String abst= '';
                                        if(abstext.gettext()!=null){  
                                            abst += '<p>'+abstext.gettext()+'</p>'; 
                                        }pat.Abstract__c =abst;
                                    }
                                }
                            }
                            system.debug('Patent : '+pat);
                            return pat;
                        }
                    } 
                }
            }               
        }
        return null;
    }
    public static date formatdate(string indate){
        system.debug('indate : '+indate);
        string yyyy = indate.substring(0,4);
        string mm = indate.substring(4,6);
        string dd = indate.substring(6,8);
        system.debug(yyyy+'-'+mm+'-'+dd);
        return (Date.valueOf(yyyy+'-'+mm+'-'+dd)); 
    }*/
}