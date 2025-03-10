# This will be a script to generate random and secure passwords.

import random
import string

length = random.randint(15, 35)
password = ''.join(random.choices(string.hexdigits + string.punctuation + string.ascii_letters, k=length))

print(password)
# print(f"Your password is {length} characters.")

