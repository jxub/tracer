-file("case-studies/barber/barber.erl", 1).
-module(barber).
-export([main/0,open_barber_shop/0,barber/1,customer/3]).
main() ->
    io:format("~nCustomers: John and Joe~n~n"),
    ShopPid = spawn(barber, open_barber_shop, []),
    spawn(barber, customer, [ShopPid, 'John', self()]),
    spawn(barber, customer, [ShopPid, 'Joe', self()]),
    receive
        {send, tmp$^1, _, {Name1, State1}} ->
            {undefined, nonode@nohost} ! {'receive', tmp$^1},
            io:format("~p ~p~n", [Name1, State1])
    end,
    receive
        {send, tmp$^2, _, {Name2, State2}} ->
            {undefined, nonode@nohost} ! {'receive', tmp$^2},
            io:format("~p ~p~n", [Name2, State2])
    end,
    tracer_erlang:send_centralized(ShopPid, stop).
customer(ShopPid, Name, MainPid) ->
    tracer_erlang:send_centralized(ShopPid, {new, {self(), Name}}),
    receive
        {send, tmp$^1, _, X} ->
            {undefined, nonode@nohost} ! {'receive', tmp$^1},
            tracer_erlang:send_centralized(MainPid, {Name, X})
    end.
barber(ShopPid) ->
    tracer_erlang:send_centralized(ShopPid, ready),
    receive
        {send, tmp$^1, _, wakeup} ->
            {undefined, nonode@nohost} ! {'receive', tmp$^1},
            barber(ShopPid);
        {send, tmp$^2, _, {customer, Customer}} ->
            {undefined, nonode@nohost} ! {'receive', tmp$^2},
            tracer_erlang:send_centralized(ShopPid, {cut, Customer}),
            barber(ShopPid)
    end.
open_barber_shop() ->
    BarberPid = spawn(barber, barber, [self()]),
    barber_shop(BarberPid, []).
barber_shop(BarberPid, CustomersInChairs) ->
    receive
        {send, tmp$^1, _, {cut, {CustomerPid, _}}} ->
            {undefined, nonode@nohost} ! {'receive', tmp$^1},
            tracer_erlang:send_centralized(CustomerPid, finished),
            barber_shop(BarberPid, CustomersInChairs);
        {send, tmp$^2, _, ready} ->
            {undefined, nonode@nohost} ! {'receive', tmp$^2},
            respond_to_barber(BarberPid, CustomersInChairs);
        {send, tmp$^3, _, {new, CustomerInfo}} ->
            {undefined, nonode@nohost} ! {'receive', tmp$^3},
            add_customer_if_available(BarberPid, CustomerInfo, CustomersInChairs);
        {send, tmp$^4, _, stop} ->
            {undefined, nonode@nohost} ! {'receive', tmp$^4},
            stop
    end.
respond_to_barber(BarberPid, []) ->
    barber_shop(BarberPid, []);
respond_to_barber(BarberPid, List) ->
    tracer_erlang:send_centralized(BarberPid, {customer, last(List)}),
    barber_shop(BarberPid, removeCustomer(List)).
add_customer_if_available(BarberPid, {CustomerPid, _CustomerName}, [X, Y | R]) ->
    tracer_erlang:send_centralized(CustomerPid, no_room),
    barber_shop(BarberPid, [X, Y | R]);
add_customer_if_available(BarberPid, {CustomerPid, CustomerName}, List) ->
    tracer_erlang:send_centralized(BarberPid, wakeup),
    barber_shop(BarberPid, [{CustomerPid, CustomerName} | List]).
last([A]) ->
    A;
last([_A | R]) ->
    last(R).
removeCustomer([_A | R]) ->
    R.

