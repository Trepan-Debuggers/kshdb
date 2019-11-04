.. index:: set; different
.. _set_different:

Set Different (consecutive stops on different file/line positions)
------------------------------------------------------------------

**set different** [ **on** | **off** ]

Set consecutive stops must be on different file/line positions.
If no argument is given, different is set "off".

One of the challenges of debugging is getting the granualarity of
stepping comfortable. By setting different "on" you can set a more
coarse-level of stepping which often still is small enough that you
won't miss anything important.

Note that the `step` and `next` debugger commands have '+' and '-'
suffixes if you wan to override this setting on a per-command basis.

.. seealso::

   :ref:`set trace <set_trace>` to change what events you want to filter.
   :ref:`show trace <show_trace>`.
