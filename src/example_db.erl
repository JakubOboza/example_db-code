-module(example_db).
-behaviour(gen_server).

-author("jakub.oboza@gmail.com").
-define(Prefix, "example").

-export([start_link/0]).
-export([init/1, handle_call/3, handle_cast/2, terminate/2, handle_info/2, code_change/3, stop/1]).
-export([get_script/2, save_script/3]).

% public api

start_link() ->
  gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
  {ok, Redis} = eredis:start_link(),
  {ok, Redis}.

stop(_Pid) ->
  stop().

stop() ->
    gen_server:cast(?MODULE, stop).

%% public client api

get_script(Api, Method) ->
  gen_server:call(?MODULE, {get_script, Api, Method}).

save_script(Api, Method, Script) ->
  gen_server:call(?MODULE, {save_script, Api, Method, Script}).

%% genserver handles

handle_call({get_script, Api, Method}, _From, Redis) ->
  Response = eredis:q(Redis, [ "GET", get_key(Api, Method) ]),
  {reply, Response, Redis};

handle_call({save_script, Api, Method, Script}, _From, Redis) ->
  Response = eredis:q(Redis, ["SET", get_key(Api, Method), Script]),
  {reply, Response, Redis};

handle_call(_Message, _From, Redis) ->
  {reply, error, Redis}.

handle_cast(_Message, Redis) -> {noreply, Redis}.
handle_info(_Message, Redis) -> {noreply, Redis}.
terminate(_Reason, _Redis) -> ok.
code_change(_OldVersion, Redis, _Extra) -> {ok, Redis}.

%% helper methods

get_key(Api, Method) ->
  generate_key([Api, Method]).

generate_key(KeysList) ->
  lists:foldl(fun(Key, Acc) -> Acc ++ ":" ++ Key end, ?Prefix, KeysList).

% tests

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
-endif.


-ifdef(TEST).

generate_key_test() ->
  Key = generate_key(["one", "two", "three"]),
  ?assertEqual("example:one:two:three", Key).

server_test_() ->
  {setup, fun() -> example_db:start_link() end,
   fun(_Pid) -> example_db:stop(_Pid) end,
   fun generate_example_db_tests/1}.

generate_example_db_tests(_Pid) ->
  [
    ?_assertEqual({ok,<<"OK">>}, example_db:save_script("jakub", "oboza", <<"yo dwang">>) ),
    ?_assertEqual({ok,<<"yo dwang">>}, example_db:get_script("jakub", "oboza") )
  ].

-endif.
