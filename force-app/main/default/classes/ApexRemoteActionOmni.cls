global with sharing class ApexRemoteActionOmni implements omnistudio.VlocityOpenInterface2{
    
    @RemoteAction
public static void saveOpps(Map<String,Object> inputMap, Map<String,Object> outputMap) { 
	System.debug('in remote action'+JSON.serialize(inputMap));
    List<Opportunity> updateOpps = new List<Opportunity>();
    List<Object> t = (List<Object>)inputMap.get('opps');
    
   for(Object temp: t) {
       
        Opps op = (Opps) JSON.deserialize(JSON.serialize(temp), Opps.class);
       Opportunity o = new Opportunity(Id = op.Id, Name = op.Name,StageName =  op.StageName, Type = op.Type );
       
        updateOpps.add(o);
        system.debug('in loop :' + o);
        
    }
    update updateOpps;
}
    
    global Boolean invokeMethod(String param1, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        Boolean res = true;
        try{
        if(param1 == 'saveOpps') {
            saveOpps(inputMap,outputMap);
        } else {
            res = false;
        }
        } catch(Exception e) {
            System.debug(e.getMessage());
            return false;
        } 
        
        return res;
    }
    
    public class Opps {
        private String Id;
        private String StageName;
        private String Name;
        private String TrackingNumber;
        private String Type;
        
        
    }

}