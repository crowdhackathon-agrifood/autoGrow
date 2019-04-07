import time
import TCPSrv

########################################################################
## Main code
while True:
  try:
    TCPSrv.SocketProcess()
  except:
    pass

  time.sleep(0.01)
