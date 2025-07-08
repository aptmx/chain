"""
 calculate the nonce
"""

import hashlib
import time

# function to calculate the nonce
def pow(prefix_zeros):
    nickname = "Gold"
    nouce = 0 # from 0 
    prefix = "0" * prefix_zeros
    start_time = time.time()

    while True:
        content = f"{nickname}{nouce}"
        hash_value = hashlib.sha256(content.encode()).hexdigest() # hash the content
        if hash_value.startswith(prefix): 
            # if the hash value starts with the prefix, then the nonce is found
            time_elapsed = time.time() - start_time
            print(f"prefix zeros is {prefix_zeros}")
            print(f"content is {content}")
            print(f"nonce is {nouce}")
            print(f"Hash is {hash_value}")
            print(f"time needed {time_elapsed}")
            print("-"*50)
            break
        nouce += 1

if __name__ == "__main__":
    pow(4)
    pow(5)





