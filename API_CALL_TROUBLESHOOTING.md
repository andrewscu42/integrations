# API Call Troubleshooting - Named Credential Access

## Issue
@future method runs as you (sculliwag@gmail.com) and works via anonymous apex, but fails when called via API with:
```
System.CalloutException: The callout couldn't access the endpoint. You might not have the required permissions, or the named credential "Stripe_API" might not exist.
```

## Root Cause
When calling via REST/SOAP API, even though the @future method runs as the same user, Named Credential access is checked differently in the API context.

## Solutions

### Solution 1: Verify Named Credential Configuration

1. Go to **Setup** > **Security** > **Named Credentials**
2. Find `Stripe_API`
3. Verify:
   - **Identity Type**: Should be "Named Principal" (not "Per User")
   - **Callout Status**: Enabled
   - **Generate Authorization Header**: Enabled

### Solution 2: Assign Named Credential to Profile

Even though @future runs as you, the Named Credential must be accessible:

1. Go to **Setup** > **Profiles**
2. Find your profile (the one for sculliwag@gmail.com)
3. Go to **App Permissions** > **Named Credentials**
4. Ensure `Stripe_API` is listed and enabled

### Solution 3: Use Permission Set (Recommended)

1. Go to **Setup** > **Permission Sets**
2. Create/Edit: "Stripe API Access"
3. **App Permissions** > **Named Credentials** > Add `Stripe_API`
4. Assign to your user:
   - **Setup** > **Users** > Find your user
   - **Permission Set Assignments** > Assign "Stripe API Access"

### Solution 4: Check API User Context

If calling via REST/SOAP API, verify:
- The API user has the same permissions
- The Named Credential is accessible to that user's profile
- The API user has the Permission Set assigned

## Debug Steps

1. **Check Debug Logs** - The updated code now logs:
   - User ID
   - User Name
   - User Email
   - Profile ID

2. **Verify Named Credential Name** - Ensure it's exactly `Stripe_API` (case-sensitive)

3. **Test Direct Call** - Try calling the Named Credential directly:
```apex
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:Stripe_API/v1/account');
req.setMethod('GET');
Http http = new Http();
HttpResponse res = http.send(req);
System.debug('Status: ' + res.getStatusCode());
```

## Common Issues

1. **Named Credential doesn't exist** - Create it in Setup
2. **Wrong Identity Type** - Should be "Named Principal" for API access
3. **Not assigned to Profile** - Add to your profile's Named Credentials
4. **Permission Set not assigned** - Assign the Permission Set to your user
5. **Case sensitivity** - Named Credential name must match exactly: `Stripe_API`

## Quick Fix Checklist

- [ ] Named Credential `Stripe_API` exists
- [ ] Identity Type is "Named Principal"
- [ ] Named Credential is enabled
- [ ] Named Credential is assigned to your Profile
- [ ] Permission Set with Named Credential is assigned to your user
- [ ] Test direct callout works

