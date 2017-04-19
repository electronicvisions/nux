This repository contains the Nux Processor developed during the Brain-i-Nets,
BrainScaleS, and HBP EU research projects. It is a small RISC processor
implementing the Power ISA 2.06 (32 bit embedded implementation). It also has
a non-standard SIMD processing unit for 8 and 16-bit fixed-point arithmetics.
The design is open source and provided under the Solderpad license. For details
see the LICENSE and NOTICE files.


Documentation
-------------

Documentation about the design is provided in
 - doc/guide contains a user guide as LaTeX document.
 - The PhD thesis of Simon Friedmann [1] documents internals.

The user guide can be regenerated:

    $ cd doc/guide
    $ make


Requirements for simulation
---------------------------

The processor was designed using SystemVerilog. It uses components from the
Synopsys DesignWare library (FIFOs and some arithmetic functions.
Replacements are welcome!). The current simulation flow is based on make and
uses ModelSim. It should be easily adaptable to other simulators.

The project uses OMNIBUS as bus interface. Use the mr tool to set it up:

    $ mr checkout

You may have to add the local .mrconfig file to your global `$HOME/.mrtrust` file.
You can then update dependencies using

    $ mr update

Alternatively you can directly clone the OMNIBUS git repository. Have a look
into the `.mrconfig` file for the exact command line.


Directory structure
-------------------

 - `doc/` contains documentation
 - `omnibus/` OMNIBUS repository checked out using mr tool.
 - `src/` HDL source files.
 - `support/` Tools and stuff to work with the design and its source.
 - `target/` Run directories to implement the processor for a given target e.g.
   a certain FPGA platform.
 - `test/` Sources required for tests of the design, e.g. C and assembly code for
   test programs.
 - `verification/` Run directories for simulation.


How to simulate
---------------

Go to the simulation run directory in `verification/sim_model` for ModelSim and
run:

    $ make

This will compile all relevant source files. Make sure, that the `$SYNOPSYS`
environment variable points to an installation directory, where a DesignWare
installation can be found.

What is compiled can be configured through the `.config` file in the main
directory. The defaults should be ok.

To start simulations, TCL scripts are provided as `sim_*.do` files for ModelSim. A
useful first simulation is the Program Level Test:

    $ vsim -c -do sim_plt.do

This will execute a number of test programs and report if any errors are
detected.

See the user guide for more detailed descriptions of what simulations are
available.



References
----------

[1] http://archiv.ub.uni-heidelberg.de/volltextserver/15359/

