<?php

ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

$if_eno1=exec("/sbin/ifconfig eno1 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'");
$if_wlp2s0=exec("/sbin/ifconfig wlp2s0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'");

$streams = object_read_url('http://localhost:1985/api/v1/streams/');
$streams['push'] = array(
	'rtmp://'.$if_eno1.'/[app]/[stream]',
	'rtmp://'.$if_wlp2s0.'/[app]/[stream]',
);

jsonp_nocache_exit($streams);

///////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////

function jsonp_nocache_exit($output)
{
	set_nocache();
	echo jsonp($output);
	exit();
}

function set_nocache()
{
	header("Cache-Control: no-cache, must-revalidate"); //HTTP 1.1
	header("Pragma: no-cache"); //HTTP 1.0
	header("Expires: Sat, 26 Jul 1997 05:00:00 GMT"); // Date in the past
}

function jsonp($data)
{
	header('Access-Control-Allow-Origin: *');  
	header('Content-Type: application/json; charset=utf-8');
	$json = json_encode($data);
	if(!isset($_GET['callback']))
		return $json;
	if(is_valid_jsonp_callback($_GET['callback']))
		return "{$_GET['callback']}($json)";
	return false;
}

function clean_html($json)
{
	$json = preg_replace( '/[[:cntrl:]]+/', ' ',$json);
	$json = preg_replace( '/[\s]+/', ' ',$json);
	return $json;
}

function is_valid_jsonp_callback($subject)
{
	$identifier_syntax = '/^[$_\p{L}][$_\p{L}\p{Mn}\p{Mc}\p{Nd}\p{Pc}\x{200C}\x{200D}]*+$/u';
	$reserved_words = array('break', 'do', 'instanceof', 'typeof', 'case',
			'else', 'new', 'var', 'catch', 'finally', 'return', 'void', 'continue', 
			'for', 'switch', 'while', 'debugger', 'function', 'this', 'with', 
			'default', 'if', 'throw', 'delete', 'in', 'try', 'class', 'enum', 
			'extends', 'super', 'const', 'export', 'import', 'implements', 'let', 
			'private', 'public', 'yield', 'interface', 'package', 'protected', 
			'static', 'null', 'true', 'false');
	return preg_match($identifier_syntax, $subject)
		&& ! in_array(mb_strtolower($subject, 'UTF-8'), $reserved_words);
}

function object_read_url($req_url, $conn_timeout=7, $timeout=5)
{
	$res = curl_get_content($req_url,null,$conn_timeout,$timeout);
	if (empty($res)) {
		return array();
	}
	$res = clean_html($res);
	preg_match("#(\[|{){1,2}[\s]*\".*[\s]*(\]|}){1,2}#ui", $res, $mm);
	$res_body = @$mm[0];
	if (empty($res_body)) {
		return array();
	}
	return json_decode($res_body, true);
}

/****/
/***************  curl ********************/
/****/
function curl_get_content($url, $user_agent=null, $conn_timeout=7, $timeout=5)
{
	$headers = array(
		"Accept: application/json",
		"Accept-Encoding: deflate,sdch",
		"Accept-Charset: utf-8;q=1"
		);
	if ($user_agent === null) {
		$user_agent = 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/31.0.1650.57 Safari/537.36';
	}
	$headers[] = $user_agent;
	$ch = curl_init();
	curl_setopt($ch, CURLOPT_URL, $url);
	curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
	curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
	curl_setopt($ch, CURLOPT_HEADER, 0);
	curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, $conn_timeout);
	curl_setopt($ch, CURLOPT_FOLLOWLOCATION, TRUE);
	curl_setopt($ch, CURLOPT_TIMEOUT, $timeout);
	$res = curl_exec($ch);
	$httpcode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
	$err = curl_errno($ch);
	curl_close($ch);
	if (($err) || ($httpcode !== 200)) {
		return null;
	}
	return $res;
}
function curl_post_content($url, $data, $user_agent=null, $conn_timeout=7, $timeout=5)
{
	$headers = array(
		'Accept: application/json',
		'Accept-Encoding: deflate',
		'Accept-Charset: utf-8;q=1'
		);
	if ($user_agent === null) {
		$user_agent = 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/31.0.1650.57 Safari/537.36';
	}
	$headers[] = $user_agent;
	$ch = curl_init();
	curl_setopt($ch, CURLOPT_URL, $url);
	curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
	curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
	curl_setopt($ch, CURLOPT_HEADER, 0);
	curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, $conn_timeout);
	curl_setopt($ch, CURLOPT_FOLLOWLOCATION, TRUE);
	curl_setopt($ch, CURLOPT_TIMEOUT, $timeout);
	if ($data) {
		curl_setopt($ch, CURLOPT_POST, 1);
		curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($data));
	}
	$res = curl_exec($ch);
	$httpcode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
	$err = curl_errno($ch);
	curl_close($ch);
	if (($err) || ($httpcode !== 200)) {
		return null;
	}
	return $res;
}
