package Math::Int64::die_on_overflow;

sub import {
    require Math::Int64;
    Math::Int64::_set_may_die_on_overflow(1);
    $^H{'Math::Int64::die_on_overflow'} = 1
}


sub unimport {
    undef $^H{'Math::Int64::die_on_overflow'}
}

1;
