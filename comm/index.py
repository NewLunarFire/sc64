from src.sc64.comm import Sc64Comm
from src.oot.comm import OotComm

save_context = 0x8011A5D0
zeldaz = 0x001C
rupees = 0x0034

def main():
    #comm = Sc64Comm()
    comm = OotComm()

    if not comm.connect():
        print("Device not available")
        return
    
    res = comm.read_memory(address=save_context + zeldaz, size=6)

    # comm.read_memory(address=0x8011A604, size=2)

    #res = comm.write_memory(address=0x05000000, data=bytes([x for x in range(0,32)]))    
    #print(res)
    #res = comm.read_memory(address=0x05000000, size=32)
    #print(res)

    while True:
        comm.sc64.read()

if __name__ == "__main__":
    main()
