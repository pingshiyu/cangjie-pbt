// Optional shared/pure generators for net PBT (e.g. randPortInRange) can go here.
// Currently all generators are methods on NetContext in net_testing_lib.cj.
package cangjie_experiments

import std.collection.*
import std.net.*
import std.fs.*
import cangjie_experiments.pbt.*

// --- TCP state: servers (socket, bound, closed); clients (socket, connected, closed).
// We use parallel lists; index i in each list corresponds to the same entry.
// After bind(), server's localAddress (as IPSocketAddress).port is used for client connect to localhost.

public class NetContext {
    // TCP servers: created by tcpServerCreate; after bind() the entry is marked bound.
    let tcpServers: ArrayList<TcpServerSocket> = ArrayList()
    var tcpServerBound: ArrayList<Bool> = ArrayList()
    var tcpServerClosed: ArrayList<Bool> = ArrayList()

    // TCP clients: created by tcpClientCreate; after connect() the entry is marked connected.
    // Peer/hasData: peer index (-1 = none); hasData set when peer writes; serverIndex for pairing on accept.
    let tcpClients: ArrayList<TcpSocket> = ArrayList()
    var tcpClientConnected: ArrayList<Bool> = ArrayList()
    var tcpClientClosed: ArrayList<Bool> = ArrayList()
    var tcpClientServerIndex: ArrayList<Int64> = ArrayList()
    var tcpClientPeerIndex: ArrayList<Int64> = ArrayList()
    var tcpClientHasData: ArrayList<Bool> = ArrayList()

    let tmpRoot: String

    public init(tmpRoot: String) {
        this.tmpRoot = tmpRoot
    }

    // --- Helpers: get port from a bound TCP server (localAddress is Option<SocketAddress>; cast to IPSocketAddress yields Option<IPSocketAddress>).
    private func tcpServerPortAtIndex(i: Int64): UInt16 {
        let opt: Option<SocketAddress> = tcpServers[i].localAddress
        if (!opt.isSome()) {
            throw Exception("tcpServerPortAtIndex: server not bound")
        }
        let raw: SocketAddress = opt.getOrThrow()
        let addrOpt: Option<IPSocketAddress> = raw as IPSocketAddress
        if (!addrOpt.isSome()) {
            throw Exception("tcpServerPortAtIndex: localAddress not IPSocketAddress")
        }
        let addr: IPSocketAddress = addrOpt.getOrThrow()
        return addr.port
    }

    // --- Generators used by getTcpRunners

    // Returns an index of a TcpServerSocket that is bound and not closed; creates one if none exist.
    private func randBoundTcpServerIndex(): Int64 {
        for (i in 0..tcpServers.size) {
            if (tcpServerBound[i] && !tcpServerClosed[i]) {
                return i
            }
        }
        let server = TcpServerSocket(bindAt: 0u16)
        tcpServers.add(server)
        tcpServerBound.add(false)
        tcpServerClosed.add(false)
        server.bind()
        tcpServerBound[tcpServerBound.size - 1] = true
        return tcpServers.size - 1
    }

    // Non-empty byte array for read/write buffers. Size in [1, 1024] for TCP.
    public func randSmallByteArray(): Array<Byte> {
        let n = randIntRange(1, 1025)
        return randSmallBytes(n: n)().toArray()
    }

    /** Returns a connected TCP socket index that has data to read (so read won't block). Ensures one by writing from peer if needed. */
    public func randConnectedTcpSocketIndexWithData(): Int64 {
        for (i in 0..tcpClients.size) {
            if (tcpClientConnected[i] && !tcpClientClosed[i] && tcpClientHasData[i]) {
                return i
            }
        }
        for (i in 0..tcpClients.size) {
            let j = tcpClientPeerIndex[i]
            if (j >= 0 && tcpClientPeerIndex[j] == i && tcpClientConnected[j] && !tcpClientClosed[j]) {
                let payload = randSmallByteArray()
                tcpSocketWriteIndex(j, payload)
                return i
            }
        }
        let si = randBoundTcpServerIndex()
        let port = tcpServerPortAtIndex(si)
        let clientAddr = IPSocketAddress(IPv4Address.localhost, port)
        let client = TcpSocket(clientAddr)
        client.readTimeout = Some(streamReadTimeout)
        tcpClients.add(client)
        tcpClientConnected.add(false)
        tcpClientClosed.add(false)
        tcpClientServerIndex.add(si)
        tcpClientPeerIndex.add(-1)
        tcpClientHasData.add(false)
        client.connect()
        tcpClientConnected[tcpClientConnected.size - 1] = true
        let clientIdx = tcpClients.size - 1
        let _ = tcpServerAccept(si)
        let acceptedIdx = tcpClients.size - 1
        let payload = randSmallByteArray()
        tcpSocketWriteIndex(clientIdx, payload)
        return acceptedIdx
    }

