<?php
//=============================================================================//
// FOR EDUCATION PURPOSE ONLY. Don't Sell this Script, This is 100% Free.
// Join Community https://t.me/ygxworld, https://t.me/ygx_chat
//=============================================================================//

$jsonFile = 'data.json';
$jsonData = file_get_contents($jsonFile);
$protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off' || $_SERVER['SERVER_PORT'] == 443) ? "https://" : "http://";
$host = $_SERVER['HTTP_HOST'];
$requestUri = $_SERVER['REQUEST_URI'];
$scriptUrl = $protocol . $host . str_replace('playlist.php','index.php', $requestUri);
$data = json_decode($jsonData, true);
header('Content-Type: audio/x-mpegurl');
echo "#EXTM3U\n\n";
echo "# Zee5 Playlist Combined (IN + GB + SG + AE)\n";

foreach ($data['data'] as $channel) {
    $id        = $channel['id'] ?? '';
    if ($id === '' || isset($seenIds[$id])) continue; $seenIds[$id] = true;
    $slug      = $channel['slug'] ?? '';
    $country   = $channel['country'] ?? '';
    $chno      = $channel['chno'] ?? '';
    $language  = $channel['language'] ?? '';
    $name      = $channel['name'] ?? '';
    $chanName  = $channel['channel_name'] ?? '';
    $logo      = $channel['logo'] ?? '';
    $genre     = $channel['genre'] ?? '';
    $streamUrl = $scriptUrl . '?id=' . ($id ?: '');
    echo "#EXTINF:-1 tvg-id=\"$id\" tvg-country=\"$country\" tvg-chno=\"$chno\" tvg-language=\"$language\" tvg-name=\"$name\" tvg-logo=\"$logo\" group-title=\"$genre\", $chanName\n";
    echo "#KODIPROP:inputstream=inputstream.adaptive\n";
    echo "#KODIPROP:inputstream.adaptive.manifest_type=HLS\n";
    echo "#KODIPROP:inputstream.adaptive.stream_headers=User-Agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3\n";
    echo "$streamUrl\n\n";
}
exit;
//@yuvraj824




