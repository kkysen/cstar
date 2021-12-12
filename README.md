# C*

Also written as `cstar` and pronounced **Sea Star**.


![A sea star (aka starfish)](https://www.papo-france.com/1266-thickbox_default/starfish.jpg =100x100)


## Proposal
See the [proposal](./proposal.md) for an overview of the language.

## Language Reference Manual
See the [language reference manual](./LRM.md) for a detailed reference manual for the language.

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

## Building
(See set up with VM section first)
Run `./setup.sh <mode>`, where `mode` is either `build` or `dev`.  
Run `eval "$(./setup.sh path)"`, or if you already have `just`, just `eval "$(just path)"`.
Then run `just build` to build and install `cstar` to your `$PATH`, i.e, to `./bin/cstar`.
`just watch` is also useful for watching for changes to build.
To add shell autocompletions, run `eval "$(cstar completions)"`.
