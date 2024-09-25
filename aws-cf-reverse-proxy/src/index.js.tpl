"use strict";

exports.handler = async (event) => {
  const request = event.Records[0].cf.request;
  console.log("Request received:", JSON.stringify(request));

  // Load the redirect URL and HTTP code from environment variables
  const redirectUrlBase = "${REDIRECT_URL}";
  const redirectHttpCode = "${REDIRECT_HTTP_CODE}" || "302"; // Default to 302 if not set

  // Construct the full redirect URL with the URI and query string
  const redirectUrl = redirectUrlBase + request.uri;
  const queryString = request.querystring ? "?" + request.querystring : "";

  const newUrl = redirectUrl + queryString;
  console.log("Redirecting to:", newUrl, "with status code:", redirectHttpCode);

  // Return the redirect response
  const response = {
    status: redirectHttpCode,
    statusDescription: "Found",
    headers: {
      location: [
        {
          key: "Location",
          value: newUrl,
        },
      ],
    },
  };

  return response;
};
