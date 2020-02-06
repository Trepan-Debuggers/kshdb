How to install
****************

.. toctree::


From a Package
--------------

Repology_ maintains a list of various bundled `kshdb` packages. Below are some specific distributions that contain `kshdb`.

At the time this documentation was built, here is status that they provide:

|packagestatus|

Check the link above for more up-to-date information.


.. |packagestatus| image:: https://repology.org/badge/vertical-allrepos/kshdb.svg
		 :target: https://repology.org/project/kshdb/versions


git
---


Many package managers have back-level versions of this debugger. The most recent versions is from the github_.

To install from git:

.. code:: console

        $ git-clone git://github.com/rocky/kshdb.git
        $ cd kshdb
        $ ./autogen.sh  # Add configure options. See ./configure --help


If you've got a suitable `ksh` installed, then

.. code:: console

        $ make && make test


To try on a real program such as perhaps `/etc/default/profile`:

.. code:: console

      $ ./kshdb -L /etc/default/profile # substitute .../profile with your favorite ksh script

To modify source code to call the debugger inside the program:

.. code:: console

    source path-to-kshdb/kshdb/dbg-trace.sh
    # work, work, work.

    _Dbg_debugger
    # start debugging here


Above, the directory *path-to-kshdb* should be replaced with the
directory that `dbg-trace.sh` is located in. This can also be from the
source code directory *kshdb* or from the directory `dbg-trace.sh` gets
installed directory. The "source" command needs to be done only once
somewhere in the code prior to using `_Dbg_debugger`.

If you are happy and `make test` above worked, install via:

.. code:: console

    sudo make install


and uninstall with:

.. code:: console

    $ sudo make uninstall # ;-)


.. _Repology: https://repology.org/project/kshdb/versions
.. _github: https://github.com/rocky/kshdb
