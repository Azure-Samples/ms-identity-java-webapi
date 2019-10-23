---
page_type: sample
languages:
- java
- powershell
- html
products:
- azure-active-directory
description: "This sample demonstrates a Java web application calling an OBO service, which in turn calls Microsoft Graph API using the On-Behalf-Of flow which are all secured by Microsoft identity platform."
urlFragment: ms-identity-java-webapi
---

# A Java Web API that calls another web API with the Microsoft identity platform using the On-Behalf-Of flow

## About this sample

### Overview

This sample demonstrates a Java web application calling an OBO service, which in turn call the [Microsoft Graph](https://graph.microsoft.com) using the On_Behalf_Of flow. All these are secured using the Microsoft identity platform.

1. The Java web application uses the Microsoft Authentication Library for Java (MSAL4J) to obtain an Access token from Azure Active Directory(AD) for authenticated users.
2. The access token is used as a bearer token to authenticate the user when calling the Java Web API and the Microsoft Graph API.

The flow is as follows:

1. Sign-in the user in the client(web) application
1. Acquire a token to the Java Web API and call it.
1. The Java Web API then calls another downstream Web API (The Microsoft Graph).

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

There are two projects in this sample. Each needs to be separately registered in your Azure AD tenant. To register these projects, you can:

- either follow the steps in the paragraphs below
- or use PowerShell scripts that:
  - **automatically** create for you the Azure AD applications and related objects (passwords, permissions, dependencies) and modify the application configuration files manually.

If you want to use this automation, read the instructions in [App Creation Scripts](./AppCreationScripts/AppCreationScripts.md).

#### First step: choose the Azure AD tenant where you want to create your applications

As a first step you'll need to:

1. Sign in to the [Azure portal](https://portal.azure.com).
1. On the top bar, click on your account, and then on **Switch Directory**.
1. Once the *Directory + subscription* pane opens, choose the Active Directory tenant where you wish to register your
application, from the *Favorites* or *All Directories* list.
1. Click on **All services** in the left-hand nav, and choose **Azure Active Directory**.

> In the next steps, you might need the tenant name (or directory name) or the tenant ID (or directory ID). These are
presented in the **Properties** of the Azure Active Directory window respectively as *Name* and *Directory ID*

#### Register the webapp (Webapp-Openidconnect)

1. In the  **Azure Active Directory** pane, click on **App registrations** and choose **New registration**.
1. Enter a friendly name for the application, for example 'java-webapp', select "Accounts in any organizational directory
and personal Microsoft Accounts (e.g. Skype, Xbox, Outlook.com)".
1. Click **Register** to register the application.
1. On the left hand menu, click on **Overview** and :
    - copy **Application (client) ID**
    - copy **Directory (tenant) ID**
    - You'll need both of these values later to configure the project, so put them in a safe place
1. On the left hand menu, click on **Authentication**, and under *Redirect URIs*, select "Web". You will need to enter
 two different redirect URIs: one for the signIn page, and one for the graph page. For both, you should use the same
 host and port number, then followed by "/msal4jsample/secure/aad" for the sign in page and
 "msal4jsample/graph/me" for the user info page.
  By default, the sample uses:

    - `http://localhost:8080/msal4jsample/secure/aad`.
    - `http://localhost:8080/msal4jsample/graph/me`

Click on **save**.

1. On the left hand menu, choose **Certificates & Secrets** and click on `New client secret` in the **Client Secrets** section:

   - Type a key description (of instance `app secret`),
   - Select a key duration of either **In 1 year**, **In 2 years**, or **Never Expires**.
   - When you save this page, the key value will be displayed, copy, and save the value in a safe location.
   - You'll need this key later to configure the project. This key value will not be displayed again, nor retrievable by
   any other means, so record it as soon as it is visible from the Azure portal.

#### Configure the msal-webapp-sample to use your Azure AD tenant

Open `application.properties` in the src/main/resources folder. Fill in with your tenant and app registration information noted in registration step. Replace *Enter_the_Tenant_Id_Here* with the tenant id, *Enter_the_Application_Id_here* with the Application Id and *Enter_the_Client_Secret_Here* with the key value noted.

If you did not use the  default redirect URIs, then you'll have to update `aad.redirectUriSignin` and `aad.redirectUriGraph` as well with the registered redirect URIs.
> You can use any host and port number, but the path must stay the same (/msal4jsample/secure/aad and /msal4jsample/graph/me)
as these are mapped to the controllers that will process the requests.

#### Register the webapi app

1. In the  **Azure Active Directory** pane, click on **App registrations** and choose **New registration**.
1. Enter a friendly name for the application, for example 'java-webapi', select "Accounts in any organizational directory
and personal Microsoft Accounts (e.g. Skype, Xbox, Outlook.com)".
1. Click **Register** to register the application.
1. On the left hand menu, click on **Overview** and :
    - copy **Application (client) ID**
    - copy **Directory (tenant) ID**
    - You'll need both of these values later to configure the project, so put them in a safe place.

1. On the left hand menu, choose **Certificates & Secrets** and click on `New client secret` in the **Client Secrets** section:

   - Type a key description (of instance `app secret`),
   - Select a key duration of either **In 1 year**, **In 2 years**, or **Never Expires**.
   - When you save this page, the key value will be displayed, copy, and save the value in a safe location.
   - You'll need this key later to configure the project. This key value will not be displayed again, nor retrievable by
   any other means, so record it as soon as it is visible from the Azure portal.

#### Configure the msal-obo-sample to use your Azure AD tenant

Open `application.properties` in the src/main/resources folder. Fill in with your tenant and app registration information noted in registration step. Replace *Enter_the_Tenant_Id_Here* with the *Tenant Id*, *Enter_the_Application_Id_here* with the *Application Id* and *Enter_the_Client_Secret_Here* with the *key value* noted.

### Step 4: Run the application

To run the project, you can either:

- Run it directly from your IDE by using the embedded spring boot server
- or package it to a WAR file using [maven](https://maven.apache.org/plugins/maven-war-plugin/usage.html) and deploy it a J2EE container solution for example [Tomcat](https://tomcat.apache.org/maven-plugin-trunk/tomcat6-maven-plugin/examples/deployment.html)

#### Running from IDE

If you are running the application from an IDE, follow the steps below.

The following steps are for IntelliJ IDEA. But you can choose and work with any editor of your choice.

1. Navigate to *Run* --> *Edit Configurations* from menu bar.
2. Click on '+' (Add new configuration) and select *Application*.
3. Enter name of the application for example 'webapp'
4. Go to main class and select from the dropdown, for example 'MsalWebSampleApplication' also go to *Use classpath of the module* and select from the dropdown, for example 'msal-web-sample'.
5. Click on *Apply*. Follow the same instructions for adding the another application.
6. Click on '+' (Add new configuration) and select *Compound*.
7. Enter a friendly name for in the *Name* for example 'Msal-webapi-sample'.
8. Click on '+' and select the application names you have created in the above steps one at a time.
9. Click on *Apply*. Select the created configuration and click *Run*. Now both the projects will run at a time.

- Now navigate to the home page of the project. For this sample, the standard home page URL is <http://localhost:8080

##### Packaging and deploying to container

If you would like to deploy the sample to Tomcat, you will need to make a couple of changes to the source code in both modules.

1. Open msal-webapp-sample/pom.xml
    - Under `<name>msal-webapp-sample</name>` add `<packaging>war</packaging>`
    - Add dependency:

         ```xml
         <dependency>
          <groupId>org.springframework.boot</groupId>
          <artifactId>spring-boot-starter-tomcat</artifactId>
          <scope>provided</scope>
         </dependency>
         ```

2. Open msal-webapp-sample/src/main/java/com.microsoft.azure.msalwebappsample/MsalWebAppSampleApplication

    - Delete all source code and replace with

    ```Java
        package com.microsoft.azure.msalwebappsample;

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

- This will generate a `msal-webapi-sample-0.1.0.war` file in your /targets directory.
- Rename this file to `ROOT.war`
- Deploy this war file using Tomcat or any other J2EE container solution.
- To deploy on Tomcat container, copy the .war file to the webapis folder under your Tomcat installation and then start the Tomcat server.

This WAR will automatically be hosted at `http:<yourserverhost>:<yourserverport>/`

Tomcats default port is 8080. This can be changed by
    - Going to tomcat/conf/server.xml
    - Search "Connector Port"
    - Replace "8080" with your desired port number

Example: `http://localhost:8080/msal4jsample`

### You're done

Click on "Login" to start the process of logging in. Once logged in, you'll see the account information for the user that is logged in and a Button "Call OBO API" , which will call the Microsoft Graph API with the OBO token and display the basic information of the signed-in user. You'll then have the option to "Sign out".

## About the Code

There are many key points in this sample to make the On-Behalf-Of-(OBO) flow work properly and in this section we will explain these key points for each project.

### msal-webapp-sample

1. AuthPageController class

    Contains the api to interact with the web app. The securePage method handles the authentication part and signs in the user using microsoft authentication

2. AuthHelper class

    Contains helper methods to handle authentication

    A code snippet showing how to obtain auth result

    ```java
          SilentParameters parameters = SilentParameters.builder(
                        Collections.singleton(scope),
                        result.account()).build();

                CompletableFuture<IAuthenticationResult> future = app.acquireTokenSilently(parameters);

                updatedResult = future.get();
    ```

3. AuthFilter class

    Contains method for session and state management

### msal-obo-sample

1. ApiController class

    Contains the api(graphMeApi) to trigger the obo flow. The graphMeApi method gets the obo access token using MsalAuthHelper. The callMicrosoftGraphEndPoint method calls the Microsoft graph API using obo token.

2. SecurityResourceServerConfig class

    Token Validation happens in this class, where the auth token is validated and an access token is obtained  which is used to obtain obo     token to complete the obo flow.

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
Make sure that your questions or comments are tagged with [`msal` `Java`].

If you find a bug in the sample, please raise the issue on [GitHub Issues](https://github.com/Azure-Samples/ms-identity-java-webapp/issues).

To provide a recommendation, visit the following [User Voice page](https://feedback.azure.com/forums/169401-azure-active-directory).

## Contributing

If you'd like to contribute to this sample, see [CONTRIBUTING.MD](https://github.com/Azure-Samples/ms-identity-java-webapp/blob/master/CONTRIBUTING.md).

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information, see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## More information

- For more information, see MSAL4J [conceptual documentation](https://github.com/AzureAD/azure-activedirectory-library-for-java/wiki)

- Other samples for the Microsoft identity platform are available from [Microsoft identity platform code samples](https://aka.ms/aaddevsamplesv2).

- For more information about web apps scenarios on the Microsoft identity platform see [Scenario: Web app that signs in users](https://docs.microsoft.com/en-us/azure/active-directory/develop/scenario-web-app-sign-user-overview) and [Scenario: Web app that calls web APIs](https://docs.microsoft.com/en-us/azure/active-directory/develop/scenario-web-app-call-api-overview)

- For more information about how OAuth 2.0 protocols work in this scenario and other scenarios, see [Authentication Scenarios for Azure AD](http://go.microsoft.com/fwlink/?LinkId=394414).
