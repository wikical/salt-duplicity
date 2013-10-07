==============
Salt-duplicity
==============

Overview
========

This is a Salt_ formula for making a server backup itself using
duplicity_. Essentially it creates a ``custom_backup`` script which is
similar to duplicity but which automatically passes several options to
duplicity so that you don't need to specify them (backup location, gpg
options, and so on). It also sets up scheduled backups with cron.

You may want to generate GPG keys first; to do this run::

    gpg --gen-key

and answer the defaults (RSA and RSA, 2048 bits, does not expire; real
name "Backup for *hostname*"; email address "root@*hostname*"; no
comment; empty passphrase). Then, export these keys to files::

  gpg --export-secret-keys --armor root@$hostname >$hostname.key
  gpg --export --armor root@$hostname >$hostname.pub

Then specify their contents as parameters in the pillar; see
``pillar.example`` for an example.

Parameters
----------

- ``gpg_priv_key``, ``gpg_pub_key``: The GPG keys; they must be the
  full contents of the ASCII armored files (``.asc``). If specified,
  these keys are installed in GPG and marked as trusted.
- ``gpg_key_id``: Ignored if the ``gpg_pub_key`` is specified.
  Otherwise, if ``False``, it means there will be no encryption; if it
  has the value "symmetric", it means it will do symmetric encryption;
  otherwise it should be the id of a GPG key installed via other
  means. The default is a dummy value that will not work (this is to
  prevent you from forgetting to set it properly.  Explicitly set it
  to false for no encryption.)
- ``gpg_pw``: The GPG private key passphrase, or the symmetric
  encryption password.
- ``target``: No default.
- ``target_pw``: The target password, if required.
- ``source``: Default ``/``.
- ``verbosity``: Default 4. See also the
  ``remove_all_inc_of_but_n_full`` parameter below.
- ``full_if_older_than``: How often to do full backups; see the
  duplicity documentation for more information. Default 1M.
- ``remove_older_than``: Oldest backup to keep. See the duplicity
  remove-older-than parameter. Default two years.
- ``remove_all_inc_of_but_n_full``: Delete incremental sets of all
  backup sets that are older than the count:th last full backup; see
  the duplicity documentation for more information. Note: the related
  ``duplicity`` command is always run with verbosity=error, regardless
  what has been set in ``verbosity``. This is because at the usual
  verbosity=warning, on some machines, not understood exactly when, the
  command shows an apparently harmless message "No extraneous files
  found, nothing deleted in cleanup."
- ``includes_excludes``: Parameters to duplicity related with
  including and excluding things.
- ``extra_parms``: Extra parameters to duplicity.  If you backup with
  ssh and have not added the target host key to known_hosts, you might
  want to use ``--ssh-options="-oStrictHostKeyChecking=no"``.
- ``when_to_run``: A crontab specification of the time it should run;
  default ``0 4 * * *``, i.e. 4am daily.
- ``pre``, ``post``: Strings containing scripts to run before and
  after backup.

See ``pillar.example`` for an example.

.. _salt: http://saltstack.org/
.. _duplicity: http://duplicity.nongnu.org/

Meta
====

Written by Antonis Christofides

| Copyright (C) 2011-2012 Vorgründungsgesellschaft GridMind Ivan Fernando Villanueva Barrio EU
| Copyright (C) 2013 Ministry of Environment of Greece

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see http://www.gnu.org/licenses/.
