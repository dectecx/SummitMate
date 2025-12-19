exports.handler = async function(event, context) {
  // Construct the target URL
  // The client hits /.netlify/functions/cwa_proxy?path=...&Authorization=...
  // Or we stick to the /cwa-proxy/ path rewrite.
  
  // Strategy:
  // Client: /cwa-proxy/fileapi/v1/opendataapi/F-B0053-033?Authorization=...
  // Redirect Rule in netlify.toml: /cwa-proxy/*  /.netlify/functions/cwa_proxy?path=:splat
  
  // So 'event.queryStringParameters.path' will contain "fileapi/v1/opendataapi/F-B0053-033"
  // And other query params (Authorization, etc.) will be in event.queryStringParameters
  
  const path = event.queryStringParameters.path;
  const auth = event.queryStringParameters.Authorization;
  const format = event.queryStringParameters.format;
  const downloadType = event.queryStringParameters.downloadType;
  
  if (!path) {
    return {
      statusCode: 400,
      body: "Missing path parameter"
    };
  }

  const targetUrl = `https://opendata.cwa.gov.tw/${path}?Authorization=${auth}&format=${format}&downloadType=${downloadType}`;
  
  try {
    const response = await fetch(targetUrl, {
      redirect: 'follow'
    });
    
    const data = await response.text();
    
    return {
      statusCode: 200,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Content-Type": "application/json"
      },
      body: data
    };
  } catch (error) {
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message })
    };
  }
};
