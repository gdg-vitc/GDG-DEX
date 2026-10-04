from models import User, DB_SESSION
import csv

from string import ascii_lowercase
import random

def generate_passkey(length=8):
    return ''.join(random.choice(ascii_lowercase) for _ in range(length))

def load_users():
    with open("scripts/data.csv") as file:
        reader = csv.DictReader(file)
        for row in reader:
            user = User(
                name=row["name"],
                email=row["email"],
                reg_no=row["reg_no"],
                role=row["role"],
                passkey=generate_passkey()
            )
            DB_SESSION.add(user)
        DB_SESSION.commit()