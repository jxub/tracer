tracer
=====

An OTP application

Build
-----

    $ rebar3 compile


Running
-------

    $ rebar3 shell
    1> tracer:trace(barber, main, [], [{dir, "case-studies/barber"}, {output, "case-studies/barber/trace"}]).
