require 5.008001;
use ExtUtils::MakeMaker;
eval "use Devel::Required";

WriteMakefile (
 NAME		=> "ogd",
 AUTHOR		=> 'Elizabeth Mattijsen (liz@dijkmat.nl)',
 ABSTRACT	=> 'ordered global destruction for objects',
 VERSION_FROM	=> 'lib/ogd.pm',
 PREREQ_PM	=> { qw(
		    B             0
                    Scalar::Util  0
                   ) },
);
