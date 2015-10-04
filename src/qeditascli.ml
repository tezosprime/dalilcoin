(* Copyright (c) 2015 The Qeditas developers *)
(* Distributed under the MIT software license, see the accompanying
   file COPYING or http://www.opensource.org/licenses/mit-license.php. *)

open Net;;
open Setconfig;;
open Rpc;;

process_config_args();;
process_config_file();;

let build_rpccall r =
  match r with
  | [c] when c = "stop" ->
      (Stop,fun i -> ())
  | [c;n] when c = "addnode" ->
      (AddNode(n),
       fun i ->
	 let by = input_byte i in
	 if by = 0 then
	   Printf.printf "Node not added.\n"
	 else
	   Printf.printf "Node added.\n"
      )
  | (c::_) -> 
      Printf.printf "Unknown rpc command %s.\n" c;
      raise (Failure "Unknown rpc command")
  | [] ->
      Printf.printf "No rpc command was given.\n";
      raise (Failure "Missing rpc command");;

let process_rpccall r f =
  try
    let (s,si,so) = connectlocal !Config.rpcport in
    send_rpccom so r;
    begin
      try
	f si
      with
      | End_of_file -> Printf.printf "Response to call was cut off.\n"; flush stdout
    end;
    Unix.close s
  with
  | Unix.Unix_error(Unix.ECONNREFUSED,m1,m2) when m1 = "connect" && m2 = "" ->
      Printf.printf "Could not connect to Qeditas rpc server.\nConnection refused.\n"
  | Unix.Unix_error(Unix.ECONNREFUSED,m1,m2) ->
      Printf.printf "Could not connect to Qeditas rpc server.\nConnection refused. %s; %s\n" m1 m2;
  | Unix.Unix_error(_,m1,m2) ->
      Printf.printf "Could not connect to Qeditas rpc server.\n%s; %s\n" m1 m2;;

let a = Array.length Sys.argv;;
let rpccallr = ref [];;
let rpcstarted = ref false;;
for i = 1 to a-1 do
  let arg = Sys.argv.(i) in
  if !rpcstarted then
    rpccallr := arg::!rpccallr
  else if not (String.length arg > 1 && arg.[0] = '-') then
    begin
      rpcstarted := true;
      rpccallr := [arg]
    end
done;;
let (r,f) = build_rpccall (List.rev !rpccallr);;
process_rpccall r f;;