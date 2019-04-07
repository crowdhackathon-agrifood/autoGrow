import time
import TCP

########################################################################
## Main code
while True:
  try:
    TCP.SocketProcess()
  except:
    pass

  time.sleep(0.01)
