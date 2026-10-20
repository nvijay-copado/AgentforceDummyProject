public with sharing class ERPCalloutService {
    public static final String NAMED_CREDENTIAL = 'callout:ERP_Named_Credential';

    public class ERPCalloutException extends Exception {}

    public static HttpResponse get(String path) {
        return send('GET', path, null);
    }

    public static HttpResponse post(String path, String body) {
        return send('POST', path, body);
    }

    private static HttpResponse send(String method, String path, String body) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(NAMED_CREDENTIAL + (String.isBlank(path) ? '' : path));
        req.setMethod(method);
        req.setTimeout(30000);
        req.setHeader('Content-Type', 'application/json');
        if (body != null) {
            req.setBody(body);
        }
        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
            throw new ERPCalloutException('ERP callout failed: ' + res.getStatusCode());
        }
        return res;
    }
}