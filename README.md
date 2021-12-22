# C*

Also written as `cstar` and pronounced **Sea Star**.


![A sea star (aka starfish)](https://www.papo-france.com/1266-thickbox_default/starfish.jpg =100x100)


## Proposal
See the [proposal](./docs/proposal.md) for an overview of the language.

## Language Reference Manual
See the [language reference manual](./docs/LRM.md) for a detailed reference manual for the language.



## Building
Building only currently works on Linux,
and has been tested on recent Ubuntus and Debians.
Make sure the below is run on Linux.
We also include [instructions](#set-up-with-vm) below for 
downloading and using our VM, which already has things installed.

Run `./setup.sh <mode>`, where `mode` is either `build` or `dev`.
* `build` installs everything necessary to build
* `dev` also installs things necessary/useful for developing `cstar`

Then run `eval "$(./setup.sh path)"`, or if you already have `just`, just `eval "$(just path)"`.

Then run `just build` to build and install `cstar` to your `$PATH`, i.e, to `./bin/cstar`.

`just watch` is also useful for watching for changes to build.

To add shell autocompletions (for the `cstar` executable), run `eval "$(cstar completions)"`.

`cstar --help` and `cstar compile --help` explain how to run `cstar`.  For the simplest case, run `cstar compile $path.cstar` to produce a `$path` executable.

Make sure `./bin/llvm` is still on your `$PATH` when running this,
which it is after running `eval "$(just path)"`.


## Set Up with VM 
1. Download VirtualBox:
        With Homebrew (MacOS): brew install --cask virtualbox
        Via a dmg install (Any OS): https://www.virtualbox.org/wiki/Downloads

2. Install VirtualBox

3. Download cstar.ova: 
https://drive.google.com/file/d/1mU8F33PCl8f9cnk0UJ24SIuVKea9am26/view?usp=sharing
        a) file size is ~12 gb
        b) vm will be ~25 gb
        c) You can delete the .ova file after install

4. In VirtualBox
	a) Select "File" in the top menu-bar
	b) Select "Import Appliance"
	c) For the file select "cstar.ova"
	d) Select "Continue"
	e) On the next page select "Import" 

5. After Installation in homepage/Ocacle VM VirtualBox Manager
	a) Select settings
	b) Select display
	c) Make sure the bottom of the settings page does not say
	"Invalid settings detected"
		ii) if it does switch the graphics controller to
		VMSVGA (this seems to primarily be a Big Sur MacOS thing)
		ii) if it does not select cancel and boot the VM

6. Password for the vm is "lerner"
