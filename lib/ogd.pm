package ogd;

# Make sure we have version info for this module
# Make sure we do everything by the book from now on

$VERSION = '0.01';
use strict;

# Make sure we can find out the blessing of an object and to weaken it

use Scalar::Util qw(blessed weaken);

# Initialize counter for number of objects registered
# List with objects that should be destroyed (first is a dummy object)

my $registered = 0;
my @object;

# Make sure we do this before anything else
#  Allow for dirty tricks
#  Obtain current setting
#  See if we can call it
#  Use the core one if it was an empty subroutine reference

BEGIN {
    no strict 'refs'; no warnings 'redefine';
    my $old = \&CORE::GLOBAL::bless;
    eval {$old->()};
    $old = undef if $@ =~ m#CORE::GLOBAL::bless#;

#  Steal the system bless with a sub
#   Obtain the class
#   Create the object with the given parameters
#   Save weakened ref keyed to address if objects of this package are handled
#   Return the blessed object

    *CORE::GLOBAL::bless = sub {
        my $class = $_[1] || caller();
        my $object = $old ? $old->( $_[0],$class ) : CORE::bless $_[0],$class;
        __PACKAGE__->register( $object );
        $object;
    };
} #BEGIN

# Make sure the shutting down sequence will be called way at the end

END { require B; push @{B::end_av()->object_2svref}, \&_shutting_down } #END

# Satisfy -require-

1;

#---------------------------------------------------------------------------
#
# Class methods
#
#---------------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2..N objects to register

sub register {

# Lose the class
# Store weakened references to the object in the global list

    shift;
    weaken( $object[@object] = shift ) while @_;
#    weaken( $object[@object] = $_ ) foreach @_; # doesn't work, why?

# Remember current number of objects registered (ever)
# Increment for number of objects registered
# Clean up the list if again 1024 objects were registered (since last time)

    my $old = $registered;
    $registered += @_;
    @object = grep { defined } @object if ($registered & 1023) > ($old & 1023);
} #register

#---------------------------------------------------------------------------
#
# Internal methods
#
#---------------------------------------------------------------------------

sub _shutting_down {

# Initialize hash with packages handled
# While there are objects to process
#  Obtain newest object, reloop if it is already dead
#  Mark the package as used
#  Execute the DESTROY method on it

    my %package;
    while (@object) {
        next unless my $object = pop @object;
        $package{blessed $object}++;
        $object->DESTROY;
    }

# Make sure we'll be silent about the dirty stuff
# Replace DESTROY subs of all packages with an empty stub

    no strict 'refs'; no warnings 'redefine';
    *{$_.'::DESTROY'} = \&_destroy foreach keys %package;
} #_shutting_down

#---------------------------------------------------------------------------
#  IN: 1 instantiated object (ignored)
#
# This is the empty DESTROY stub that replaces any actual DESTROY subs
# after all objects have been destroyed.

sub _destroy { } #_destroy

#---------------------------------------------------------------------------

__END__

=head1 NAME

ogd - ordered global destruction of objects

=head1 SYNOPSIS

 use ogd;

 ogd->register( @object ); # for objects from XSUBs only

=head1 DESCRIPTION

This module adds ordered destruction of object in LIFO order during global
destruction.

=head1 CLASS METHODS

=head2 register

 ogd->register( @object ); # only for blessed objects created in XSUBs

Not all blessed objects in Perl are necessarily created with "bless": they can
also be created in XSUBs and thereby bypass the registration mechanism that
ogd installs for "bless".  For those cases, it is possible to register objects
created in such a manner by calling the "register" class function.  Any object
passed to it will be registered.

=head1 REQUIRED MODULES

 B (any)
 Scalar::Util (any)

=head1 ORDER OF LOADING

The C<ogd> pragma installs its own version of the "bless" system function.
Without that special version of "bless", it can not work (unless you
L<register> your objects yourself).  This means that the C<ogd> pragma
needs to be loaded B<before> any modules that you want the special
functionality of C<ogd> to be applied to.

=head1 TODO

Examples should be added.

=head1 AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

Please report bugs to <perlbugs@dijkmat.nl>.

=head1 ACKNOWLEDGEMENTS

Mark Jason Dominus for the initial impetus.  Yitzchak Scott-Thoennes for
the suggestion of using the B module.  Inspired by similar work on
L<Thread::Bless>.

=head1 COPYRIGHT

Copyright (c) 2004 Elizabeth Mattijsen <liz@dijkmat.nl>. All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Thread::Bless>.

=cut
