<?php

/*
	This script builds JSON playlist definitions for nginx-vod-module.
	When playlist type is set to live, it will play the MP4 files one after the other in a loop.
	When playlist type is vod, it will play each MP4 file once.
	The discontinuity parameter is true by default, set it to false only when all MP4's have 
	exactly the same encoding parameters (in the case of h264, the SPS/PPS have to be the same).
*/

function getRequestParams()
{
        $scriptParts = explode('/', $_SERVER['SCRIPT_NAME']);
        $pathParts = array();
        if (isset($_SERVER['PHP_SELF']))
                $pathParts = explode('/', $_SERVER['PHP_SELF']);
        $pathParts = array_diff($pathParts, $scriptParts);

        $params = array();
        reset($pathParts);
        while(current($pathParts))
        {
                $key = each($pathParts);
                $value = each($pathParts);
                if (!array_key_exists($key['value'], $params))
                {
                        $params[$key['value']] = $value['value'];
                }
        }
        return $params;
}

$params = getRequestParams();
#$discontinuity = (isset($params['disc']) && $params['disc']) ? true : false;
#$playlistType = isset($params['type']) ? $params['type'] : "live";
$playlistType='vod';
$discontinuity=true;

// input params
$filePaths = array(
	"/var/www/vodsrv/mp4/22.mp4",
	"/var/www/vodsrv/mp4/33.mp4",
	"/var/www/vodsrv/mp4/44.mp4",
	"/var/www/vodsrv/mp4/55.mp4",
	"/var/www/vodsrv/mp4/77.mp4",
	"/var/www/vodsrv/mp4/99.mp4",
	);
if (!$discontinuity)
{
	$filePaths = array($filePaths[0], $filePaths[0]);
}
$ffprobeBin = '/usr/bin/ffprobe';
$timeMargin = 10000;		// a safety margin to compensate for clock differences

// nginx conf params
$segmentDuration = 10000;
$segmentCount = 10;

$redis = new Redis(); 
$redis->connect('127.0.0.1', 6379); 

function getSourceClip($filePath)
{
	return array(
		"type" => "source",
		"path" => $filePath
	);
}

function getDurationMillis($filePath)
{
	global $ffprobeBin, $redis;

	// try to fetch from cache
	$cacheKey = "duration-{$filePath}";

	$duration = $redis->get($cacheKey);
	if (!empty($duration)) {
		return intval($duration);
	}

	// execute ffprobe
	$commandLine = "{$ffprobeBin} -i {$filePath} -show_streams -print_format json -v quiet";
	$output = null;
	exec($commandLine, $output);
	
	// parse the result - take the shortest duration
	$ffmpegResult = json_decode(implode("\n", $output));
	$duration = null;
	foreach ($ffmpegResult->streams as $stream)
	{
		$curDuration = floor(floatval($stream->duration) * 1000);
		if (is_null($duration) || $curDuration < $duration)
		{
			$duration = $curDuration;
		}
	}
	
	// store to cache
	$redis->set($cacheKey, $duration);
	
	return $duration;
}


$durations = array_map('getDurationMillis', $filePaths);

$result = array();

if ($playlistType == "live")
{
	// find the duration of each cycle
	$cycleDuration = array_sum($durations);
	
	// if the cycle is too small to cover the DVR window, duplicate it
	$dvrWindowSize = $segmentDuration * $segmentCount;
	while ($cycleDuration <= $dvrWindowSize + $timeMargin)
	{
		$filePaths = array_merge($filePaths, $filePaths);
		$durations = array_merge($durations, $durations);
		$cycleDuration *= 2;
	}
	
	// start the playlist from now() - <dvr window size>
	$time = isset($params['time']) ? $params['time'] : time();
	$currentTime = $time * 1000 - $timeMargin - $dvrWindowSize;

	// get the reference time (the time of the first run)
	$reference_time_key = 'reference_time';
	$referenceTime = $redis->get($reference_time_key);
	if (empty($referenceTime)) {
		$referenceTime = $currentTime;
		$redis->set($reference_time_key, $referenceTime);
	}
	$referenceTime = intval($referenceTime);
	
	// set the first clip time to now() rounded down to cycle duration
	$cycleIndex = floor(($currentTime - $referenceTime) / $cycleDuration);
	$result["firstClipTime"] = $referenceTime + $cycleIndex * $cycleDuration;
	
	if ($discontinuity)
	{
		// find the total number of segments in each cycle
		$totalSegmentCount = 0;
		foreach ($durations as $duration)
		{
			$totalSegmentCount += ceil($duration / $segmentDuration);
		}

		// find the initial clip index and initial segment index
		$result["initialClipIndex"] = $cycleIndex * count($durations) + 1;
		$result["initialSegmentIndex"] = $cycleIndex * $totalSegmentCount + 1;
	}
	else
	{
		$result["segmentBaseTime"] = $referenceTime;
	}

	// duplicate the clips, this is required so that we won't run out of segments 
	// close to the end of a cycle
	$filePaths = array_merge($filePaths, $filePaths);
	$durations = array_merge($durations, $durations);
}

// generate the result object
$result = array_merge($result, array(
	"discontinuity" => $discontinuity,
	"playlistType" => $playlistType,
	"durations" => $durations,
	"sequences" => array(
		array(
			"clips" => array_map('getSourceClip', $filePaths)
		)
	)
));

header('Content-Type: application/json; charset=utf-8');
echo json_encode($result);
