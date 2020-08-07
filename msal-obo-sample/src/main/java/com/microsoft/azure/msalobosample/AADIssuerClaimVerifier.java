package com.microsoft.azure.msalobosample;
import org.springframework.security.oauth2.common.exceptions.InvalidTokenException;
import org.springframework.security.oauth2.provider.token.store.JwtClaimsSetVerifier;
import org.springframework.util.Assert;
import org.springframework.util.CollectionUtils;
import java.util.Arrays;
import java.util.Map;

public class AADIssuerClaimVerifier implements JwtClaimsSetVerifier {
    private static final String ISS_CLAIM = "iss";

    private String[] issuers;

    public AADIssuerClaimVerifier(String[] issuers, String issuerTenant) {
        // In production, you'd want to get a valid list of issuers from:
        // https://login.microsoftonline.com/common/discovery/instance?authorization_endpoint=https://login.microsoftonline.com/common/oauth2/v2.0/authorize&api-version=1.1
        // You must get all the values under the metadata[].aliases[] properties.

        Assert.notEmpty(issuers, "issuers cannot be empty");
        for (String issuer: issuers ) {
            Assert.notNull(issuer, "issuer cannot be null");
        }

        // prepend https:// and append tenantId. And then duplicate this and append /v2.0
        this.issuers = this.addHttpsTenantIdAndV2Endpoints(issuers, issuerTenant);
    }

    private String[] addHttpsTenantIdAndV2Endpoints(String[] issuers, String issuerTenant) {
        String[] issuersV2Included = new String[issuers.length * 2];
        for (int i = 0; i < issuers.length; i++) {
            issuers[i] = "https://" + issuers[i] + "/" + issuerTenant;
            issuersV2Included[i] = issuers[i];
            issuersV2Included[issuers.length+i] = issuers[i] + "/v2.0";
        }
        return issuersV2Included;
    }

    public void verify(Map<String, Object> claims) throws InvalidTokenException {
        if (!CollectionUtils.isEmpty(claims) && claims.containsKey("iss")) {
            String jwtIssuer = (String)claims.get("iss");
            if (!Arrays.stream(this.issuers).anyMatch(x -> x.equals(jwtIssuer))) {
                throw new InvalidTokenException("Invalid Issuer (iss) claim: " + jwtIssuer);
            }
        }

    }
}
