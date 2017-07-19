public class AccountOpportunity {
    
    @AuraEnabled
    //To get List of Account
    public static List<Account> getAccountList(){
        return[Select Name, Id from Account];
    }
    @AuraEnabled
    //To get Account Detail
    public static Account getAccountDetail(string Id){
        system.debug('Id::' + id);
        return [Select Website, Phone, Name from Account where Id=:Id];
    }
	@AuraEnabled
    // To get List of Opportunities
    public static List<Opportunity> getListopps(string Id) {
         system.debug('Select name,AccountId  from Opportunity where AccountId =\''+String.escapeSingleQuotes(id) + '\'');
         List<Opportunity> listopps=database.query('Select name,AccountId,closedate,stagename from Opportunity where AccountId =\''+String.escapeSingleQuotes(id) + '\'');
         System.debug('Data in opps '+listopps);
         return listopps;
    }
    @AuraEnabled
    // To delete Opportunity
    public static List<Opportunity> deleteopp(String oppsId) {
        try {
            system.debug('in delete opp ::' + 'SELECT Id FROM Opportunity WHERE Id =\'' + String.escapeSingleQuotes(oppsId) + '\'');
            if(oppsId != null){
                Opportunity opp =  [SELECT Id FROM Opportunity WHERE Id =:oppsId];
                string accid =  opp.AccountId;
                delete opp;
                return getListopps(accid);  
            }
        }
        catch(exception ex){
            system.debug('deleteopp error: '+ex.getMessage());
            return null;
            }
       return null;
    }
    @AuraEnabled
    public static List<Opportunity> Saveopportunity(Opportunity Opp){
        try{
            system.debug('Opp::'+ Opp);
            Insert Opp;
            return getListopps(Opp.AccountId);
        }
        catch(exception ex){
             system.debug('Saveopportunity error: '+ex.getMessage());
            return null;
        }
    }
}