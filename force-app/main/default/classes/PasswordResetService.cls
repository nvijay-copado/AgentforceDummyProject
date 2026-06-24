public with sharing class PasswordResetService {

    // INPUT WRAPPER
    public class ResetRequest {

        @InvocableVariable(required=true)
        public String username;
    }

    // OUTPUT WRAPPER
    public class ResetResponse {

        @InvocableVariable
        public String username;

        @InvocableVariable
        public Boolean success;

        @InvocableVariable
        public String message;
    }

    @InvocableMethod(label='Reset User Password')
    public static List<ResetResponse> resetPassword(
        List<ResetRequest> requests
    ) {

        List<ResetResponse> responses = new List<ResetResponse>();

        for(ResetRequest request : requests) {

            ResetResponse response = new ResetResponse();
            response.username = request.username;

            try {

                User usr = [
                    SELECT Id
                    FROM User
                    WHERE Username = :request.username
                    LIMIT 1
                ];

                System.resetPassword(usr.Id, true);

                response.success = true;
                response.message =
                    'Password reset email sent successfully';

            } catch(Exception e) {

                response.success = false;
                response.message = e.getMessage();
            }

            responses.add(response);
        }

        return responses;
    }
}