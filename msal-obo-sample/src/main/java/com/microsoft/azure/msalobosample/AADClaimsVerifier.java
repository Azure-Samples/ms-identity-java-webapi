package com.microsoft.azure.msalobosample;
import org.springframework.security.oauth2.common.exceptions.InvalidTokenException;
import org.springframework.security.oauth2.provider.token.store.JwtClaimsSetVerifier;
import org.springframework.util.Assert;
import org.springframework.util.CollectionUtils;
import java.util.Arrays;
import java.util.Map;

public class AADClaimsVerifier implements JwtClaimsSetVerifier {
    private static final String ISS_CLAIM = "iss";

    private final String[] issuers;
    private final String resourceId;

    public AADClaimsVerifier(final String[] issuers, final String issuerTenant, final String resourceId) {
        // In production, you'd want to get a valid list of issuers from:
        // https://login.microsoftonline.com/common/discovery/instance?authorization_endpoint=https://login.microsoftonline.com/common/oauth2/v2.0/authorize&api-version=1.1
        // You must get all the values under the metadata[].aliases[] properties.

        Assert.notEmpty(issuers, "issuers cannot be empty");
        for (final String issuer : issuers) {
            Assert.notNull(issuer, "issuer cannot be null");
        }
        Assert.notNull(resourceId, "resourceId (audience) cannot be null");

        this.resourceId = resourceId;
        // prepend https:// and append tenantId. And then duplicate this and append
        // /v2.0
        this.issuers = this.addHttpsTenantIdAndV2Endpoints(issuers, issuerTenant);
    }

    private String[] addHttpsTenantIdAndV2Endpoints(final String[] issuers, final String issuerTenant) {
        final String[] issuersV2Included = new String[issuers.length * 2];
        for (int i = 0; i < issuers.length; i++) {
            issuers[i] = "https://" + issuers[i] + "/" + issuerTenant + "/";
            issuersV2Included[i] = issuers[i];
            issuersV2Included[issuers.length + i] = issuers[i] + "v2.0";
        }
        return issuersV2Included;
    }

    public void verify(final Map<String, Object> claims) throws InvalidTokenException {
        if (CollectionUtils.isEmpty(claims))
            throw new InvalidTokenException("token must contain claims");
        if (!claims.containsKey("iss"))
            throw new InvalidTokenException("token must contain issuer (iss) claim");
        if (!claims.containsKey("aud"))
            throw new InvalidTokenException("token must contain audience (aud) claim");

        final String jwtIssuer = (String) claims.get("iss");
        if (!Arrays.stream(this.issuers).anyMatch(x -> x.equals(jwtIssuer))) {
            throw new InvalidTokenException("Invalid Issuer (iss) claim: " + jwtIssuer);
        }

        final String jwtAud = (String) claims.get("aud");
        if (!jwtAud.equals(resourceId) && !jwtAud.equals("api://" + resourceId)) {
            throw new InvalidTokenException("Invalid Audience (aud) claim: " + jwtAud);
        }
        
    }
}
