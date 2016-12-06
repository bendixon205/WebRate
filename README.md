# WebRate
<h2>First Logging In </h2>
<p>In order to be able to upload sites and users to the database, you must first login to the site with <br><br> 
  Username: admin<br>Password: admin<br>
</p>
<h2>Uploading Users</h2>
<p>
  When uploading the users as a .csv file, make sure every entry is in the form: <br>
  name,password,role<br>
  where role is either instructor or student
</p>
<h2>Uploading Sites</h2>
<p>
  When uploading the zip files with all of the sites in them, it is important to make sure that the zip contains individual folders for each website and each of these folders have all of the files inside. Each site can only use one .html file. <br>
</p> 
<pre>
    ZipFile
      Website 1(Folder)
       -main.html
       -styles.css
      Website 2(Folder)
       -home.html
       -scripts.js
       -styles.css
      Etc...
</pre>

<h2>Gems that were tricky to get working</h2>
<p>If you have trouble using 'sanitize' - when using the gem 'sanitize' on windows you have to make sure you have the dev kit installed and have the gem'nokogiri' installed before you can install the sanitize gem. </p>
