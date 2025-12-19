exports.handler = async function(event, context) {
  // Strategy:
  // 1. Try to get path from 'path' query param (from netlify.toml rewrite)
  // 2. Fallback: Parse it from event.path (e.g. /cwa-proxy/fileapi/...)
  
  let targetPath = event.queryStringParameters.path;
  
  if (!targetPath) {
    // Fallback: strip /cwa-proxy/ prefix
    // event.path follows the request URL
    const prefix = "/cwa-proxy/";
    if (event.path && event.path.startsWith(prefix)) {
      targetPath = event.path.substring(prefix.length);
    }
  }

  if (!targetPath) {
    console.error("Missing path parameter. Event path:", event.path);
    return {
      statusCode: 400,
      body: JSON.stringify({ 
        error: "Missing path parameter", 
        debug_path: event.path,
        debug_qs: event.queryStringParameters 
      })
    };
  }

  // Reconstruct query parameters
  // Exclude 'path' since we used it for routing
  const params = new URLSearchParams();
  for (const key in event.queryStringParameters) {
    if (key !== 'path') {
      params.append(key, event.queryStringParameters[key]);
    }
  }

  const targetUrl = `https://opendata.cwa.gov.tw/${targetPath}?${params.toString()}`;
  console.log("Proxying to:", targetUrl);

  try {
    const response = await fetch(targetUrl, {
      redirect: 'follow'
    });
    
    if (!response.ok) {
        return {
            statusCode: response.status,
            body: `Upstream Error: ${response.statusText}`
        }
    }

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
    console.error("Fetch Error:", error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message })
    };
  }
};
