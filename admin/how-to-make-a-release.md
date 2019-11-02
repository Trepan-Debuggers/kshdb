- Let people know of a pending release?

- test on lots of platforms.

- Look for patches and outstanding bugs.

- git pull

- Edit from `configure.ac`'s release name. If we have this in `configure.ac`:
```
   AC_INIT([kshdb],[1.0.0],[rocky@gnu.org])
                    ^^^^^
```

then:

```console
   $ export KSHDB_VERSION='1.0.0'
   $ ./autogen.sh && make && make check
```

- Commit changes:

```console
  $ git commit -m"Get ready for release $KSHDB_VERSION" .
  $ make Changelog
```

- Go over `ChangeLog` and add to `NEWS.md`. Update date of release.

  ```console
	$  git commit --amend .
  ```

- `make distcheck` should work

- Tag release on github
   https://github.com/rocky/kshdb/releases

- Get onto sourceforge:

  Use the GUI
   login, file release, add folder $KSHDB_VERSION
   create new folder, right click to set place to upload and
   hit upload button.


- Bump version in configure.ac and add "dev". See place above in
  removal
