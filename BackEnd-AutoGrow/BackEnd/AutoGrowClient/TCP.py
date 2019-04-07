import time, socket, select
import Cmd, ClientProcess

Host = ""
Port = 8888

AliveSendEvery = 2    # Send alive every x seconds
LastAliveSent = -AliveSendEvery  # Make sure it fires immediatelly

########################################################################
## Init Socket

SocketConnected = False
Socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM, socket.IPPROTO_TCP)
Socket.setblocking(False)
Socket.settimeout(0.5)
Socket.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, True)
Socket.setsockopt(socket.SOL_SOCKET, socket.SO_KEEPALIVE, True)

########################################################################
## Socket line helper functions
def SetSocketConnectedInternal(aConnected):
  global SocketConnected
  
  if aConnected != SocketConnected:
    SocketConnected = aConnected
    if SocketConnected:
      print "Connected to Server"
    else:
      print "Disconnected from Server"

  return

def SocketConnect():
  global SocketConnected

  if not SocketConnected:  
    Socket.connect((Host, Port))
    SetSocketConnectedInternal(True)

  return 
  
def SocketDisconnect():
  global SocketConnected

  if SocketConnected:
    try:
      SetSocketConnectedInternal(False)
      Socket.shutdown()
    except:
      pass

  return
  
def SocketIsReadable():
  if not SocketConnected:
    Result = False
  else:
    ReadableSockets, WritableSockets, ErrorSockets = select.select([Socket], [], [], 0)
    Result = len(ReadableSockets) > 0
  
  return Result
  
def ReceiveBytes(aNumBytes):
  Result = ""
  try:
    while len(Result) != aNumBytes:
      Received = Socket.recv(aNumBytes - len(Result))
      if not Received:
        raise Exception("Socket disconnected while reading")
      SetSocketConnectedInternal(True)
      Result = Result + Received
  except:
    SocketDisconnect()
    raise
      
  return Result

def SendBytes(aBuffer):
  global SocketConnected
  try:
    Socket.sendall(aBuffer)
    SetSocketConnectedInternal(True)
  except:
    SocketDisconnect()
    raise  
  return
  
MaxPacketLengthCharacters = 6
MaxCmdLengthCharacters = 3

def ProcessResultBuffer(aBufferType):
	
  Response = ReceiveBytes(MaxPacketLengthCharacters)
  BytesInPacket = int(Response)
  Response = ReceiveBytes(BytesInPacket)

  return Response
  
def SocketProcess():
	
  # Check incoming messages from the peer
  while SocketConnected and SocketIsReadable():
    try:
      BufferType = ReceiveBytes(1)  # ctInitiator, ctResponse or ctResponseException
      if BufferType == ctInitiator:
        ProcessInitiatorBuffer()
      else:
        ProcessResultBuffer(ctResponse)
    except:
      pass

  return
