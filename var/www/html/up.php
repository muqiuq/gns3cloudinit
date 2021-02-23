<?php

if(!isset($_FILES["ovpn"])
|| !isset($_POST["ip"])
|| !isset($_POST["name"])
) {
	echo "ERROR\n\r";
	exit;
}

$name = $_POST["name"];
$reported_ip = $_POST["ip"];
$remote_ip = $_SERVER["REMOTE_ADDR"];
$now = date("Y-m-d H:i:s"); 

$macAddr=false;

#run the external command, break output into lines
$arp=`arp -a $reported_ip`;
$lines=explode("\n", $arp);

#look for the output line describing our IP address
foreach($lines as $line)
{
   $cols=preg_split('/\s+/', trim($line));
   if(count($cols) < 4) continue;
   if (strpos($cols[1],$reported_ip) !== false)
   {
       $macAddr=$cols[3];
   }
}

$ovpnfilename = "keys/" . $name . ".ovpn";

$infofile = <<<EOD
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>$name</title>
    <style>
    table td {
    	border-top: 1px solid grey;
    	padding-right: 10px;
    }
    </style>
  </head>
  <body>
    <table style="border: 1px solid;">
    	<tr><td><b>Name</b></td><td>$name</td></tr>
    	<tr><td><b>Created</b></td><td>$now</td></tr>
    	<tr><td><b>Reported HOST</b></td><td>$reported_ip</td></tr>
    	<tr><td><b>Reported HOST MAC</b></td><td>$macAddr</td></tr>
    	<tr><td><b>HTTP Client HOST</b></td><td>$remote_ip</td></tr>
    	<tr><td><b>OpenVPN Client Config file</b></td><td><a href="/$ovpnfilename">$name.ovpn</a></td></tr>
    </table>
  </body>
</html>

EOD;

move_uploaded_file($_FILES["ovpn"]["tmp_name"], $ovpnfilename);

file_put_contents("keys/" . $name . ".html", $infofile);

echo "OK\r\n";