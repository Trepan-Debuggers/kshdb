.. index:: step
.. _step:

Step (step into)
----------------

**step** [ **+** | **-** [*count*]

Execute the current line, stopping at the next event.

With an integer argument, step that many times.

You can Set an event, by suffixing one of the symbols `+`, `-`,
or after the command or on an alias of that.  A suffix of `+` on a
command or an alias forces a move to another line, while a suffix of
`-` disables this requirement.

If no suffix is given, the debugger setting `different-line`
determines this behavior.

Examples:
+++++++++

::

    step        # step 1 event, *any* event
    step 1      # same as above
    step 5/5+0  # same as above
    step+
    step-

.. seealso::

   :ref:`next <next>` command. :ref:`skip <skip>`, and :ref:`continue <continue>` provide other ways to progress execution.
