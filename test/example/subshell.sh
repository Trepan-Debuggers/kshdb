#!/bin/ksh
# Test debugger handling of lines  with multiple commands per line 
# and subshells in a line

x=1; y=2; z=3
(cd  . ; x=$(print *); (print "ho") )
case $(print "testing"; print 1,2,3),$(print 1,2,3) in
  *c*,-n*) PRINT_N= PRINT_C='
' PRINT_T='	' ;;
  *c*,*  ) PRINT_N=-n PRINT_C= PRINT_T= ;;
  *)       PRINT_N= PRINT_C='\c' PRINT_T= ;;
esac

(cd  . ; x=$(print *); (print "ho") )

x=5; y=6;
