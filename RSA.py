"""
    RSA algorithm & signature
"""


import random
import hashlib

"""
     RSA algorithm
    1. generate two large prime numbers p and q
    2. calculate n = p * q
    3. calculate phi(n) = (p - 1) * (q - 1)
    4. choose an integer e such that 1 < e < phi(n) and gcd(e, phi(n)) = 1
    5. calculate d such that d * e = 1 mod phi(n)
    6. the public key is (e, n) and the private key is (d, n)
"""
# calculate the greatest common divisor(gcd) of two numbers
def gcd(a,b):
    while b != 0:
        a, b = b, a % b
    return a

# verifiy prime number
def is_prime(n):
    if n <= 1:
        return False
    if n <= 3:
        return True
    if n % 2 == 0 or n % 3 == 0:
        return False
    i = 5
    while i * i <= n:
        if n % i == 0 or n % (i + 2) == 0:
            return False
        i += 6
    return True

# generate random prime number
def generate_prime(start=300, end=999):
    while True:
        p = random.randint(start, end)
        if is_prime(p):
            return p

# calculate the modular inverse
def mod_inverse(a, m):
    m0, x0, x1 = m, 0, 1
    while a > 1:
        q = a // m
        a, m = m, a % m
        x0, x1 = x1 - q * x0, x0
    if x1 < 0:
        x1 += m0
    return x1

# generate the public and private key
def generate_rsa_keypair():
    while True:
        p = generate_prime()
        q = generate_prime()
        while p == q:
            q = generate_prime()
        n = p * q
        phi = (p-1) * (q-1)
        e = 65537
        if gcd(e, phi) == 1:
            d = mod_inverse(e, phi)
            return (e, n), (d, n) # public key and private key

"""
    hash value
    prefix 0000
"""
# generate hash value
# function to calculate the nonce
def pow_hash():
    nickname = "Gold"
    nouce = 0 # from 0 
    prefix = "0" * 4

    while True:
        content = f"{nickname}{nouce}"
        hash_value = hashlib.sha256(content.encode()).hexdigest() # hash the content
        if hash_value.startswith(prefix): 
            # if the hash value starts with the prefix, then the nonce is found
            print(f"nonce is {nouce}")
            print(f"Hash is {hash_value}")
            break
        nouce += 1
    return int(hash_value,16), content

# generate the signature
def generate_signature(hash_value, private_key):
    d, n = private_key
    signature = pow(hash_value, d, n)
    return signature

# verify the signature
def verify_signature(content,signature,public_key):
    e, n = public_key
    hash_value = hashlib.sha256(content.encode()).hexdigest()
    hash_int = int(hash_value,16) % n
    verified = (pow(signature, e, n) == hash_int)
    return verified



if __name__ == "__main__":
    hash_value, content = pow_hash()
    print(f"hash value: {hash_value}")
    print(f"content: {content}")
    public_key, private_key = generate_rsa_keypair()
    print(f"public key: {public_key}")
    print(f"private key: {private_key}")
    signature = generate_signature(hash_value, private_key)
    print(f"signature: {signature}")
    verified = verify_signature(content, signature, public_key)
    print(f"verified: {verified}")

