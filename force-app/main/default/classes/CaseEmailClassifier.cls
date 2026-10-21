public with sharing class CaseEmailClassifier {
    public static final String CAT_ACCESS = 'Access';
    public static final String CAT_HARDWARE = 'Hardware';
    public static final String CAT_NETWORK = 'Network';
    public static final String CAT_GENERAL = 'General';

    private static final Map<String, List<String>> KEYWORDS = new Map<String, List<String>>{
        CAT_ACCESS => new List<String>{ 'password', 'login', 'locked out', 'access', 'permission' },
        CAT_HARDWARE => new List<String>{ 'laptop', 'printer', 'monitor', 'keyboard', 'hardware' },
        CAT_NETWORK => new List<String>{ 'vpn', 'wifi', 'network', 'internet', 'connection' }
    };
    private static final Map<String, String> QUEUES = new Map<String, String>{
        CAT_ACCESS => 'Access_IT',
        CAT_HARDWARE => 'Hardware_IT',
        CAT_NETWORK => 'Network_IT',
        CAT_GENERAL => 'General_IT'
    };

    public static String categorize(String subject, String body) {
        String text = ((subject == null ? '' : subject) + ' ' + (body == null ? '' : body)).toLowerCase();
        for (String category : new List<String>{ CAT_ACCESS, CAT_HARDWARE, CAT_NETWORK }) {
            for (String kw : KEYWORDS.get(category)) {
                if (text.contains(kw)) {
                    return category;
                }
            }
        }
        return CAT_GENERAL;
    }

    public static String queueNameFor(String category) {
        String name = QUEUES.get(category);
        return name == null ? QUEUES.get(CAT_GENERAL) : name;
    }

    public static void routeEmailCases(List<Case> cases) {
        List<Case> emailCases = new List<Case>();
        for (Case c : cases) {
            if (c.Origin == 'Email') {
                emailCases.add(c);
            }
        }
        if (emailCases.isEmpty()) {
            return;
        }
        Map<String, Id> queueIds = new Map<String, Id>();
        for (QueueSobject qs : [
            SELECT QueueId, Queue.DeveloperName FROM QueueSobject
            WHERE SobjectType = 'Case' AND Queue.DeveloperName IN :QUEUES.values()
        ]) {
            queueIds.put(qs.Queue.DeveloperName, qs.QueueId);
        }
        for (Case c : emailCases) {
            Id queueId = queueIds.get(queueNameFor(categorize(c.Subject, c.Description)));
            if (queueId != null) {
                c.OwnerId = queueId;
            }
        }
    }
}