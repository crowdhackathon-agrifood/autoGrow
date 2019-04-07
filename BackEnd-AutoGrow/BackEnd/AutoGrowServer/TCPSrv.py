import time, socket, select
import Cmd, ServerProcess

Port = 8888

AliveSendEvery = 2    # Send alive every x seconds
LastAliveSent = -AliveSendEvery  # Make sure it fires immediatelly

########################################################################
## Init Socket

def SetSocketOptions(aSocket):
  aSocket.setblocking(False);
  aSocket.settimeout(0.5)
  aSocket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
  aSocket.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, True)
  aSocket.setsockopt(socket.SOL_SOCKET, socket.SO_KEEPALIVE, True)
  return
  
# Listener socket
Socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM, socket.IPPROTO_TCP)
try:
  SetSocketOptions(Socket)
  # Bind socket to local host and port
  Socket.bind(('', Port))
  Socket.listen(socket.SOMAXCONN)
  
except socket.error as msg:
  print 'Server socket creation failed with error message (' + str(msg[0]) + '): ' + msg[1]
  print 'Server will now exit'
  Socket.close
  raise

print 'Server socket activated'

# List of socket clients, contains by default also the listener
ConnectionList = [Socket] 

########################################################################
## Socket line helper functions

def SocketConnected(aSocket):
  return aSocket in ConnectionList
  
def SocketDisconnect(aSocket):
  if SocketConnected(aSocket):
    try:
      print "Client disconnected"
      ConnectionList.remove(aSocket)
      aSocket.shutdown()  # Destroy connection
      aSocket.close()  # Destroy socket object
    except:
      pass

  return
  
def SocketIsReadable(aSocket):
  if not SocketConnected(aSocket):
    Result = False
  else:
    ReadableSockets, WritableSockets, ErrorSockets = select.select([aSocket], [], [], 0)
    Result = len(ReadableSockets) > 0

  return Result
  
def ReceiveBytes(aSocket, aNumBytes):
  Result = ""
  try:
    while len(Result) != aNumBytes:
      Received = aSocket.recv(aNumBytes - len(Result))
      if not Received:
        raise Exception("Socket disconnected while reading")
      Result = Result + Received
      try:
        Tasks.DoTasks()
      except:
        pass
  except:
    SocketDisconnect(aSocket)
    raise
    
  return Result

def SendBytes(aSocket, aBuffer):
  try:
    aSocket.sendall(aBuffer)
  except:
    SocketDisconnect(aSocket)
    raise  
  return
  
MaxPacketLengthCharacters = 6;
MaxCmdLengthCharacters = 3;

def ProcessResultBuffer(aSocket, aBufferType):
	
  Response = ReceiveBytes(aSocket, MaxPacketLengthCharacters)
  BytesInPacket = int(Response)
  Response = ReceiveBytes(aSocket, BytesInPacket)

  return Response
  
def SocketProcess():

  ReadSockets, WriteSockets, ErrorSockets = select.select(ConnectionList, [], [], 0)
  
  for Sock in ReadSockets:
    # New connection
    if Sock == Socket:
      (NewSocket, (NewAddr, NewPort)) = Sock.accept()
      
      ConnectionList.append(NewSocket)
      SetSocketOptions(NewSocket)
      print "Client (%s) connected" % NewAddr
    else:
      # Check incoming messages from the peer
      while SocketConnected(Sock) and SocketIsReadable(Sock):
        try:
          BufferType = ReceiveBytes(Sock, 1)  
        except:
          pass

  return
