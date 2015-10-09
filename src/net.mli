(* Copyright (c) 2015 The Qeditas developers *)
(* Distributed under the MIT software license, see the accompanying
   file COPYING or http://www.opensource.org/licenses/mit-license.php. *)

open Hash
open Signat
open Tx
open Ctre
open Block

exception RequestRejected
exception IllformedMsg

val extract_ip_and_port : string -> string * int * bool

val sethungsignalhandler : unit -> unit
val accept_nohang : Unix.file_descr -> float -> (Unix.file_descr * Unix.sockaddr) option
val input_byte_nohang : in_channel -> float -> int option

val openlistener : string -> int -> int -> Unix.file_descr
val connectpeer : string -> int -> Unix.file_descr
val connectpeer_socks4 : int -> string -> int -> Unix.file_descr * in_channel * out_channel

type msg =
  | Version of int32 * int64 * int64 * string * string * int64 * string * rframe * rframe * rframe * int64 * int64 * bool * (int64 * hashval) option
  | Verack
  | Addr of (int64 * string) list
  | Inv of (int * hashval) list
  | GetData of (int * hashval) list
  | MNotFound of (int * hashval) list
  | GetBlocks of int32 * int64 * hashval option
  | GetBlockdeltas of int32 * int64 * hashval option
  | GetBlockdeltahs of int32 * int64 * hashval option
  | GetHeaders of int32 * int64 * hashval option
  | MTx of int32 * stx (*** signed tx in principle, but in practice some or all signatures may be missing ***)
  | MBlock of int32 * block
  | Headers of blockheader list
  | MBlockdelta of int32 * hashval * blockdelta (*** the hashval is for the block header ***)
  | MBlockdeltah of int32 * hashval * blockdeltah (*** the hashval is for the block header; the blockdeltah only has the hashes of stxs in the block ***)
  | GetAddr
  | Mempool
  | Alert of string * signat
  | Ping
  | Pong
  | Reject of string * int * string * string
  | GetFramedCTree of int32 * int64 option * hashval * rframe
  | MCTree of int32 * ctree
  | Checkpoint of int64 * hashval
  | AntiCheckpoint of int64 * hashval

type pendingcallback = PendingCallback of (msg -> pendingcallback option)

type connstate = {
    mutable alive : bool;
    mutable lastmsgtm : float;
    mutable pending : (hashval * bool * float * float * pendingcallback option) list;
    mutable rframe0 : rframe; (*** which parts of the ctree the node is keeping ***)
    mutable rframe1 : rframe; (*** what parts of the ctree are stored by a node one hop away ***)
    mutable rframe2 : rframe; (*** what parts of the ctree are stored by a node two hops away ***)
    mutable first_height : int64; (*** how much history is stored at the node ***)
    mutable last_height : int64; (*** how up to date the node is ***)
  }

val send_msg : out_channel -> msg -> hashval
val send_reply : out_channel -> hashval -> msg -> hashval

val rec_msg_nohang : in_channel -> float -> float -> (hashval option * hashval * msg) option

val handle_msg : in_channel -> out_channel -> connstate -> hashval option -> hashval -> msg -> unit

