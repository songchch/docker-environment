# TA training - Docker
## Usage of `docker.sh`
* build an image
``` bash
./docker.sh build --stage-name STAGE --username USER --image-name IMAGE"
```
* run a container
``` bash
./docker.sh run --username USER --image-name IMAGE --cont-name CONTAINER
```
* stop a container
``` bash
./docker.sh stop --cont-name CONTAINER
```
* Clean containers and images
``` bash
./docker.sh clean
```
* Clean and rebuild images
``` bash
./docker.sh rebuild
```

## Usage of `workspace/eman.sh`
* show  help message
``` bash
./eman.sh help 
```
* print the version of the first found Verilator
``` bash
./eman.sh check-verilator
```
* compile and run the Verilator example
``` bash
./eman.sh verilator-example
```
* change default Verilator to different version. If not installed, install it.
``` bash
./eman.sh change-verilator <VERSION>
```
* print the version of default C compiler and GNU Make
``` bash
./eman.sh c-compiler-version
```
* compile and run the C example(s)
``` bash
./eman.sh c-compiler-example
```
* compile and run the SystemC example
``` bash
./eman.sh systemc-example
```