    // --- TCP wrapper methods (the two used by getTcpRunners)

    /** Pre: none. Post: new TcpServerSocket(0) created and recorded; not bound, not closed. */
    public func tcpServerCreateUnit(): Unit {
        let server = TcpServerSocket(bindAt: 0u16)
        tcpServers.add(server)
        tcpServerBound.add(false)
        tcpServerClosed.add(false)
    }

    private static let acceptShortTimeout: Duration = 20 * Duration.millisecond
    private static let streamReadTimeout: Duration = 500 * Duration.millisecond

    /** Pre: i is randBoundTcpServerIndex (bound and not closed). Post: returns connected TcpSocket; optionally record in state. May throw SocketTimeoutException. */
    private func tcpServerAccept(i: Int64): TcpSocket {
        if (i < 0 || i >= tcpServers.size || tcpServerClosed[i] || !tcpServerBound[i]) {
            throw Exception("tcpServerAccept precondition violated: server must be bound and not closed")
        }
        let client = tcpServers[i].accept(timeout: Some(acceptShortTimeout))
        client.readTimeout = Some(streamReadTimeout)
        let newIdx = tcpClients.size
        tcpClients.add(client)
        tcpClientConnected.add(true)
        tcpClientClosed.add(false)
        tcpClientServerIndex.add(i)
        var peerK: Int64 = -1
        var unpairedCount: Int64 = 0
        for (k in 0..tcpClients.size - 1) {
            if (tcpClientServerIndex[k] == i && tcpClientConnected[k] && tcpClientPeerIndex[k] == -1) {
                unpairedCount += 1
                peerK = k
            }
        }
        if (unpairedCount != 1) {
            peerK = -1
        }
        tcpClientPeerIndex.add(peerK)
        tcpClientHasData.add(false)
        if (peerK >= 0) {
            tcpClientPeerIndex[peerK] = newIdx
        }
        return client
    }

    /** Pre: i valid index; socket connected and not closed; buffer non-empty; hasData so read won't block. Post: hasData cleared for i. */
    public func tcpSocketReadIndex(i: Int64, buffer: Array<Byte>): Unit {
        if (buffer.isEmpty()) {
            return
        }
        if (i < 0 || i >= tcpClients.size || tcpClientClosed[i] || !tcpClientConnected[i]) {
            return
        }
        let _ = tcpClients[i].read(buffer)
        tcpClientHasData[i] = false
    }

    /** Pre: i valid index; socket connected and not closed; payload non-empty. Post: peer's hasData set. Used by randConnectedTcpSocketIndexWithData. */
    private func tcpSocketWriteIndex(i: Int64, payload: Array<Byte>): Unit {
        if (payload.isEmpty()) {
            return
        }
        if (i < 0 || i >= tcpClients.size || tcpClientClosed[i] || !tcpClientConnected[i]) {
            return
        }
        tcpClients[i].write(payload)
        let peer = tcpClientPeerIndex[i]
        if (peer >= 0) {
            tcpClientHasData[peer] = true
        }
    }

    public func initialiseContext(): Unit {
        if (!exists(Path(tmpRoot))) {
            Directory.create(Path(tmpRoot), recursive: true)
        }
        let _ = randBoundTcpServerIndex()
    }

    public func cleanup(): Unit {
        for (i in 0..tcpClients.size) {
            if (!tcpClientClosed[i]) {
                tcpClients[i].close()
            }
        }
        for (i in 0..tcpServers.size) {
            if (!tcpServerClosed[i]) {
                tcpServers[i].close()
            }
        }
    }
}
