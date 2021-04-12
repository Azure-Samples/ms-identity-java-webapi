// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

package com.microsoft.azure.msalobosample;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.microsoft.graph.models.User;
import com.microsoft.graph.requests.GraphServiceClient;
import okhttp3.Request;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class ApiController {

    @Autowired
    OboAuthProvider oboAuthProvider;

    @RequestMapping("/graphMeApi")
    public String graphMeApi() throws JsonProcessingException {

        GraphServiceClient<Request> graphClient = GraphServiceClient
                .builder()
                .authenticationProvider(oboAuthProvider)
                .buildClient();

        User user = graphClient.me().buildRequest().get();
        ObjectMapper objectMapper = new ObjectMapper();
        return objectMapper.writeValueAsString(user);
    }

}
