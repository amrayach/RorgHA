import sys

SUBJECT = b"Subject: "
HEADER_END = b"\r\n\r\n"

def find_pos(email):
    return map(
            lambda x: email.find(x) + len(x),
            (SUBJECT, HEADER_END)
            )

with open(sys.argv[1], "rb") as f:
    email = f.read()
    #print(lambda x: email.find(x) + len(x))
    subject_pos, header_end_pos = find_pos(email)
    print("The email:")
    print("\n")
    print(email)
    print("\n")
    print("################################")
    print("HEADER OF THE EMAIL: starts from:"+str(subject_pos)+" ends at:"+str(header_end_pos))
    print("\n")
    print(email[subject_pos:header_end_pos])
    print("################################")
    print("\n")
    print("BODY OF EMAIL:  starts from:"+str(header_end_pos))
    print("\n")
    print(email[header_end_pos:])
    print("################################")
    print(subject_pos, header_end_pos)
