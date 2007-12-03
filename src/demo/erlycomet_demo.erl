%%%---------------------------------------------------------------------------------------
%%% @author     Roberto Saccon <rsaccon@gmail.com> [http://rsaccon.com]
%%% @copyright  2007 Roberto Saccon
%%% @doc        ErlyComet Demo Chat Application
%%% @reference  See <a href="http://erlycomet.googlecode.com" target="_top">http://erlycomet.googlecode.com</a> for more information
%%% @end
%%%
%%%
%%% The MIT License
%%%
%%% Copyright (c) 2007 Roberto Saccon
%%%
%%% Permission is hereby granted, free of charge, to any person obtaining a copy
%%% of this software and associated documentation files (the "Software"), to deal
%%% in the Software without restriction, including without limitation the rights
%%% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
%%% copies of the Software, and to permit persons to whom the Software is
%%% furnished to do so, subject to the following conditions:
%%%
%%% The above copyright notice and this permission notice shall be included in
%%% all copies or substantial portions of the Software.
%%%
%%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%%% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%%% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
%%% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%%% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
%%% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
%%% THE SOFTWARE.
%%%
%%%---------------------------------------------------------------------------------------
-module(erlycomet_demo).
-author('rsaccon@gmail.com').


%% Api
-export([start/0,
         status/0,
         hello/0,
         stop/0,
         stop/1]).


%% Internal exports
-export([loop/1, loop/4]).


%%====================================================================
%% API functions
%%====================================================================
start() ->
	{ok, App} = application:get_application(),
	Loop = fun ?MODULE:loop/1,
	Args = [{ip, "127.0.0.1"},
	        {loop, Loop}],
	Args1 = case application:get_env(App, http_port) of
	            {ok, Port} ->
	                io:format("Listening on Port: ~p~n",[Port]),
			        [{port, Port} | Args];
			    _ ->
			        Args
			end,
	mochiweb_http:start(Args1).
			
status() ->
    L = erlycomet_dist_server:connections(),
    io:format("Connections: ~p~n",[L]).
  
  
hello() ->
    io:format("Sending: ~p~n",["hello world"]).
  
       
stop() ->
    mochiweb_http:stop(?MODULE),
    register(clock, spawn(fun() ->
				  tick() end)).

stop(Name) ->
    clock ! stop,
    mochiweb_http:stop(Name).

tick() ->
    receive
	stop ->
	    void
    after 1000 ->
	    {_,Secs,_} = now() rem 1000,
	    Channel = "/test/time",
	    Data = [struct, 
		    {data, Secs},
		    {channel, Channel}],
	    erlycomet_dist_server:deliver_to_channel(Channel, Data),
	    tick()
    end.

%%====================================================================
%% Internal functions
%%====================================================================
loop(Req) ->
	DocRoot = filename:join([filename:dirname(code:which(?MODULE)),"..", "demo-docroot"]),
    loop(Req, Req:get(method), Req:get(path), DocRoot).

loop(Req, Method, "/cometd", _) ->
	erlycomet_bayeux:handle(Req, Method);
    	
loop(Req, 'GET', [$/ | Path], DocRoot) ->
    Req:serve_file(Path, DocRoot);
	
loop(Req, _Method, _Path, _) ->
	Req:not_found().
