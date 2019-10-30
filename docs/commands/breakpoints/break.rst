.. index:: break
.. _break:

Break (set a breakpoint)
------------------------

**break** [*loc-spec*]

Set a breakpoint at loc-spec.

If no location specification is given, use the current line.

Multiple breakpoints at one place are permitted, and useful if conditional.

Examples:
+++++++++

::

   break              # Break where we are current stopped at
   break 10           # Break on line 10 of the file we are
                      # currently stopped at
   break /etc/profile:10   # Break on line 45 of os.path

.. seealso::

   :ref:`tbreak <tbreak>`, and :ref:`continue <continue>`.
