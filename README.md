This is a Delphi package supporting access to MongoDB.

In order to compile this repo, you need to use it as submodule within another repo on it's own subdirectory.
This is how we use it from https://github.com/Convey-Compliance/mongo-delphi-driver-build :

[submodule "__submodules/mongo-c-driver"]
	path = __submodules/mongo-c-driver
	url = git@github.com:Convey-Compliance/mongo-c-driver.git
[submodule "__submodules/fast-aes"]
	path = __submodules/fast-aes
	url = git@github.com:Convey-Compliance/fast-aes.git
[submodule "__submodules/zlib"]
	path = __submodules/zlib
	url = git@github.com:Convey-Compliance/zlib.git
[submodule "__submodules/mongo-delphi-driver"]
	path = __submodules/mongo-delphi-driver
	url = git@github.com:Convey-Compliance/mongo-delphi-driver.git
[submodule "__submodules/delphi-fastmm"]
	path = __submodules/delphi-fastmm
	url = git@github.com:Convey-Compliance/delphi-fastmm.git

The best way to use this is by cloning https://github.com/Convey-Compliance/mongo-delphi-driver-build, building and running
tests from that submodule.
