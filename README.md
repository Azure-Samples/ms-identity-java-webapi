---
page_type: sample
languages:
- java
products:
  - azure
  - azure-active-directory
  - java
description: "This sample demonstrates calling a downstream web API from another web API in Microsoft identity platform using the On-Behalf-Of flow"
urlFragment: ms-identity-java-webapi
---

# A Java Web API that calls another web API with the Microsoft identity platform using the On-Behalf-Of flow

## About this sample

### Overview

This sample demonstrates a Java web application calling a downstream Web API, [Microsoft Graph](https://graph.microsoft.com) using the [On-Behalf-Of](https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-on-behalf-of-flow) flow. All these are secured using the Microsoft identity platform.

1. The Java web application uses the [Microsoft Authentication Library for Java (MSAL4J)](https://github.com/AzureAD/microsoft-authentication-library-for-java) to obtain an Access token the Microsoft identity platform for the authenticated user.
2. The access token is used as a bearer token to authenticate the user when calling the Java Web API and then the Microsoft Graph API.

The flow is as follows:

1. Sign-in the user in the client(web) application.
1. Acquire a token for the Java Web API and call it.
1. The Java Web API then calls the Microsoft Graph using another access token obtained using the on-behalf-of flow.

### Scenario

This sample shows how to build a Java web app that uses OpenId Connect to sign in/ sign out an user and to get access to the Microsoft Graph using MSAL4J. And also shows how to use On-Behalf-Of flow to call an API with another service. For more information about how the protocols work in this scenario and other scenarios, see [Authentication Scenarios for Azure AD](https://docs.microsoft.com/en-us/azure/active-directory/develop/active-directory-authentication-scenarios),[Microsoft identity platform and OAuth 2.0 On-Behalf-Of flow](https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-on-behalf-of-flow).

## How to run this sample

To run this sample, you'll need:

- Working installation of Java and Maven
- An Internet connection
- An Azure Active Directory (Azure AD) tenant. For more information on how to get an Azure AD tenant, see [How to get an Azure AD tenant](https://azure.microsoft.com/en-us/documentation/articles/active-directory-howto-tenant/)
- A user account in your Azure AD tenant.

### Step 1: Download Java (8 and above) for your platform

To successfully use this sample, you need a working installation of [Java](https://openjdk.java.net/install/) and [Maven](https://maven.apache.org/).

### Step 2:  Clone or download this repository

From your shell or command line:

- `git clone https://github.com/Azure-Samples/ms-identity-java-webapi.git`

### Step 3:  Register the sample with your Azure Active Directory tenant

There are two projects in this sample. Each needs to be registered separately in your Azure AD tenant. To register these projects:

#### First step: choose the Azure AD tenant where you want to create your applications

As a first step you'll need to:

1. Sign in to the [Azure portal](https://portal.azure.com).
1. On the top bar, click on your account, and then on **Switch Directory**.
1. Once the *Directory + subscription* pane opens, choose the Active Directory tenant where you wish to register your application, from the *Favorites* or *All Directories* list.
1. In the portal menu click on **All services** and choose **Azure Active Directory**.

> In the next steps, you might need the tenant name (or directory name) or the tenant ID (or directory ID). These are presented in the **Properties** of the Azure Active Directory window respectively as *Name* and *Directory ID*

#### Register the Web Api app (java-webapi)

1. In the  **Azure Active Directory** menu blade, select **App registrations** and choose **New registration**.
1. Enter a friendly name for the application, for example 'java-webapi' and select **Accounts in any organizational directory and personal Microsoft Accounts (e.g. Skype, Xbox, Outlook.com)**.
1. Click **Register** to register the application.
1. On the app **Overview** page:
    - copy **Application (client) ID**
    - copy **Directory (tenant) ID**
    - You'll need both of these values later to configure the project, so save them in a safe place.

1. In the Application menu blade, select **Certificates & Secrets** and click on `New client secret` in the **Client Secrets** section:

   - Type a key description (for instance `app secret`).
   - Select one of the provided key durations as per your security needs.
   - Key value will be displayed when you click **Add**. Copy the value and save for later to configure the project. This key value will not be displayed again, nor retrievable by any other means, so record it as soon as it is visible in the Azure portal.

1. In the Application menu blade, select **Expose an API**, click on **Add a scope**
    - Accept the proposed **Application ID URI** (api://{clientId}) by selecting **save and continue**.
    - For **scope name** use **access_as_user**
    - Select **Admins and users** for **who can consent**.
    - In **Admin consent display name** type `Access Webapi as a user`
    - In **Admin consent description** type `Allow the application to access Webapi on behalf of the signed-in user.`
    - In **User consent display name** type `Access Webapi as a user`
    - In **User consent description** type `Allow the application to access Webapi on your behalf.`
    - Keep **State** as **Enabled**
    - Click **Add scope**.

#### Configure the **msal-obo-sample** to use your Azure AD tenant

Open `application.properties` in the src/main/resources folder. Fill in with your tenant and app registration information noted in the above registration step.

- Replace *Enter_the_Tenant_Info_Here* with  **Directory (tenant) ID**.
- *Enter_the_Application_Id_here* with the **Application (client) ID**.
- *Enter_the_Client_Secret_Here* with the **key value** noted earlier.

#### Register the client Web app (java-webapp)

1. In the **Azure Active Directory** menu blade, select **App registrations** and choose **New registration**.
1. Enter a friendly name for the application, for example 'java-webapp', select **Accounts in any organizational directory and personal Microsoft Accounts (e.g. Skype, Xbox, Outlook.com)**.
1. Click **Register** to register the application.
1. On the **Overview** page:
    - copy **Application (client) ID**
    - copy **Directory (tenant) ID**
    - You'll need both of these values later to configure the projects
1. In the Application menu blade, select the **Authentication** and under *Redirect URIs*, select **Web**.
    You will need to enter two different redirect URIs: one for the sign-In page, and one for the page that calls Graph. For both, you should use the same host and port number, then followed by */msal4jsample/secure/aad* for the sign in page and */msal4jsample/graph/me* for the user info page.
    To run this sample, enter the following two urls:

    - `http://localhost:8080/msal4jsample/secure/aad`.
    - `http://localhost:8080/msal4jsample/graph/me`

Click **save**.

1. In the Application menu blade, select **Certificates & Secrets** and click on `New client secret` in the **Client Secrets** section:

   - Type a key description (for instance `app secret`),
   - Select one of the provided key durations as per your security needs.
   - When you save this page, the key value will be displayed. Copy and save the value in a safe location. You'll need this key later to configure the project. This key value will not be displayed again, nor retrievable by any other means, so record it as soon as it is visible in the Azure portal.

1. In the Application menu blade, select **API Permissions**:
   - Click the **Add a permission** button,
   - Select the **My APIs** tab,
   - In the list of APIs, select the API `Web Api app`,
   - In the **Delegated permissions** section, ensure that the right permissions are checked: **access_as_user**,
   - Select the **Add permissions** button.

#### Configure the **msal-web-sample** to use your Azure AD tenant

Open `application.properties` in the src/main/resources folder. Fill in with your tenant and app registration information noted in registration step.

- Replace *Enter_the_Application_Id_here* with the **Application (client) ID**.
- Replace *Enter_the_Client_Secret_Here* with the **key value** noted earlier.
- Replace *OboApi* with the API exposed in the `Web Api app` **(api://{clientId})**.

#### Configure known client applications for service (java-webapi)

For the middle tier web API (`java-webapi`) to be able to call the downstream web APIs, the user must grant the middle tier permission to do so in the form of consent.
However, since the middle tier has no interactive UI of its own, you need to explicitly bind the client app registration in Azure AD, with the registration for the web API.
This binding merges the consent required by both the client and middle tier into a single dialog, which will be presented to the user by the client for the first time when the user signs-in.
You can do so by adding the "Client ID" of the client app, to the manifest of the web API in the `knownClientApplications` property. Here's how:

In the [Azure portal](https://portal.azure.com), navigate to your `java-webapi` app registration:

- In the Application menu blade, select **Manifest**.
- Find the attribute **knownClientApplications** and add your client application's(`java-webapp`) **Application (client) Id** as its element.
- Click **Save**.

### Step 4: Run the applications

To run the project, you can either:

Run it directly from your IDE by using the embedded spring boot server or package it to a WAR file using [maven](https://maven.apache.org/plugins/maven-war-plugin/usage.html) and deploy it a J2EE container solution for example [Tomcat](https://tomcat.apache.org/maven-plugin-trunk/tomcat6-maven-plugin/examples/deployment.html)

#### Running from IDE

If you are running the application from an IDE, follow the steps below.

The following steps are for IntelliJ IDEA. But you can choose and work with any editor of your choice.

1. Navigate to *Run* --> *Edit Configurations* from menu bar.
2. Click on '+' (Add new configuration) and select *Application*.
3. Enter name of the application for example `webapp`
4. Go to main class and select from the dropdown, for example `MsalWebSampleApplication` also go to *Use classpath of the module* and select from the dropdown, for example `msal-web-sample`.
5. Click on *Apply*. Follow the same instructions for adding the another application.
6. Click on '+' (Add new configuration) and select *Compound*.
7. Enter a friendly name for in the *Name* for example `Msal-webapi-sample`.
8. Click on '+' and select the application names you have created in the above steps one at a time.
9. Click on *Apply*. Select the created configuration and click **Run**. Now both the projects will run at a time.

- Now navigate to the home page of the project. For this sample, the standard home page URL is <http://localhost:8080>

#### Packaging and deploying to container

If you would like to deploy the sample to Tomcat, you will need to make a couple of changes to the source code in both modules.

1. Open msal-webapp-sample/pom.xml
    - Under `<name>msal-web-sample</name>` add `<packaging>war</packaging>`
    - Add dependency:

         ```xml
         <dependency>
          <groupId>org.springframework.boot</groupId>
          <artifactId>spring-boot-starter-tomcat</artifactId>
          <scope>provided</scope>
         </dependency>
         ```

2. Open msal-web-sample/src/main/java/com.microsoft.azure.msalwebsample/MsalWebSampleApplication

    - Delete all source code and replace with

    ```Java
        package com.microsoft.azure.msalwebsample;

        import org.springframework.boot.SpringApplication;
        import org.springframework.boot.autoconfigure.SpringBootApplication;
        import org.springframework.boot.builder.SpringApplicationBuilder;
        import org.springframework.boot.web.servlet.support.SpringBootServletInitializer;

        @SpringBootApplication
        public class MsalWebSampleApplication extends SpringBootServletInitializer {
         public static void main(String[] args) {
          SpringApplication.run(MsalWebSampleApplication.class, args);
         }

         @Override
         protected SpringApplicationBuilder configure(SpringApplicationBuilder builder) {
          return builder.sources(MsalWebSampleApplication.class);
         }
        }
    ```

3. Open a command prompt, go to the root folder of the project, and run `mvn package`

- This will generate a `msal-web-sample-0.1.0.war` file in your /targets directory.
- Rename this file to `ROOT.war`
- Deploy this war file using Tomcat or any other J2EE container solution.
- To deploy on Tomcat container, copy the .war file to the webapps folder under your Tomcat installation and then start the Tomcat server.
- Repeat these steps for the `msal-obo-sample` also.

This WAR will automatically be hosted at `http:<yourserverhost>:<yourserverport>/`

Tomcats default port is 8080. This can be changed by
    - Going to tomcat/conf/server.xml
    - Search "Connector Port"
    - Replace "8080" with your desired port number

Example: `http://localhost:8080/msal4jsample`

### You're done, run the code

Click on "Login" to start the process of logging in. Once logged in, you'll see the account information for the user that is logged in and a Button "Call OBO API" , which will call the Microsoft Graph API with the OBO token and display the basic information of the signed-in user. You'll then have the option to "Sign out".

## About the Code

There are many key points in this sample to make the On-Behalf-Of-(OBO) flow work properly and in this section we will explain these key points for each project.

### msal-webapp-sample

1. AuthPageController class

    Contains the api to interact with the web app. The securePage method handles the authentication part and signs in the user using microsoft authentication.

2. AuthHelper class

    Contains helper methods to handle authentication.

    A code snippet showing how to obtain auth result by silent flow.

    ```java

        private ConfidentialClientApplication createClientApplication() throws MalformedURLException {
            return ConfidentialClientApplication.builder(clientId, ClientCredentialFactory.create(clientSecret))
                                                .authority(authority)
                                                .build();
        }...

          SilentParameters parameters = SilentParameters.builder(
                        Collections.singleton(scope),
                        result.account()).build();

                CompletableFuture<IAuthenticationResult> future = app.acquireTokenSilently(parameters);
                ...

        storeTokenCacheInSession(httpRequest, app.tokenCache().serialize());
        ...
    ```

    Important things to notice:

    - We create a `ConfidentialClientApplication` using **MSAL Build Pattern** passing the `clientId`, `clientSecret` and `authority` in the builder. This `ConfidentialClientApplication` will be responsible of acquiring access tokens later in the code.
    - `ConfidentialClientApplication` also has a token cache, that will cache [access tokens](https://docs.microsoft.com/en-us/azure/active-directory/develop/access-tokens) and [refresh tokens](https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-auth-code-flow#refresh-the-access-token) for the signed-in user. This is done so that the application can fetch access tokens after they have expired without prompting the user to sign-in again.

3. AuthFilter class

    Contains methods for session and state management.

### msal-obo-sample

1. ApiController class

    Contains the api(graphMeApi) to trigger the obo flow. The graphMeApi method gets the obo access token using MsalAuthHelper. The callMicrosoftGraphEndPoint method calls the Microsoft graph API using obo token.

    ```java
    String oboAccessToken = msalAuthHelper.getOboToken("https://graph.microsoft.com/.default");

        return callMicrosoftGraphMeEndpoint(oboAccessToken);
    ```

    Important things to notice:

    - The scope [.default](https://docs.microsoft.com/en-us/azure/active-directory/developv2-permissions-and-consent#the-default-scope) is a built-in scope for every application that refers to the static list of permissions configured on the application registration. In our scenario here, it enables the user to grant consent for permissions for both the Web API and the downstream API (Microsoft Graph). For example, the permissions for the Web API and the downstream API (Microsoft Graph) are listed below:
             - Web Api sample (access_as_user)
             - Microsoft Graph (user.read)

    - When you use the `.default` scope, the end user is prompted for a combined set of permissions that include scopes from both the **Web Api** and **Microsoft Graph**.

2. SecurityResourceServerConfig class

    Token Validation happens in this class, where the auth token is validated and an access token is obtained which is used to obtain obo token to complete the obo flow.

    ```java
            http
            .sessionManagement().sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            .and()
            .authorizeRequests()
            .antMatchers("/*")
            .access("#oauth2.hasScope('" + accessAsUserScope + "')"); // required scope to access /api URL
    ```

3. MsalAuthHelper class

    Contains the methods to obtain the auth token and obo token to enable on-behalf-of flow.

    A code snippet showing how to obtain obo token

    ```java
                OnBehalfOfParameters parameters =
                    OnBehalfOfParameters.builder(Collections.singleton(scope),
                            new UserAssertion(authToken))
                            .build();

            auth = application.acquireToken(parameters).join();
    ```

## Feedback, Community Help and Support

Use [Stack Overflow](http://stackoverflow.com/questions/tagged/adal) to get support from the community.
Ask your questions on Stack Overflow first and browse existing issues to see if someone has asked your question before.
Make sure that your questions or comments are tagged with [`msal4j` `Java`].

If you find a bug in the sample, please raise the issue on [GitHub Issues](https://github.com/Azure-Samples/ms-identity-java-webapp/issues).

To provide a recommendation, visit the following [User Voice page](https://feedback.azure.com/forums/169401-azure-active-directory).

## Contributing

If you'd like to contribute to this sample, see [CONTRIBUTING.MD](https://github.com/Azure-Samples/ms-identity-java-webapp/blob/master/CONTRIBUTING.md).

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information, see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Other samples and documentation

- For more information, see MSAL4J [conceptual documentation](https://github.com/AzureAD/azure-activedirectory-library-for-java/wiki)
- Other samples for Microsoft identity platform are available from [https://aka.ms/aaddevsamplesv2](https://aka.ms/aaddevsamplesv2)
- [Microsoft identity platform and OAuth 2.0 On-Behalf-Of flow](https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-on-behalf-of-flow)
- the documentation for Microsoft identity platform is available from [https://aka.ms/aadv2](https://aka.ms/aadv2)
- For more information about web apps scenarios on the Microsoft identity platform see [Scenario: Web app that signs in users](https://docs.microsoft.com/en-us/azure/active-directory/develop/scenario-web-app-sign-user-overview) and [Scenario: Web app that calls web APIs](https://docs.microsoft.com/en-us/azure/active-directory/develop/scenario-web-app-call-api-overview)
- [Why update to Microsoft identity platform?](https://docs.microsoft.com/en-us/azure/active-directory/develop/azure-ad-endpoint-comparison)
For more information about how OAuth 2.0 protocols work in this scenario and other scenarios, see [Authentication Scenarios for Azure AD](http://go.microsoft.com/fwlink/?LinkId=394414).