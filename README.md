# openjdkquartz
This repository contains a patch script designed to allow java programmers to create an open-jdk-8 variant which allows memory allocation over the [Quartz performance emulator](https://github.com/HewlettPackard/quartz). 
It is assumed [Quartz](https://github.com/HewlettPackard/quartz) is compiled and installed before running the script. 

## Requisites
Some version of open-jdk-8 source code. Can be obtained from the project's [mercurial](http://hg.openjdk.java.net/jdk8u) repository. 

## Usage
1. Compile Quartz, install the library (libnvmemul.so) to the machine's \usr\lib\. Set-up the nvmemul device. 
2. Run ```./openjdk8patcher.sh path/to/openjdk/src```
3. build openjdk from source using its embedded readme. 
4. Test your jdk by compiling and running the two simple tests in the unitTests directory. 