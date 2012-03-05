This is a Delphi package supporting access to MongoDB.

After downloading this repo, download and build [mongo-c-driver](http://github.com/mongodb/mongo-c-driver) with scons.
Use the --m32 option with SCons to generate a 32-bit dll.
Copy the produced mongoc.dll to C:\10gen\mongo-delphi-driver\Win32\Debug or ...\Release as appropriate.

Load the project group, MongoDelphiDriver.groupproj, into RAD Studio.

To run the examples, in the Project Manager, right-click on either Test.exe or 
AddressBook.exe and Activate.  Hit F9 to build and run.

The documentation for package is in the 3 unit files: MongoDB.pas, MongoBson.pas, and GridFS.pas

