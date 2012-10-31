<?php 
$get = $_GET;
$base_url = 'https://coastalriskunderwriters.zendesk.com/api/v2/search.json?';

$default_params = array(
		'sort_order' => 'desc',
		'sort_by'    => 'created_at'
	);

$params = array_merge($get, $default_params);

// Safety fist
$safe_params = array(
		'query'      => $params['query'],
		'sort_order' => $params['sort_order'],
		'sort_by'    => $params['sort_by']
	);

$api_url = $base_url . http_build_query($safe_params);

$token = base64_encode("darren.newton@arc90.com:arc90zen");

$headers = array(
		"Authorization: {$token}",
		"Expect: "
	);

// Make API call
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $api_url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
$zen = curl_exec($ch);
curl_close($ch);

// Return as JSON
header('Content-Type: application/json');
echo $zen;
exit();
?>