
use ExtUtils::MakeMaker;

use Config;

my $backend;

if ($Config::Config{ivsize} == 8) {
    $backend = 'NATIVE';
}
elsif ($Config::Config{doublesize} == 8) {
    $backend = 'DOUBLE';
}
else {
    $backend = 'STRING';
}

# we force the DOUBLE backend for the moment...
$backend = 'DOUBLE';

unless ($Config::Config{d_atoll} and $Config::Config{i64type}
        and $Config::Config{d_int64_t} and $Config::Config{i64size} == 8) {
    die "Your C compiler does not have enough support for int64 values\n";
}


WriteMakefile( NAME              => 'Math::Int64',
               VERSION_FROM      => 'lib/Math/Int64.pm',
               PREREQ_PM         => {},
               ABSTRACT_FROM  => 'lib/Math/Int64.pm', # retrieve abstract from module
               AUTHOR         => 'Salvador Fandino <sfandino@yahoo.com>',
               LIBS              => [''], # e.g., '-lm'
               DEFINE            => "-DINTEGER64_BACKEND_$backend",
               INC               => '-I.', # e.g., '-I. -I/usr/include/other'
);
