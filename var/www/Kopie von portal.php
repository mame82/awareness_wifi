<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title></title>
<link href="style.css" rel="stylesheet" type="text/css" />
</head>
<body>


<div id="container">
        <!-- header -->
    <div id="header">
            <div id="logo"><a href="#"><span class="blue">Fakesite</span> Wunderland</a></div>

    </div>
    <!--end header -->
    <!-- main -->
    <div id="main">
        <div id="content">
        <div id="head_image">


        </div>
        <div id="text">
<?php 
$arp="/usr/sbin/arp";
$iptables="sudo /sbin/iptables";
$client_ip=$_SERVER['REMOTE_ADDR'];

//Find out MAC-adress
preg_match("/..:..:..:..:..:../",shell_exec("$arp -a $client_ip"),$entries);
$mac=$entries[0]; 
if (!isset($mac)) {exit;}
//echo $mac;
//echo "<br>";
$b64url=$_GET['url'];
$decurl=base64_decode($b64url);

//check if mac is allowed already 
$acces_allowed=False;
$client_mac=strtoupper($mac);
$testmac=shell_exec("$iptables -t mangle -L portal | grep $client_mac");
echo "Client Mac: ".$testmac;
if (strlen($testmac) > 0) $acces_allowed=True; //iptables Entry already exists


?>

          <h1>Willkommen
                <p>zur <b>A6/S6-Tagung</b> im Kernwasser Wunderland.<br /> <br /><br />  </h1>

                     <h1>Vorf&uuml;hrung WLAN-Sicherheit</h1>
                <p>Hier wird kurz vorgef&uuml;hrt welche Probleme bei einem gefakten WLAN Hot Spot entstehen
                und welche Daten ausspioniert werden k&ouml;nnen.</p>
       </div>


<div id="sidebar">
<h2>Anmeldung  Hotspot</h2>
<b style="font-size: 10pt">Ihre IP ist <?php echo $client_ip; ?></b></p>

<form method="post" action="/redirect.php" name="fire_form">
<TD vAlign=top width=20></TD>
<TD vAlign=top width=398><br>
<TD class=largetext vAlign=center width = 70><b>User ID:</b><input name="auth_user" type="text"></TD>
<TD class=largetext vAlign=center width =70><b>Password:</b><input name="auth_pass" type="password"></TD>

<br><br><br>

<input name="b64redirurl" type="hidden" value=<?php echo $b64url; ?>>
<input name="mac" type="hidden" value="<?php echo base64_encode($mac) ?>">
<input name="fire" type="submit" value="und ab die Post">
<?php
if ($acces_allowed==True)
{
	echo "<input name=\"logout\" type=\"submit\" value=\"Abmelden\">";
}
?>
<a href="cert.html">Setup...</a>
</form>

       </div>
       </div>
    </div>
    <!-- end main -->
    <!-- footer -->
    <div id="footer">
    <div id="left_footer">&copy; Copyright 2015 MEST-Design
    </div>
    <div id="right_footer">



    </div>
    </div>
    <!-- end footer -->
</div>
</body>
</html>