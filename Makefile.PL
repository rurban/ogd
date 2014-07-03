require 5.008_001;
use ExtUtils::MakeMaker;
eval "use Devel::Required";

WriteMakefile (
 NAME		=> "ogd",
 AUTHOR		=> 'Elizabeth Mattijsen (liz@dijkmat.nl)',
 ABSTRACT	=> 'ordered global destruction of objects stored in globals',
 VERSION_FROM	=> 'lib/ogd.pm',
 PREREQ_PM	=> { qw(
		    B             0
                    Scalar::Util  1.23
                   ) },
 SIGN           => 1
);

if ($] < 5.008009) {
  # check if the XS versions needs to be updated
  require Scalar::Util;
  Scalar::Util->import('weaken');
}

package MY;
sub depend { "
README.md : \$(VERSION_FROM)
	pod2markdown \$(VERSION_FROM) > \$@"
}
