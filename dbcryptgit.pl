=pod

we plan to share with you a mirror of our user table 
with these fields visible 

ID ,
SALT ( string ),
AES ENCRYPTED PASSWORD  (VARBINARY(300))

To check a password you cooncatenate the sha256 checksum of the with the users salt 
https://mariadb.com/kb/en/sha2/

You then check that against the AES DECRYPT of the AES ENCRYPTED PASSWORD 

https://mariadb.com/kb/en/aes_encrypt/

https://mariadb.com/kb/en/aes_decrypt/


It should be a fairly fast and inexpensive operation for you. 

I considered Bcrypt which would be more secure but would be slower for you to use
and with this version everything is being done inside mariadb and you could write a script in any language 

There is an example of decryption on line 171 

=cut 


use DBI;
use String::Random;
### connect to your DB 
# file wont work without connection string added 
$dbh = DBI->connect('your connection string here');


my $rand = String::Random->new;
print "Your password is ", $rand->randpattern("CCcc!ccn"), "\n";


# CREATE A FAKE USER TABLE 

my $sql = " DROP TABLE IF EXISTS `USER` ";
$sth = $dbh->prepare($sql);
$sth->execute();
$sth->finish;


my $sql = "
CREATE TABLE `USER` (
 `ID` int(11) NOt NULL AUTO_INCREMENT,
 `PASSWORD` VARCHAR(100) NOT NULL ,
 PRIMARY KEY (`ID`)
) ENGINE=MyISAM AUTO_INCREMENT=131 DEFAULT CHARSET=latin1; ";
$sth = $dbh->prepare($sql);
$sth->execute();
$sth->finish;



# ADD 3 FAKE USERS 
my $sql = " INSERT INTO USER VALUES (1, 'itspassword'), (2, 'hispassword'), (3, 'herpassword'); ";
$sth = $dbh->prepare($sql);
$sth->execute();
$sth->finish;

# CREATE AN ENCRYPTED PASSWORD TABLE 

my $sql = "DROP TABLE IF EXISTS `ENCRYPTED_PASSWORD`;";
my $sth = $dbh->prepare($sql);
$sth->execute();
$sth->finish;

my $sql = " CREATE  TABLE `ENCRYPTED_PASSWORD` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `SHA_VERSION` VARCHAR(100) NULL ,
            `SALT` VARCHAR(100) NULL,
            `AES_VERSION` VARBINARY(300) NULL,
            PRIMARY KEY (`ID`)
            ) ENGINE=MyISAM AUTO_INCREMENT=131 DEFAULT CHARSET=latin1;";

my $sth = $dbh->prepare($sql);
$sth->execute();
$sth->finish;


# loop over all users and store sha256 version in encrypted table

my $sql = "select ID,PASSWORD from USER order by ID limit 1000";
my $sth = $dbh->prepare($sql);
my $rc = $sth->execute();
while (my ($uid,$password) = $sth->fetchrow_array) {
  
   # store sha256 version of password in table
   # The return value is a nonbinary string in the connection character set and collation, 
   # determined by the values of the character_set_connection and collation_connection system variables.

   #SELECT SUBSTRING(SHA1(RAND()), 1, 6) AS salt
   #SELECT SHA1(CONCAT(salt, 'password')) AS hash_value

   my $rand = String::Random->new;
   my $salt = $rand->randpattern("CCcc!ccn");
   my $sql = "INSERT INTO ENCRYPTED_PASSWORD (ID, SHA_VERSION, SALT, AES_VERSION) 
               values ($uid, SHA2('$password',256), '$salt', '12345678901' );";
   my $sth = $dbh->prepare($sql);
    $sth->execute();
    $sth->finish; 
   
}
$sth->finish;

#store aes version of password in encrypted table 
#loop over encrypted table and get id and sha pass 
# for each user in encrypted table 

my $sql = "select ID,SHA_VERSION,SALT from ENCRYPTED_PASSWORD order by ID limit 1000";
my $sth = $dbh->prepare($sql);
my $rc = $sth->execute();
while (my ($uid,$shaversion,$salt) = $sth->fetchrow_array) {
   #print "$uid -- $shapassword\n";
   # store sha256 version of password in table
   my $aesPassword = "2020nordG2X251mod";
   # I don't think this line works !!!
   # AES_ENCRYPT expects a string I tried casting $shaversion to a CHAR 
   my $sql = "UPDATE ENCRYPTED_PASSWORD SET AES_VERSION = (AES_ENCRYPT('$shaversion.$salt',SHA2('$aesPassword',512))) WHERE ID= '$uid';";
  #UPDATE USER SET PASSWORD = (AES_ENCRYPT('123456a',SHA2('secret',512))) WHERE ID= 1175980;
   my $sth = $dbh->prepare($sql);
    $sth->execute();
    $sth->finish; 
   

}
$sth->finish;

#print everything in both tables

#print user table
print("\nuser table \n \n");
my $sql = "select ID,PASSWORD from USER order by ID limit 1000";
my $sth = $dbh->prepare($sql);
my $rc = $sth->execute();
while (my ($uid,$password) = $sth->fetchrow_array) {
   print "$uid -- $password\n";
}
$sth->finish;

#print encrypted table
print("\nencrypted table \n \n");
my $sql = "select ID,SHA_VERSION,SALT,AES_VERSION from ENCRYPTED_PASSWORD order by ID limit 1000";
my $sth = $dbh->prepare($sql);
my $rc = $sth->execute();
while (my ($uid,$sha,$salt,$aes) = $sth->fetchrow_array) {
   #print "id - $uid - sha - $sha - aes - $aes\n";
   print "id - $uid - sha - $sha\n";
   print "######\n";
   print "\nsalt -- $salt";
   print "aes : \n";
   print "$aes\n";

}
$sth->finish;



# DECRYPT THE SHA PASSES 

print("\n decrypted table\n \n");

    # use aes_version 
my $aesPassword = "2020nordG2X251mod";
my $sql =  "SELECT (AES_DECRYPT(AES_VERSION,SHA2('$aesPassword',512))), ID from ENCRYPTED_PASSWORD order by ID limit 1000;";
# UPDATE USER SET PASSWORD = (AES_DECRYPT(PASSWORD,SHA2('secret',512))) WHERE ID= 1175980;
my $sth = $dbh->prepare($sql);
my $rc = $sth->execute();
while (my ($decr,$uid) = $sth->fetchrow_array) {
    print("id - $uid\n");
    print("######\n");
    print("decrypted string $decr\n");
        }
$sth->finish;



exit;

# /usr/local/www/iml/bin/passwordLoop.pl

