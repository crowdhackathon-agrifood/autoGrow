import Cmd

def ProcessCommand(aSocket, aCmd, aData):

  Result = None
  
  print "Process Command: " + str(aCmd) + ", Data: " + aData

  Result = "CMD EXECUTED ON SERVER"
    
  return Result
