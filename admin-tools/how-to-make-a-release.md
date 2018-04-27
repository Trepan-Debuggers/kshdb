- Let people know of a pending release, e.g. bashdb-devel@sourceforge.net;
  no major changes before release, please

- test on lots of platforms; sourceforge compile farm, for example

- "make distcheck" should work

- Look for patches and outstanding bugs on sourceforge.net

- Go over Changelog and add NEWS. Update date of release.

- Edit from configure.ac's release name. E.g.
    AC_INIT([kshdb],[0.02],[rocky@gnu.org])
                       ^^

- Make sure sources are current and checked in:
    svn pull
    svn commit .
    svn push

- autogen.sh && make && make check

- Tag release in git:
   git tag release-0.02
   git push --tags

- Get onto sourceforge:

  scp kshdb-0.02.tar.*   rockyb@frs.sourceforge.net:uploads

  Go to:
   https://sourceforge.net/project/admin/newrelease.php?package_id=57763&group_id=61395
  and add release  0.02


- Update/Announce on Freshmeat:
   http://freshmeat.net/add-release/30926/

  The NEWS file is your friend.

- copy bashdb manual to web page:
     cd doc
     rm *.html
     make
     scp *.html rockyb,bashdb@web.sourceforge.net:htdocs
     # scp *.html rockyb,bashdb@web.sourceforge.net:htdocs/

- Bump version in configure.ac and add "cvs". See place above in
  removal
