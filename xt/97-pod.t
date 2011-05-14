#!perl -T

BEGIN {
    unless ($ENV{AUTHOR_TESTING}) {
        require Test::More;
        Test::More::plan(skip_all => 'these tests are for testing by the author');
    }
}

eval "use Test::Pod 1.14";
all_pod_files_ok();
