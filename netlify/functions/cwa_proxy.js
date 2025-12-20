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

    const jsonText = await response.text();
    let jsonData;
    try {
      jsonData = JSON.parse(jsonText);
    } catch (e) {
      console.error("JSON Parse Error:", e);
      return {
          statusCode: 200,
          headers: { "Content-Type": "application/json" },
          body: jsonText 
      };
    }

    // [Critical Fix for 6MB Limit] 
    // Filter data Server-Side based on client request.
    // The client sends ?locationName=...
    // If missing, default to "向陽山" (Xiangyang Mountain) as a fallback.
    const targetLocationName = event.queryStringParameters.locationName || "向陽山";
    
    // Navigate the JSON structure: cwaopendata -> dataset -> locations -> location[]
    if (jsonData?.cwaopendata?.dataset?.locations?.location) {
      const locations = jsonData.cwaopendata.dataset.locations.location;
      
      // Find the specific location
      const targetLoc = locations.find(l => l.locationName === targetLocationName);

      if (targetLoc) {
        // Construct minimized response
        const minimizedData = {
          cwaopendata: {
            dataset: {
              locations: {
                location: [targetLoc]
              }
            }
          }
        };
        
        console.log(`Filtered data for ${targetLocationName}. Size reduced.`);
        
        return {
          statusCode: 200,
          headers: {
            "Access-Control-Allow-Origin": "*",
            "Content-Type": "application/json"
          },
          body: JSON.stringify(minimizedData)
        };
      } else {
         console.warn(`Location ${targetLocationName} not found in API response.`);
         // Optional: Return 404 or empty structure? 
         // For now, let it fall through to original (which implies failure if too big)
         // or better, return an empty friendly response to avoid 502 crash
         return {
             statusCode: 404, // Not Found
             headers: { "Content-Type": "application/json" },
             body: JSON.stringify({ error: `Location '${targetLocationName}' not found in weather data.` })
         };
      }
    }
    
    // Fallback: If structure doesn't match or location not found, return original
    // (This will likely fail with 502 again if too big, but it's the only option)
    return {
      statusCode: 200,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Content-Type": "application/json"
      },
      body: jsonText
    };

  } catch (error) {
    console.error("Fetch Error:", error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message })
    };
  }
};
