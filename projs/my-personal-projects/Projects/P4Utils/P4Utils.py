#!/depot/Python/Python-3.8.0/bin/python
from P4 import P4,P4Exception  
import os
import getpass

def create_instance():

    p4 = P4()  # Create the P4 instance

    try:
        p4.port = os.getenv("P4PORT")
    except AttributeError:
        eprint("Could not get P4PORT environment variable.")
        return NULL_VAL

    try:
        p4.client = os.getenv("P4CLIENT")
    except AttributeError:
        eprint("Could not get P4CLIENT environment variable.")
        return NULL_VAL

    p4.user = getpass.getuser()
    return p4

try: 
    p4 = create_instance()                            # Catch exceptions with try/except
    p4.connect()                   # Connect to the Perforce server
    info = p4.run( "info" )        # Run "p4 info" (returns a dict)
    for key in info[0]:            # and display all key-value pairs
        print(key, "=", info[0][key])
    # p4.run( "edit", "file.txt" )   # Run "p4 edit file.txt"
    p4.run_sync()
    p4.disconnect()                # Disconnect from the server
except P4Exception:
    for e in p4.errors:            # Display errors
        print(e)