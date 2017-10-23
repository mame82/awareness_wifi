<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>WLAN-Wunderland</title>
<link href="style.css" rel="stylesheet" type="text/css" />
</head>
<body>


<div id="container">
        <!-- header -->
    <div id="header">
            <div id="logo"><a href="#"><span class="blue">WLAN</span> Wunderland</a></div>

    </div>
    <!--end header -->
    <!-- main -->
    

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

	<div id="main">
        <div id="content">
			<div id="head_image"></div>
			<table><tr>
			<td>	
			<div id="text">

				<p><h1>Willkommen im WUNDERLAND WiFi</h1></p>
                <!-- <p><h2>zur <b>A6/S6-Tagung</b> im Kernwasser Wunderland.<br /> </h2><hr> -->
                <p>
					Nutzen Sie unseren Service f&uuml;r freies Wlan.<br />
					Entscheiden Sie sich ob sie direkt im Internet surfen oder <br />
					eine sichere Verbindung erstellen wollen.<br />
                </p>
			</div>
			</td>
			<td>
			<div id="sidebar">
				<a href="./app.apk"><img src="images/android.svg" height="60px"></a><br>
				<h2>Anmeldung<br /> Free-WLAN</h2>
				<b style="font-size: 10pt">Ihre IP lautet: <?php echo $client_ip; ?></b></p>
				<br>
				<form method="post" action="/redirect.php" name="fire_form">
					<input name="b64redirurl" type="hidden" value=<?php echo $b64url; ?>>
					<input name="mac" type="hidden" value="<?php echo base64_encode($mac); ?>">
					<input name="fire" type="submit" value="direkt surfen" onclick="javascript:alert('Sollten Sie nicht automatisch weitergeleitet werden geben Sie Ihre Zielseite von Hand im Browser ein')">
					<?php
					if ($acces_allowed==True)
					{
						echo "<input name=\"logout\" type=\"submit\" value=\"Abmelden\">";
					}
					?>
				</form>

				<form action="cert.php" method="post">
					<input name="b64redirurl" type="hidden" value=<?php echo $b64url; ?>>
					<input name="mac" type="hidden" value="<?php echo base64_encode($mac); ?>">
					<input name="setup" type="submit" value="sichere Verbindung">
				</form>
			</div>
			</td>
			</tr></table>
		</div><!-- end content -->
	</div><!-- end main -->
    
    <!-- footer -->
    <div id="footer">
		<div id="left_footer">
			&copy; Copyright 2015 MEST-Design
		</div>
		<div id="right_footer">
		</div>
			<!-- end footer -->
	</div>
</body>
</html>
