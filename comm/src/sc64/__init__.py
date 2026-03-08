from .comm import Sc64Comm

sc64 = None
def get_sc64():
    global sc64
    
    if not sc64:
        sc64 = Sc64Comm()

    return sc64