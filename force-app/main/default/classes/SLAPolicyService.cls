/**
 * Loads SLA policies from SLA_Policy__mdt (once per transaction) and holds the pure
 * date and status calculations used by the Case trigger handler and the escalation service.
 */
public with sharing class SLAPolicyService {
    public static final String FALLBACK_PRIORITY = 'Low';
    public static final String STATUS_ON_TRACK = 'On Track';
    public static final String STATUS_AT_RISK = 'At Risk';
    public static final String STATUS_BREACHED = 'Breached';
    public static final String STATUS_MET = 'Met';
    public static final String STATUS_PAUSED = 'Paused';

    public class Policy {
        public String priority;
        public Decimal resolutionHours;
        public Decimal atRiskPct;
        public Integer maxLevel;
        public String queueName;
        public String pauseStatus;
    }

    @TestVisible
    private static Map<String, Policy> policies;

    public static Policy getPolicy(String priority) {
        Map<String, Policy> all = load();
        if (priority != null && all.containsKey(priority)) {
            return all.get(priority);
        }
        if (all.containsKey(FALLBACK_PRIORITY)) {
            return all.get(FALLBACK_PRIORITY);
        }
        return defaultPolicy();
    }

    /** Due date = start + (resolution hours + paused hours), rounded to the nearest minute. */
    public static Datetime calculateDueDate(Datetime startDate, Policy policy, Decimal pausedHours) {
        Decimal hours = policy.resolutionHours + (pausedHours == null ? 0 : pausedHours);
        Long minutes = (hours * 60).round(System.RoundingMode.HALF_UP);
        return startDate.addMinutes(minutes.intValue());
    }

    /**
     * Pure status evaluation.
     * Closed: stays Breached if already breached or closed late, otherwise Met.
     * Open: Breached when past due, At Risk at or above the threshold percentage, else On Track.
     */
    public static String evaluateStatus(
        Datetime startDate,
        Datetime dueDate,
        Datetime now,
        Decimal atRiskPct,
        Boolean isClosed,
        String currentStatus
    ) {
        if (isClosed) {
            if (currentStatus == STATUS_BREACHED || now > dueDate) {
                return STATUS_BREACHED;
            }
            return STATUS_MET;
        }
        if (currentStatus == STATUS_PAUSED) {
            return STATUS_PAUSED;
        }
        if (now > dueDate) {
            return STATUS_BREACHED;
        }
        Decimal window = Decimal.valueOf(dueDate.getTime() - startDate.getTime());
        if (window > 0) {
            Decimal elapsed = Decimal.valueOf(now.getTime() - startDate.getTime());
            if ((elapsed * 100) / window >= atRiskPct) {
                return STATUS_AT_RISK;
            }
        }
        return STATUS_ON_TRACK;
    }

    private static Map<String, Policy> load() {
        if (policies == null) {
            policies = new Map<String, Policy>();
            for (SLA_Policy__mdt record : SLA_Policy__mdt.getAll().values()) {
                if (String.isBlank(record.Priority__c)) {
                    continue;
                }
                Policy p = new Policy();
                p.priority = record.Priority__c;
                p.resolutionHours = record.Resolution_Hours__c == null ? 72 : record.Resolution_Hours__c;
                p.atRiskPct = record.At_Risk_Threshold_Pct__c == null ? 80 : record.At_Risk_Threshold_Pct__c;
                p.maxLevel = record.Max_Escalation_Level__c == null ? 3 : record.Max_Escalation_Level__c.intValue();
                p.queueName = record.Escalation_Queue_DeveloperName__c;
                p.pauseStatus = String.isBlank(record.Pause_Status__c) ? 'Waiting on Customer' : record.Pause_Status__c;
                policies.put(p.priority, p);
            }
        }
        return policies;
    }

    private static Policy defaultPolicy() {
        Policy p = new Policy();
        p.priority = FALLBACK_PRIORITY;
        p.resolutionHours = 72;
        p.atRiskPct = 80;
        p.maxLevel = 3;
        p.pauseStatus = 'Waiting on Customer';
        return p;
    }
}