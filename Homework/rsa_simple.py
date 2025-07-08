import random

# 辗转相除法求最大公约数
def gcd(a, b):
    while b != 0:
        a, b = b, a % b
    return a

# 扩展欧几里得算法求逆元
def modinv(a, m):
    m0, x0, x1 = m, 0, 1
    while a > 1:
        q = a // m
        a, m = m, a % m
        x0, x1 = x1 - q * x0, x0
    return x1 + m0 if x1 < 0 else x1

# 判断素数
def is_prime(n):
    if n <= 1:
        return False
    for i in range(2, int(n ** 0.5) + 1):
        if n % i == 0:
            return False
    return True

# 随机生成素数
def generate_prime(start=100, end=300):
    while True:
        p = random.randint(start, end)
        if is_prime(p):
            return p

# 生成RSA密钥对
def generate_rsa_keypair():
    p = generate_prime()
    q = generate_prime()
    while q == p:
        q = generate_prime()
    n = p * q
    phi = (p - 1) * (q - 1)
    e = 65537
    while gcd(e, phi) != 1:
        e += 2
    d = modinv(e, phi)
    return (e, n), (d, n), (p, q)

# 私钥加密，公钥解密
def encrypt_with_private_key(m, d, n):
    return pow(m, d, n)

def decrypt_with_public_key(c, e, n):
    return pow(c, e, n)

if __name__ == "__main__":
    public_key, private_key, (p, q) = generate_rsa_keypair()
    print("p =", p)
    print("q =", q)
    print("公钥 (e, n):", public_key)
    print("私钥 (d, n):", private_key)

    # 用私钥加密，公钥解密
    message = 42  # 明文
    d, n = private_key
    e, n = public_key
    print("\n明文:", message)
    cipher = encrypt_with_private_key(message, d, n)
    print("私钥加密后的密文:", cipher)
    plain = decrypt_with_public_key(cipher, e, n)
    print("公钥解密后的明文:", plain) 