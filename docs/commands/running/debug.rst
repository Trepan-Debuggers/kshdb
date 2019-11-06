.. index:: debug
.. _debug:

Debug (recursive debugging)
---------------------------
**debug** [*ksh-script* [*args*...]]

Set up *ksh-script* for debugging.

If *script* is not given, take the script name from the command that
is about to be executed. Note that when the nested debug finished, you
are still where you were prior to entering the debugger.

.. seealso::

   :ref:`skip <skip>`, and :ref:`run <run>`
