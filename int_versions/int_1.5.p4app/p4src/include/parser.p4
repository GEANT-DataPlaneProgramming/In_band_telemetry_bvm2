/*
 * Copyright 2020 PSNC
 *
 * Author: Damian Parniewicz
 *
 * Created in the GN4-3 project.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
 
 
parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {

    state parse_enc_ipv4 {
        packet.extract(hdr.enc_ipv4);
        meta.layer34_metadata.ip_src = hdr.enc_ipv4.srcAddr;
        meta.layer34_metadata.ip_dst = hdr.enc_ipv4.dstAddr;
        meta.layer34_metadata.ip_ver = 8w4;
        meta.layer34_metadata.dscp = hdr.enc_ipv4.dscp;
        transition select(hdr.enc_ipv4.protocol) {
            8w0x11: parse_enc_udp;
            8w0x6: parse_tcp;
            default: accept;
        }
    }
    state parse_enc_udp {
        packet.extract(hdr.enc_udp);
        meta.layer34_metadata.l4_src = hdr.enc_udp.srcPort;
        meta.layer34_metadata.l4_dst = hdr.enc_udp.dstPort;
        meta.layer34_metadata.l4_proto = 8w0x11;
        transition select(meta.layer34_metadata.dscp) {
            6w0x20: parse_int_shim;
            default: accept;
        }
    }
    state parse_gtp {
        packet.extract(hdr.gtp);
        transition select((packet.lookahead<bit<4>>())[3:0]) {
            4w4: parse_enc_ipv4;
            default: accept;
        }
    }
    state parse_int_header {
        packet.extract(hdr.int_header);
        transition accept;
    }
    state parse_int_shim {
        packet.extract(hdr.int_shim);
        transition parse_int_header;
    }
    state parse_tcp {
        packet.extract(hdr.tcp);
        meta.layer34_metadata.l4_src = hdr.tcp.srcPort;
        meta.layer34_metadata.l4_dst = hdr.tcp.dstPort;
        meta.layer34_metadata.l4_proto = 8w0x6;
        transition select(meta.layer34_metadata.dscp) {
            6w0x20: parse_int_shim;
            default: accept;
        }
    }
    state parse_udp {
        packet.extract(hdr.udp);
        meta.layer34_metadata.l4_src = hdr.udp.srcPort;
        meta.layer34_metadata.l4_dst = hdr.udp.dstPort;
        meta.layer34_metadata.l4_proto = 8w0x11;
        transition select(meta.layer34_metadata.dscp, hdr.udp.dstPort) {
            (6w0 &&& 6w0x0, 16w2152 &&& 16w0xffff): parse_gtp;
            (6w0x20 &&& 6w0x3f, 16w0x0 &&& 16w0x0): parse_int_shim;
            default: accept;
        }
    }
    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        meta.layer34_metadata.ip_src = hdr.ipv4.srcAddr;
        meta.layer34_metadata.ip_dst = hdr.ipv4.dstAddr;
        meta.layer34_metadata.ip_ver = 8w4;
        meta.layer34_metadata.dscp = hdr.ipv4.dscp;
        transition select(hdr.ipv4.protocol) {
            8w0x11: parse_udp;
            8w0x6: parse_tcp;
            default: accept;
        }
    }
    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            16w0x800: parse_ipv4;
            default: accept;
        }
    }
    state start {
        transition parse_ethernet;
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.udp);
        packet.emit(hdr.gtp);
        packet.emit(hdr.enc_ipv4);
        packet.emit(hdr.tcp);
        packet.emit(hdr.enc_udp);
        packet.emit(hdr.int_shim);
        packet.emit(hdr.int_header);
        packet.emit(hdr.int_switch_id);
        packet.emit(hdr.int_port_ids);
        packet.emit(hdr.int_q_occupancy);
        packet.emit(hdr.int_ingress_tstamp);
        packet.emit(hdr.int_egress_tstamp);
    }
}

control verifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}
