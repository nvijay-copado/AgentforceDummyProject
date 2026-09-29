/**
 * @description Provides a simple dummy message utility used to validate the
 * Dev2 Meta 10 Apex deployment/commit pipeline.
 */
public with sharing class DummyDev2Meta102 {
    /**
     * @description Returns the dummy confirmation message for the Dev2 Meta 10 commit.
     * @return String containing the dummy commit confirmation message.
     */
    public static String getMessage() {
        return 'Dev2 Meta 10 dummy Apex commit.';
    }
}