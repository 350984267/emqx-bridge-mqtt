%% Copyright (c) 2013-2019 EMQ Technologies Co., Ltd. All Rights Reserved.
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.

-module(emqx_bridge_mqtt_rpc_tests).
-include_lib("eunit/include/eunit.hrl").

send_and_ack_test() ->
    %% delegate from gen_rpc to rpc for unit test
    meck:new(gen_rpc, [passthrough, no_history]),
    meck:expect(gen_rpc, call, 4,
                fun(Node, Module, Fun, Args) ->
                        rpc:call(Node, Module, Fun, Args)
                end),
    meck:expect(gen_rpc, cast, 4,
                fun(Node, Module, Fun, Args) ->
                        rpc:cast(Node, Module, Fun, Args)
                end),
    meck:new(emqx_bridge_mqtt, [passthrough, no_history]),
    meck:expect(emqx_bridge_mqtt, import_batch, 3,
                fun(batch, AckFun, _IfRecordMetrics) -> AckFun() end),
    try
        {ok, Pid, Node} = emqx_bridge_mqtt_rpc:start(#{address => node(), if_record_metrics => true}),
        {ok, Ref} = emqx_bridge_mqtt_rpc:send(Node, batch, true),
        receive
            {batch_ack, Ref} ->
                ok
        end,
        ok = emqx_bridge_mqtt_rpc:stop(Pid, Node)
    after
        meck:unload(gen_rpc),
        meck:unload(emqx_bridge_mqtt)
    end.
