<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>Free WiFi</title>
<link href="style.css" rel="stylesheet" type="text/css" />
</head>
<body>



<div id="container">
    <div id="header" class="gradient">
            <div id="logo"><a href="#"><span class="blue">Free</span> WiFi</a></div>

    </div>

<!--
<?php
include 'settings.php';
$arp="sudo /usr/sbin/arp";
$iptables="sudo /sbin/iptables";
$client_ip=$_SERVER['REMOTE_ADDR'];

echo $client_ip;
echo "<br>";

//Find out MAC-adress
preg_match("/..:..:..:..:..:../",shell_exec("$arp -a $client_ip"),$entries);
$mac=$entries[0];
//echo $mac;
if (!isset($mac)) {exit;}

//echo $mac;
//echo "<br>";
$b64url=$_GET['url'];
$decurl=base64_decode($b64url);

//check if mac is allowed already
$acces_allowed=False;
$client_mac=strtoupper($mac);
$testmac=shell_exec("$iptables -t mangle -L $portal_chain | grep $client_mac");
//echo "Client Mac: ".$testmac;
if (strlen($testmac) > 0) $acces_allowed=True; //iptables Entry already exists


?>
-->

	<div id="main" class="gradient_rev">
        <div id="content" class="gradient border2">
			<div id="head_image"></div>
			
			<table><tr>
				<td>
				<div id="text">

					<p><span class="highlight_text">Willkommen im Free WiFi</span></p>
					
					<p>
						Nutzen Sie unseren Service f&uuml;r freies Wlan.<br /><br />
						Entscheiden Sie sich ob sie direkt im Internet surfen oder <br />
						eine sichere Verbindung erstellen wollen.<br />
						</br></br>
						Mit Ihre Anmeldung akzeptieren Sie die AGB.
					</p>
				</div> <!-- end text -->
				</td>
				
				<td>
				<div id="sidebar" class="gradient_rev border2">
				
					<span class="highlight_text">Anmeldung Free-WLAN</span>
					<p><b style="font-size: 10pt">Ihre IP lautet: </b></p>
					<br>
					<form method="post" action="/redirect.php" name="fire_form">
						<input name="mac" type="hidden" value="<?php echo base64_encode($mac); ?>">
						<input name="fire" type="submit" value="direkt surfen" onclick="javascript:alert('Sollten Sie nicht automatisch weitergeleitet werden geben Sie Ihre Zielseite von Hand im Browser ein')">

					</form>

					<form action="cert.php" method="post">
						<input name="b64redirurl" type="hidden" >
						<input name="mac" type="hidden" value="<?php echo base64_encode($mac); ?>">
						<input name="setup" type="submit" value="sichere Verbindung">
					</form>
				</div> <!-- end sidebar -->
				</td>
				
			</tr>
			<tr>
				<td>
					
				</td>
				<td>
					<div id="sidebar" class="gradient_rev border2">
						<p><span class="highlight_text">Unsere App</span></p>
						<a href="./app.apk"><img src="images/android.svg" height="60px"></a><br>
					</div>
				</td>
			</tr>
			</table>
		</div><!-- end content -->
	</div><!-- end main -->
    
    <div id="footer" class="gradient">
		<div id="left_footer">
			&copy; Copyright 2017 the Provider
		</div>
	</div>
</body>
</html>
