.. index:: set; autoeval
.. _set_autoeval:

Set Auto Eval (auto evaluation of unrecognized debugger commands)
-----------------------------------------------------------------

**set autoeval** [ **on** | **off** ]

Evaluate unrecognized debugger commands.

Often inside the debugger, one would like to be able to run arbitrary
ksh commands without having to preface expressions with
``print`` or ``eval``. Setting *autoeval* on will cause unrecognized
debugger commands to be *eval*'d as a ksh expression.

Note that if this is set, on error the message shown on type a bad
debugger command changes from:

::

      Undefined command: "fdafds". Try "help".

to something more ksh-eval-specific such as:

::

      /tmp/kshdb_eval_26397:2: command not found: fdafds


.. seealso::

   :ref:`show autoeval <show_autoeval>`
