from .comm import OotComm

comm = None
def get_comm(sc64):
    global comm
    
    if not comm:
        comm = OotComm(sc64)
    
    return comm