<?php
$attachurl = $_POST["url"];
$params = $_POST["params"];

$ch = curl_init();

error_log("Policy Central: Retrieving Attachment from " . $attachurl, 0);

//set the curl option parameters
curl_setopt($ch, CURLOPT_URL, $attachurl);
curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, false);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_VERBOSE, true);
curl_setopt($ch, CURLOPT_HEADER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, array(
    'X-Authorization: Basic ' . $params,
    'x-crippled-client: yes',
    'x-rest-method: GET',
    'X-Method: GET'
    ));

//execute post
$result = curl_exec($ch);

if (curl_errno($ch)) {
    error_log("Policy Central: " . curl_error($ch), 0);
    echo '<html>
              <body>
                  <br/><br/><br/>
                  <center>
                      <font style="font-family: Tahoma,sans-serif; font-size:18px;">
                      Error: There was a problem retrieving the document.<br/><br/>' . curl_error($ch) . '<br/><br/>If this problem persists, please contact support.
                      </font>
                  </center>
              </body>
          </html>';
    exit(1);
}

$header_size = curl_getinfo($ch, CURLINFO_HEADER_SIZE);
$result_header = trim(substr($result, 0, $header_size));
$result_body = substr($result, $header_size);

//close connection
curl_close($ch);

//break headers down into an associative array
$header_array = array();
$header_data = explode("\n", $result_header);
$header_array['status'] = $header_data[0];
array_shift($header_data);

foreach($header_data as $header_item) {
    $header_keyvalue = explode(":", $header_item);
    $header_array[trim(strtolower($header_keyvalue[0]))] = trim($header_keyvalue[1]);
}

error_log("Policy Central: Checking for JSON Object from ixLibrary...",0);
$attachment = json_decode($result_body);

//if the result is returned as a JSON object, the attachment is contained
//in the data key as a base64 encoded string
if (property_exists($attachment, "data")) {
    error_log("Policy Central: PDF sent from ixLibrary as JSON Object - Attachment generated from Base64 Data Key", 0);
    $binattach = base64_decode($attachment->data);
    //check JSON for content type. if it doesn't exist, default to octet-stream
    if (property_exists($attachment, "contentType")) {
        header('Content-Type: ' . $attachment->contentType);
    }
    else {
        header('Content-Type: application/octet-stream');
    }
    //header('Content-Disposition: inline; filename="document.pdf"');
    header('Content-Length: ' . strlen( $binattach ) );
    echo $binattach;
}
//if it is not an object, check the headers
else if (strpos($result_body, "%PDF-") === 0) {
    error_log("Policy Central: PDF sent from ixLibrary as DataStream - Proxy Passes Original Data", 0);
    $ct_header = $header_array['content-type'];
    error_log("Policy Central: ixLibary returned ContentType " . $ct_header);
    if (!empty($ct_header)) {
        header('Content-Type: ' . $ct_header);
    }
    else {
        header('Content-Type: application/octet-stream');
    }
    //header('Content-Disposition: inline; filename="document.pdf"');
    header('Content-Length: ' . strlen( $result_body ) );
    echo $result_body;
}
else if (strpos($header_array['status'], '200') !== FALSE) {
    error_log("Policy Central: NON-PDF response from ixLibrary Proxy Passes Original Data", 0);
    $ct_header = $header_array['content-type'];
    error_log("Policy Central: ixLibary returned Content-Type " . $ct_header);
    //Adding this because ixLibrary is returning the wrong Content-Type when
    //it does not find the requested document.
    if (strpos($result_body, '<h1>Document Not Found</h1>') !== FALSE) {
        error_log("Policy Central: ixLibary returned 'Document Not Found' message", 0);
        header('Content-Type: text/html');
        echo '<html>
                  <body>
                      <br/><br/><br/>
                      <center>
                          <font style="font-family: Tahoma,sans-serif; font-size:18px;">
                          An error occurred while retrieving the document.<br/><br/>' . $result_body . '<br/><br/>If this problem persists, please contact support.
                          </font>
                      </center>
                  </body>
             </html>';
        exit(1);
    }
    else if (!empty($ct_header)) {
        header('Content-Type: ' . $ct_header);
    }
    else {
        header('Content-Type: text/html');
    }
    header('Content-Length: ' . strlen( $result_body ) );
    echo $result_body;
}
else {
    error_log("Policy Central: Curl Request Status " . $header_array['status']);
    error_log("Policy Central: Error from ixLibrary - " . $result_body, 0);
    header('Content-Type: text/html');
    echo '<html>
          <body>
              <br/><br/><br/>
              <center>
                  <font style="font-family: Tahoma,sans-serif; font-size:18px;">
                  An error occurred while retrieving the document.<br/><br/>' . $result_body . '<br/><br/>If this problem persists, please contact support.
                  </font>
              </center>
          </body>
          </html>';
}

?>