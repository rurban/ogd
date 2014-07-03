# NAME

ogd - ordered global destruction

# SYNOPSIS

    perl -mogd yourscript.pl # recommended

    export PERL5OPT=-mogd
    perl yourscript.pl

    use ogd;
    ogd->register( @object ); # for objects from XSUBs only

# VERSION

This documentation describes version 0.04.

# DESCRIPTION

This module adds ordered destruction of objects stored in global variables
in LIFO order during global destruction.

Ordered global destruction is only applicable to objects with DESTROY
methods stored in non-lexical (i.e. global or our) variables (even if
they are in file scope). Lexical our variables behave like global
objects in this regard.

Note that global destruction should be avoided at all. Rather use my
variables for all objects and file handles to get proper timely
destruction and avoid weird sideeffects or even crashes with already
destroyed objects being referenced in DESTROY blocks.

Perl destroys all lexical my and state objects __before__ the first END
block is called, at the end of the scope of each block where they are
defined. Then the END block is executed, and then the remaining package
objects and global IO objects are destructed, i.e. their DESTROY methods
are called.

With a DEBUGGING perl you can use the `-DD` command-line flag to see
the order of global destruction.

# THE PROBLEM

If you store objects in global variables, and those objects contain
references to other objects stored in global variables, then you cannot be
sure of the order in which these objects are destroyed when executing of
Perl is stopped (by reaching the end of the script, or by an `exit()`).

To get the proper behaviour it is better to use lexical my variables.
But sometimes this is not possible, e.g. when you're using [AutoLoader](https://metacpan.org/pod/AutoLoader).

The random way these objects are destroyed, can sometimes be a problem.
This pragma is intended to replace this random behaviour by a deterministic
behaviour.

# THEORY OF OPERATION

The `ogd` pragma install its own version of the `bless()` system function.
This version keeps a list of weakened references to each and every object
created during the execution of Perl.  A cleanup run is done every 1024
objects that have been created, to reduce memory usage of this list of
weakened references.

When execution of Perl stops and `END` code blocks are starting to get
called, an internal subroutine is added as the very last END code block to be
executed.  This is when the [B](https://metacpan.org/pod/B) module is loaded to achieve this feat.

Once all other END code blocks have been executed, the internal subroutine
loops through all still valid weakened references in LIFO (Last In, First Out)
order and executes the `DESTROY` method on them.  In case the DESTROY method
would like to differentiate between a "real" object destruction, or a forced
one, the parameter "1" is given to the DESTROY method.  While looping through
the list of objects, a list of packages in which still valid objects were
available, is built.

When DESTROY has been called on all objects, the internal sub loops through
all the packages it has seen and installs an empty DESTROY subroutine in
those packages.

The internal sub then relinquishes control back to Perl, which will then
call DESTROY on all the objects it still thinks are valid (in more or less
random order).  Since the DESTROY methods have all been replaced by empty
stubs, this is effectively a noop.

# CLASS METHODS

## register

    ogd->register( @object ); # only for blessed objects created in XSUBs

Not all blessed objects in Perl are necessarily created with "bless": they can
also be created in XSUBs and thereby bypass the registration mechanism that
ogd installs for "bless".  For those cases, it is possible to register objects
created in such a manner by calling the "register" class function.  Any object
passed to it will be registered.

# REQUIRED MODULES

    B (any)
    Scalar::Util (with the XS version of List::Util)

# ORDER OF LOADING

Since the `ogd` pragma installs its own version of the `bless()` system
function and it can not work without that special version of bless (unless
you wish to [register](https://metacpan.org/pod/register) your objects yourself).  This means that the `ogd`
pragma needs to be loaded __before__ any modules that you want the special
functionality of `ogd` to be applied to.

This can be achieved by loading the module from the command line (with the
`-m` or `-M` option), or by adding loading of the `ogd` pragma in the
`PERL5OPT` environment variable.

# DEBUGGING

In order to facilitate debugging and testing of `ogd`, the `OGD_DEBUG`
environment variable can be set to a numeric value before loading the `ogd`
pragma for the first time.  Currently, only the value __1__ is supported.
If set, the following messages will be sent to STDERR:

- object registration

    As soon as one or more objects are registered, a line starting with "+",
    followed by the number of objects registered, followed by a newline, will
    be sent to STDERR.  Since this usually happens when the `bless()` function
    is executed, you will usually see this as:

        +1

    on STDERR.

- list cleanup

    If a list cleanup is done (by default, every 1024 object registrations), and
    destroyed objects have been removed, a line starting with "-", followed by
    the original number of elements in the list, followed by "->", the number
    of objects left after cleanup, and a newline.  You would e.g. see this as:

        -1024->564

    on STDERR.

- END block executed

    As soon as the END block of `ogd` itself is executed, a "\*" followed by a
    newline is sent to STDERR:

        *

- objects destroyed

    As soon as all of the valid objects registered have been called with the
    DESTROY method, a "!" followed by the number of objects handled, will be sent
    to STDERR.  E.g.:

        !234

- packages patched

    All of the packages of which the DESTROY method has been replaced by an
    empty stub, followed by the number of objects forcibly destroyed of that
    class between parentheses, will be sent to STDERR prefixed with "x".  For
    instance:

        *Foo(123) Bar(234) Baz(13)

# CLEANUP

In order to reduce the memory requirements of `ogd`, a regular cleanup is
performed on the list of registered objects (which may contain reference to
already destroyed objects).  By default, this happens every 1024 object
registrations, but this can be changed by setting the environment variable
`OGD_CLEANUP` to a numeric value before loading `ogd` the first time.  The
value represents the power of 2 at which a cleanup will be performed: by
default this is 10 (as 2\*\*10 = 1024), but any other positive integer value is
allowed (allowing for more or lesser aggressive cleanup checks).

# TODO

Maybe an `after` and `before` class method should be added to manipulate
the order in which objects will be destroyed at global destruction?

Examples should be added.

Check in which perl version deterministic order of global destruction
was added and __ogd__ is not needed anymore.

# AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

Current maintainer: Reini Urban <rurban@cpan.org>

Please report bugs to the RT ticket queue.

# ACKNOWLEDGEMENTS

Mark Jason Dominus for the initial impetus.  Yitzchak Scott-Thoennes for
the suggestion of using the B module.  Inspired by similar work on
[Thread::Bless](https://metacpan.org/pod/Thread::Bless).

# COPYRIGHT

Copyright (c) 2004, 2012 Elizabeth Mattijsen <liz@dijkmat.nl>.
Copyright (c) 2014 Reini Urban <rurban@cpanel.net>.  All rights
reserved.  This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

# SEE ALSO

[Thread::Bless](https://metacpan.org/pod/Thread::Bless), ["PERL_DESTRUCT_LEVEL" in perlhacktips](https://metacpan.org/pod/perlhacktips#PERL_DESTRUCT_LEVEL)


